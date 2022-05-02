public with sharing class DeactivateApprovalProcess {
	public static void executeBeforeUpdateProcess(
		Map<id, SObject> oldMap,
		List<ApprovalProcess__c> newList
	) {
		List<ApprovalProcess__c> approvalProcessToCalculateDecrement = new List<ApprovalProcess__c>();

		for (ApprovalProcess__c approvalProcess : newList) {
			ApprovalProcess__c oldValue = (ApprovalProcess__c) oldMap.get(
				approvalProcess.id
			);

			//Si el proceso de aprobación cambia a solicitado o aprobado, entonces calculamos el decremento que
			//tendran las bajas en el VTC del EP
			if (
				(oldValue.Stage__c != 'Solicitado' &&
				approvalProcess.Stage__c == 'Solicitado') ||
				(oldValue.Stage__c != 'Aprobado' &&
				approvalProcess.Stage__c == 'Aprobado')
			)
				approvalProcessToCalculateDecrement.add(approvalProcess);
		}
		CalculateDecrementByDifinitiveDeactivation(
			approvalProcessToCalculateDecrement
		);
	}

	public static void executeAfterUpdate(
		List<ApprovalProcessMail__mdt> approvalProcessMail,
		List<EmailTemplate> emailTemplates,
		Map<Id, SObject> oldMap,
		List<ApprovalProcess__c> lApprovalProcessOfDeactivate,
		Map<Id, Opportunity> opportunities,
		Map<Id, Account> accounts,
		Map<Id, List<RGU__C>> RGUPerApprovalProcess
	) {
		List<ApprovalProcess__c> newRequestedRecords = filterNewRequestedRecords(
			oldMap,
			lApprovalProcessOfDeactivate
		);

		List<ApprovalProcess__c> sendNotificationProgress = filterRecordsToSendDocumentationProgress(
			oldMap,
			lApprovalProcessOfDeactivate
		);

		List<ApprovalProcess__c> newApprovedRecords = filterNewApprovedRecords(
			oldMap,
			lApprovalProcessOfDeactivate
		);

		sendApprovalRequestNotifications(
			newRequestedRecords,
			emailTemplates,
			approvalProcessMail
		);

		sendApprovalProgressNotifications(
			sendNotificationProgress,
			emailTemplates,
			approvalProcessMail
		);

		operationsWithApprovedRecords(
			newApprovedRecords,
			opportunities,
			accounts,
			RGUPerApprovalProcess
		);

		sendApprovedNotifications(
			newApprovedRecords,
			emailTemplates,
			approvalProcessMail
		);
	}

	@testVisible
	private static void CalculateDecrementByDifinitiveDeactivation(
		List<ApprovalProcess__c> approvalProcessToCalculateDecrement
	) {
		//Obtenemos los clones de RGU de los procesos de aprobación
		List<RGU_Change_to_approve__c> lRGUsToChange = [
			SELECT id, Approval_Process__c, Referencia_Elara_Original__c
			FROM RGU_Change_to_approve__c
			WHERE Approval_Process__c IN :approvalProcessToCalculateDecrement
		];

		//Se genera mapa de Procesos de aprobacion con sus RGUs Clones
		Map<id, List<RGU_Change_to_approve__c>> rgusPerApprovalProcess = new Map<id, List<RGU_Change_to_approve__c>>();

		for (RGU_Change_to_approve__c rgu : lRGUsToChange) {
			List<RGU_Change_to_approve__c> lrgus;

			if (
				(lrgus = rgusPerApprovalProcess.get(rgu.Approval_Process__c)) ==
				null
			) {
				lrgus = new List<RGU_Change_to_approve__c>();
				rgusPerApprovalProcess.put(rgu.Approval_Process__c, lrgus);
			}
			lrgus.add(rgu);
		}

		Set<Id> idsRGUs = new Set<Id>();

		//Obtenemos los OLIS de
		for (RGU_Change_to_approve__c rguToChange : lRGUsToChange) {
			idsRGUs.add(rguToChange.Referencia_Elara_Original__c);
		}

		Map<Id, List<OpportunityLineItem>> olisPerRGUs = new Map<Id, List<OpportunityLineItem>>();

		//Obtenemos los productos de oportunidad por referencias elara original
		List<OpportunityLineItem> oppLineItems = [
			SELECT
				Id,
				Referencia_Elara__r.id,
				Fecha_Fin_Ingreso__c,
				Total_Renta_Conv_MXN__c
			FROM OpportunityLineItem
			WHERE
				Forma_de_Cobro__c != 'Diaria'
				AND Referencia_Elara__r.id IN :idsRGUs
		];

		for (OpportunityLineItem oppLineItem : oppLineItems) {
			List<OpportunityLineItem> lOppLineItem;

			if (
				(lOppLineItem = olisPerRGUs.get(
					oppLineItem.Referencia_Elara__r.id
				)) == null
			) {
				lOppLineItem = new List<OpportunityLineItem>();
				olisPerRGUs.put(
					oppLineItem.Referencia_Elara__r.id,
					lOppLineItem
				);
			}
			lOppLineItem.add(oppLineItem);
		}

		System.debug(olisPerRGUs);

		//Generamos los decrementos de VTC de las referencias ELARA
		Map<id, Decimal> lDecrementPerRGU = new Map<Id, Decimal>();

		for (RGU_Change_to_approve__c rguToChange : lRGUsToChange) {
			List<OpportunityLineItem> actualOlis = olisPerRGUs.get(
				rguToChange.Referencia_Elara_Original__c
			);
			Decimal decrementoVTC = 0;
			for (OpportunityLineItem oli : actualOlis) {
				//Se obtienen los meses que ya no se van a cobrar, con respecto al día de hoy
				Integer lapseBetweenEndDateToday = oli.Fecha_Fin_Ingreso__c.monthsBetween(
					System.today()
				);
				decrementoVTC +=
					Math.abs(lapseBetweenEndDateToday) *
					oli.Total_Renta_Conv_MXN__c;
			}
			lDecrementPerRGU.put(rguToChange.id, decrementoVTC);
		}

		System.debug(lDecrementPerRGU);
		System.debug(rgusPerApprovalProcess);

		Map<id, Decimal> decrementsPerApprovalProcess = new Map<Id, Decimal>();

		for (Id key : rgusPerApprovalProcess.keySet()) {
			List<RGU_Change_to_approve__c> lRGUS = rgusPerApprovalProcess.get(
				key
			);
			Decimal decrementVTC = 0;
			for (RGU_Change_to_approve__c rgu : lRGUS) {
				decrementVTC += lDecrementPerRGU.get(rgu.id);
			}

			decrementsPerApprovalProcess.put(key, decrementVTC);
		}

		System.debug(decrementsPerApprovalProcess);

		for (
			ApprovalProcess__c approvalProcess : approvalProcessToCalculateDecrement
		) {
			approvalProcess.Decremento_en_VTC__c = decrementsPerApprovalProcess.get(
				approvalProcess.id
			);
		}
	}

	@testVisible
	private static List<ApprovalProcess__c> filterNewRequestedRecords(
		Map<Id, SObject> oldMap,
		List<ApprovalProcess__c> lApprovalProcessOfDeactivate
	) {
		List<ApprovalProcess__c> newRequestedRecords = new List<ApprovalProcess__c>();

		System.debug(oldMap);

		for (ApprovalProcess__c newApproval : lApprovalProcessOfDeactivate) {
			ApprovalProcess__c oldApproval = (ApprovalProcess__c) oldMap.get(
				newApproval.Id
			);

			System.debug(oldApproval.Stage__c);

			if (oldApproval != null) {
				if (
					oldApproval.Stage__c == 'Iniciado' &&
					newApproval.Stage__c == 'Solicitado'
				) {
					newRequestedRecords.add(newApproval);
				}
			}
		}

		return newRequestedRecords;
	}

	@testVisible
	private static List<ApprovalProcess__c> filterRecordsToSendDocumentationProgress(
		Map<Id, SObject> oldMap,
		List<ApprovalProcess__c> newRecords
	) {
		List<ApprovalProcess__c> newRequestedRecords = new List<ApprovalProcess__c>();

		System.debug(oldMap);

		for (ApprovalProcess__c newApproval : newRecords) {
			ApprovalProcess__c oldApproval = (ApprovalProcess__c) oldMap.get(
				newApproval.Id
			);

			System.debug(oldApproval.Stage__c);

			if (oldApproval != null) {
				if (
					oldApproval.Stage__c == 'Solicitado' &&
					newApproval.Stage__c == 'Solicitado' &&
					newApproval.Aprobacion_por_comite_directivo__c
				) {
					newRequestedRecords.add(newApproval);
				}
			}
		}

		return newRequestedRecords;
	}

	@testVisible
	private static void sendApprovalRequestNotifications(
		List<ApprovalProcess__c> newRequestedRecords,
		List<EmailTemplate> emailTemplates,
		List<ApprovalProcessMail__mdt> approvalProcessMail
	) {
		EmailTemplate solicitudComiteDirectivoBajas;
		EmailTemplate solicitudControlComercialBajas;
		EmailTemplate solicitudInformacionBajas;

		List<String> sendTo;
		List<String> sendCC;
		List<String> sendCCO;

		for (EmailTemplate template : emailTemplates) {
			switch on template.name {
				when 'SL_B1 Aprobación de baja Comité Directivo' {
					solicitudComiteDirectivoBajas = template;
				}
				when 'SL_B3 Información para aprobación de baja' {
					solicitudInformacionBajas = template;
				}
				when 'SL_B2 Aprobación de baja Control Comercial' {
					solicitudControlComercialBajas = template;
				}
			}
		}

		for (ApprovalProcess__c approvalProcess : newRequestedRecords) {
			if (approvalProcess.Aprobacion_por_comite_directivo__c) {
				sendTo = new List<String>();
				sendCC = new List<String>();
				sendCCO = new List<String>();
				for (
					ApprovalProcessMail__mdt approvalMail : approvalProcessMail
				) {
					if (approvalMail.Rol__c == 'Comité Directivo')
						sendTo.add(approvalMail.Correo_Elara__c);
					else {
						sendCC.add(approvalMail.Correo_Elara__c);
					}
				}

				SendEmailNotifications(
					solicitudComiteDirectivoBajas,
					sendTo,
					sendCC,
					sendCCO,
					approvalProcess
				);
				SendEmailNotifications(
					solicitudInformacionBajas,
					sendTo,
					sendCC,
					sendCCO,
					approvalProcess
				);
			} else {
				sendTo = new List<String>();
				sendCC = new List<String>();
				sendCCO = new List<String>();
				for (
					ApprovalProcessMail__mdt approvalMail : approvalProcessMail
				) {
					if (approvalMail.Rol__c == 'Comité Directivo')
						sendTo.add(approvalMail.Correo_Elara__c);
					else {
						sendCC.add(approvalMail.Correo_Elara__c);
					}
				}

				SendEmailNotifications(
					solicitudControlComercialBajas,
					sendTo,
					sendCC,
					sendCCO,
					approvalProcess
				);
			}
		}
	}

	@testVisible
	private static void sendApprovalProgressNotifications(
		List<ApprovalProcess__c> sendNotificationProgressRecords,
		List<EmailTemplate> emailTemplates,
		List<ApprovalProcessMail__mdt> approvalProcessMail
	) {
		EmailTemplate solicitudAvance;
		EmailTemplate solicitudCompleta;

		List<String> sendTo;
		List<String> sendCC;
		List<String> sendCCO;

		for (EmailTemplate template : emailTemplates) {
			switch on template.name {
				when 'NT_B1 Avance de Documentación' {
					solicitudAvance = template;
				}
				when 'NT_B2 Documentación completa para baja' {
					solicitudCompleta = template;
				}
			}
		}

		for (
			ApprovalProcess__c approvalProcess : sendNotificationProgressRecords
		) {
			sendTo = new List<String>();
			sendCC = new List<String>();
			sendCCO = new List<String>();
			for (ApprovalProcessMail__mdt approvalMail : approvalProcessMail) {
				if (approvalMail.Rol__c == 'Comité Directivo')
					sendTo.add(approvalMail.Correo_Elara__c);
			}

			if (validateCompleteInformation(approvalProcess)) {
				SendEmailNotifications(
					solicitudCompleta,
					sendTo,
					sendCC,
					sendCCO,
					approvalProcess
				);
			} else {
				SendEmailNotifications(
					solicitudAvance,
					sendTo,
					sendCC,
					sendCCO,
					approvalProcess
				);
			}
		}
	}

	@testVisible
	private static Boolean validateCompleteInformation(
		ApprovalProcess__c approvalProcess
	) {
		Boolean isComplete = true;

		if (approvalProcess.Saldo_cubierto_a_la_fecha__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Saldo_pendiente_de_pago__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Cantidad_de_facturas_pendientes__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Margen_Bruto__c == null) {
			isComplete = false;
		}

		if (approvalProcess.CAPEX__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Divisa_CAPEX__c == null) {
			isComplete = false;
		}

		if (approvalProcess.EBITDA__c == null) {
			isComplete = false;
		}

		if (approvalProcess.EBIT__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Payback__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Par_metros_de_rentabilidad__c == null) {
			isComplete = false;
		}

		if (approvalProcess.ROI__c == null) {
			isComplete = false;
		}

		if (approvalProcess.TIR__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Ingresos_por_cubrir__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Costos_por_cubrir__c == null) {
			isComplete = false;
		}

		if (String.isBlank(approvalProcess.Penalizacion_por_cancelacion__c)) {
			isComplete = false;
		}

		if (String.isBlank(approvalProcess.Penalizacion_por_cancelacion__c)) {
			isComplete = false;
		}

		if (String.isBlank(approvalProcess.Clausula_rescision_cancelacion__c)) {
			isComplete = false;
		}

		if (approvalProcess.Vigencia_contrato_proveedor_satelital__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Proxima_fecha_de_cancelacion_segmento__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Implicaciones_cancelacion_de_segmento__c == null) {
			isComplete = false;
		}

		return isComplete;
	}

	@testVisible
	private static List<ApprovalProcess__c> filterNewApprovedRecords(
		Map<Id, SObject> oldMap,
		List<ApprovalProcess__c> newRecords
	) {
		List<ApprovalProcess__c> newRequestedRecords = new List<ApprovalProcess__c>();

		System.debug(oldMap);

		for (ApprovalProcess__c newApproval : newRecords) {
			ApprovalProcess__c oldApproval = (ApprovalProcess__c) oldMap.get(
				newApproval.Id
			);

			System.debug(oldApproval.Stage__c);

			if (oldApproval != null) {
				if (
					oldApproval.Stage__c != 'Aprobado' &&
					newApproval.Stage__c == 'Aprobado'
				) {
					newRequestedRecords.add(newApproval);
				}
			}
		}

		return newRequestedRecords;
	}

	@testVisible
	private static void operationsWithApprovedRecords(
		List<ApprovalProcess__c> approvedRecords,
		Map<Id, Opportunity> opportunities,
		Map<Id, Account> accounts,
		Map<Id, List<RGU__C>> mapRGUSPerApprovalProcess
	) {
		createProjectHistoryValue(approvedRecords, opportunities);
		createAccountHistoryValue(approvedRecords, opportunities, accounts);

		List<RGU__c> rgusToDeactivate = new List<RGU__C>();

		for (ApprovalProcess__c approvalProcess : approvedRecords) {
			for (
				RGU__C rgu : mapRGUSPerApprovalProcess.get(approvalProcess.id)
			) {
				rgusToDeactivate.add(rgu);
			}
		}

		deactivateRGUs(rgusToDeactivate);
	}

	@testVisible
	private static void createProjectHistoryValue(
		List<ApprovalProcess__c> approvedRecords,
		Map<Id, Opportunity> opportunities
	) {
		List<TotalProjectValueHistory__c> lHistoryValue = new List<TotalProjectValueHistory__c>();

		for (ApprovalProcess__c approvalProcess : approvedRecords) {
			TotalProjectValueHistory__c historyValue = new TotalProjectValueHistory__c();
			Opportunity currentOpp = opportunities.get(
				approvalProcess.Opportunity__c
			);
			historyValue.Opportunity__c = approvalProcess.Opportunity__c;
			historyValue.Total_Proyecto_OldValue__c = currentOpp.Total_Proyecto__c;
			historyValue.Total_Proyecto_NewValue__c =
				currentOpp.Total_Proyecto__c -
				approvalProcess.Decremento_en_VTC__c;

			lHistoryValue.add(historyValue);
		}

		insert lHistoryValue;
	}

	@testVisible
	private static void createAccountHistoryValue(
		List<ApprovalProcess__c> approvedRecords,
		Map<Id, Opportunity> opportunities,
		Map<Id, Account> accounts
	) {
		List<TotalAccountValueHistory__c> lHistoryValue = new List<TotalAccountValueHistory__c>();

		for (ApprovalProcess__c approvalProcess : approvedRecords) {
			TotalAccountValueHistory__c historyValue = new TotalAccountValueHistory__c();
			Account currentAccount = accounts.get(
				opportunities.get(approvalProcess.Opportunity__c).AccountId
			);
			historyValue.Cuenta__c = currentAccount.Id;
			historyValue.Total_Account_OldValue__c = currentAccount.Total_Proyecto__c;
			historyValue.Total_Account_NewValue__c =
				currentAccount.Total_Proyecto__c -
				approvalProcess.Decremento_en_VTC__c;

			lHistoryValue.add(historyValue);
		}

		insert lHistoryValue;
	}

	public static void sendApprovedNotifications(
		List<ApprovalProcess__c> approvedNotification,
		List<EmailTemplate> emailTemplates,
		List<ApprovalProcessMail__mdt> approvalProcessMail
	) {
		EmailTemplate solicitudBaja;
		List<String> sendTo;
		List<String> sendCC;
		List<String> sendCCO;

		for (EmailTemplate template : emailTemplates) {
			switch on template.name {
				when 'SL_B4 Implementación de Baja' {
					solicitudBaja = template;
				}
			}
		}

		for (ApprovalProcess__c approvalProcess : approvedNotification) {
			sendTo = new List<String>();
			sendCC = new List<String>();
			sendCCO = new List<String>();
			for (ApprovalProcessMail__mdt approvalMail : approvalProcessMail) {
				if (approvalMail.Rol__c == 'Comité Directivo')
					sendTo.add(approvalMail.Correo_Elara__c);
			}

			SendEmailNotifications(
				solicitudBaja,
				sendTo,
				sendCC,
				sendCCO,
				approvalProcess
			);
		}
	}

	public static void SendEmailNotifications(
		EmailTemplate templateMail,
		List<String> sendTo,
		List<String> sendCC,
		List<String> sendCCO,
		ApprovalProcess__c approvalProcess
	) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<Messaging.SingleEmailMessage> mailsToSend = new List<Messaging.SingleEmailMessage>();

		mail.setToAddresses(sendTo);

		if (sendCC.size() > 0)
			mail.setCcAddresses(sendCC);

		if (sendCCO.size() > 0)
			mail.setBccAddresses(sendCCO);

		mail.setWhatId(approvalProcess.Id);
		mail.setTemplateId(templateMail.Id);
		mail.setTreatBodiesAsTemplate(true);
		mail.setSubject(templateMail.Subject);
		mail.setHtmlBody(templateMail.HTMLValue);
		String texto = templateMail.Body;
		mail.setPlainTextBody(texto);
		mail.setSenderDisplayName(approvalProcess.Owner.Name);
		mailsToSend.add(mail);
		Messaging.sendEmail(mailsToSend);
	}

	@testVisible
	private static void deactivateRGUs(List<RGU__C> rgusToDeactivate) {
		for (RGU__C currentRGU : rgusToDeactivate) {
			currentRGU.Date_deactive_by_Client__c = date.today();
		}

		update rgusToDeactivate;
	}
}