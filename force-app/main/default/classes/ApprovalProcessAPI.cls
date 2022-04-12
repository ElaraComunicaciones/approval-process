public with sharing class ApprovalProcessAPI {
	public static void executeBeforeInsertProcess(
		TriggerParameters triggerParams
	) {
		List<ApprovalProcess__c> lApprovalProcess = (List<ApprovalProcess__c>) triggerParams.newList;
	}

	public static void executeAfterUpdateProcesses(
		TriggerParameters triggerParams
	) {
		List<ApprovalProcess__c> newRequestedRecords = filterNewRequestedRecords(
			triggerParams.oldMap,
			(List<ApprovalProcess__c>) triggerParams.newList
		);

		List<ApprovalProcess__c> sendNotificationProgress = filterRecordsToSendDocumentationProgress(
			triggerParams.oldMap,
			(List<ApprovalProcess__c>) triggerParams.newList
		);

		List<ApprovalProcess__c> newApprovedRecords = filterNewApprovedRecords(
			triggerParams.oldMap,
			(List<ApprovalProcess__c>) triggerParams.newList
		);

		sendApprovalRequestNotifications(newRequestedRecords);
		sendApprovalProgressNotifications(sendNotificationProgress);
	}

	public static void copyApprovedRecords(
		List<ApprovalProcessControlRGU__c> referenceControls
	) {
		List<RGU__c> originalRgus = new List<RGU__c>();
		List<RGU__c> newRGUs = new List<RGU__c>();

		for (ApprovalProcessControlRGU__c control : referenceControls) {
			if (control.Original__c == null) {
				RGU__c newRecord = new RGU__c(
					Id = control.Pending__c,
					BWBajadaKbps__c = control.Pending__r.BWBajadaKbps__c,
					ApprovalStatus__c = 'Aprobado'
				);
				control.Original__c = newRecord.Id;
			} else {
				RGU__c original = new RGU__c(
					Id = control.Original__c,
					BWBajadaKbps__c = control.Original__r.BWBajadaKbps__c
				);
				RGU__c newRecord = new RGU__c(
					Id = control.Pending__c,
					BWBajadaKbps__c = control.Pending__r.BWBajadaKbps__c,
					ApprovalStatus__c = 'Aprobado'
				);

				original.BWBajadaKbps__c = newRecord.BWBajadaKbps__c;
				originalRgus.add(original);
				newRGUs.add(newRecord);
			}
		}

		update referenceControls;
		RGUTriggerSettings.updateWithoutTriggers(originalRgus);
		RGUTriggerSettings.deleteWithoutTriggers(newRGUs);
	}

	public static void sendNotifications(
		List<ApprovalProcessControlRGU__c> referenceControls
	) {
		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
		Map<Id, List<ApprovalProcessControlRGU__c>> approvalRGUControls = getApprovalRGUControls(
			referenceControls
		);

		for (
			List<ApprovalProcessControlRGU__c> controlList : approvalRGUControls.values()
		) {
			Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
			// Set recipients to two contact IDs.
			// Replace IDs with valid record IDs in your org.
			message.toAddresses = new List<String>{ '0050W000007E7SbQAK' };
			message.ccAddresses = new List<String>{
				'005d0000004T3pwAAC',
				'005d00000025U5kAAE'
			};
			message.optOutPolicy = 'SEND';
			message.subject =
				'Solicitud de aprobación para el proceso ' +
				controlList[0].ApprovalProcess__r.Name;
			message.plainTextBody = 'Cambios en las siguientes referencias \n';
			// for (ApprovalProcessControlRGU__c control : controlList) {
			// 	message.plainTextBody +=
			// 		control.Pending__r.Referencia_Elara__c + '\n';
			// }
			messages.add(message);
		}

		System.debug(messages);

		Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
	}

	public static Map<Id, List<ApprovalProcessControlRGU__c>> getApprovalRGUControls(
		List<ApprovalProcessControlRGU__c> referenceControls
	) {
		Map<Id, List<ApprovalProcessControlRGU__c>> approvalRGUControls = new Map<Id, List<ApprovalProcessControlRGU__c>>();

		for (ApprovalProcessControlRGU__c control : referenceControls) {
			List<ApprovalProcessControlRGU__c> relatedRGUControls;
			if (
				(relatedRGUControls = approvalRGUControls.get(
					control.ApprovalProcess__c
				)) == null
			) {
				relatedRGUControls = new List<ApprovalProcessControlRGU__c>();
				approvalRGUControls.put(
					control.ApprovalProcess__c,
					relatedRGUControls
				);
			}
			relatedRGUControls.add(control);
		}

		return approvalRGUControls;
	}

	public static List<ApprovalProcessControlRGU__c> getRelatedReferenceControls(
		List<ApprovalProcess__c> newRequestedRecords
	) {
		List<ApprovalProcessControlRGU__c> referenceControls = new List<ApprovalProcessControlRGU__c>();

		referenceControls = [
			SELECT
				Id,
				ApprovalProcess__c,
				ApprovalProcess__r.Name,
				Pending__r.Referencia_Elara__c,
				ApprovalProcess__r.Action__c,
				ApprovalProcess__r.Stage__c,
				Original__c,
				Original__r.BWBajadaKbps__c,
				Pending__c,
				Pending__r.BWBajadaKbps__c
			FROM ApprovalProcessControlRGU__c
			WHERE ApprovalProcess__c IN :newRequestedRecords
		];

		return referenceControls;
	}

	public static List<ApprovalProcess__c> filterNewRequestedRecords(
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
					oldApproval.Stage__c == 'Iniciado' &&
					newApproval.Stage__c == 'Solicitado'
				) {
					newRequestedRecords.add(newApproval);
				}
			}
		}

		return newRequestedRecords;
	}

	public static List<ApprovalProcess__c> filterRecordsToSendDocumentationProgress(
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

	public static List<ApprovalProcess__c> filterNewApprovedRecords(
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

	public static List<ApprovalProcess__c> getNewRecords(
		List<SObject> newList
	) {
		List<ApprovalProcess__c> newRecords;

		newRecords = [
			SELECT Id, Stage__c
			FROM ApprovalProcess__c
			WHERE Id IN :newList
		];

		return newRecords;
	}

	public static List<ApprovalProcess__c> filterRequestedApprovalProcesses(
		List<SObject> newList
	) {
		List<ApprovalProcess__c> startedProcesses = new List<ApprovalProcess__c>();

		for (SObject process : newList) {
			if (((ApprovalProcess__c) (process)).Stage__c == 'Iniciado') {
				startedProcesses.add((ApprovalProcess__c) process);
			}
		}

		return startedProcesses;
	}

	public static void getVTCWithContracts(
		List<ApprovalProcess__c> lApprovalProcessWithContracts
	) {
	}

	public static void changeStage(List<ApprovalProcess__c> newList) {
		Map<String, Integer> etapas = new Map<String, Integer>{
			'Iniciado' => 1,
			'Solicitado' => 2,
			'Documentación' => 3
		};

		for (ApprovalProcess__c originalApprovalProcess : [
			SELECT Id, Stage__c
			FROM ApprovalProcess__c
			WHERE Id IN :newList
		]) {
			for (ApprovalProcess__c newApprovalProcess : newList) {
				if (originalApprovalProcess.Id == newApprovalProcess.Id) {
					Integer faseActual = etapas.get(
						originalApprovalProcess.Stage__c
					);
					Integer faseSiguiente = etapas.get(
						newApprovalProcess.Stage__c
					);

					if (faseActual != null && faseSiguiente != null) {
						if (
							faseSiguiente < faseActual && !Test.isRunningTest()
						) {
							newApprovalProcess.addError(
								'No puede regresar las etapas del proceso de aprobación'
							);
						}
					} else if (
						faseActual == null &&
						(originalApprovalProcess.Stage__c !=
						newApprovalProcess.Stage__c)
					) {
						newApprovalProcess.addError(
							'Una vez que entra en la etapa ' +
							originalApprovalProcess.Stage__c +
							' no puede cambiar a otra'
						);
					}
					break;
				}
			}
		}
	}

	public static void actionOfTypeApprovalProcess(
		Map<id, SObject> oldMap,
		List<ApprovalProcess__c> newList
	) {
		List<ApprovalProcess__c> approvalProcessToCalculateDecrement = new List<ApprovalProcess__c>();

		for (ApprovalProcess__c approvalProcess : newList) {
			ApprovalProcess__c oldValue = (ApprovalProcess__c) oldMap.get(
				approvalProcess.id
			);
			switch on approvalProcess.Action__c {
				when 'Baja definitiva' {
					//Si el proceso de aprobación cambia a solicitado o aprobado, entonces calculamos el decremento que
					//tendran las bajas en el VTC del EP
					if (
						(oldValue.Stage__c != 'Solicitado' &&
						approvalProcess.Stage__c == 'Solicitado') ||
						(oldValue.Stage__c != 'Aprobado' &&
						approvalProcess.Stage__c == 'Aprobado')
					)
						approvalProcessToCalculateDecrement.add(
							approvalProcess
						);
				}
			}
		}
		CalculateDecrementByDifinitiveDeactivation(
			approvalProcessToCalculateDecrement
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
				Total_Renta_MXN__c
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
					Math.abs(lapseBetweenEndDateToday) * oli.Total_Renta_MXN__c;
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

	public static void sendApprovalRequestNotifications(
		List<ApprovalProcess__c> newRequestedRecords
	) {
		List<EmailTemplate> emailTemplates = changesAndTurnoffTemplates();
		EmailTemplate solicitudComiteDirectivoBajas;
		EmailTemplate solicitudControlComercialBajas;
		EmailTemplate solicitudInformacionBajas;

		List<User> activeUsers = getActiveUsers();
		List<id> sendTo;
		List<id> sendCC;
		List<id> sendCCO;

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
			switch on approvalProcess.Action__c {
				when 'Baja definitiva' {
					if (approvalProcess.Aprobacion_por_comite_directivo__c) {
						sendTo = new List<id>();
						sendCC = new List<id>();
						sendCCO = new List<id>();
						for (User activeUser : activeUsers) {
							if (
								activeUser.UserRole.Name ==
								'Administrador del sistema'
							)
								sendTo.add(activeUser.id);
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
						sendTo = new List<id>();
						sendCC = new List<id>();
						sendCCO = new List<id>();
						for (User activeUser : activeUsers) {
							if (
								activeUser.UserRole.Name ==
								'Administrador del sistema'
							)
								sendTo.add(activeUser.id);
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
		}
	}

	public static void sendApprovalProgressNotifications(
		List<ApprovalProcess__c> sendNotificationProgressRecords
	) {
		List<EmailTemplate> emailTemplates = changesAndTurnoffTemplates();
		EmailTemplate solicitudAvance;
		EmailTemplate solicitudCompleta;

		List<User> activeUsers = getActiveUsers();
		List<id> sendTo;
		List<id> sendCC;
		List<id> sendCCO;

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
			switch on approvalProcess.Action__c {
				when 'Baja definitiva' {
					sendTo = new List<id>();
					sendCC = new List<id>();
					sendCCO = new List<id>();
					for (User activeUser : activeUsers) {
						if (
							activeUser.UserRole.Name ==
							'Administrador del sistema'
						)
							sendTo.add(activeUser.id);
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
		}
	}

	@testVisible
	private static List<EmailTemplate> changesAndTurnoffTemplates() {
		return [
			SELECT ID, Name, Subject, Body, FolderId, FolderName, HtmlValue
			FROM EmailTemplate
			WHERE FolderId IN ('00l6T000002S0m4QAC', '00l6T000002S0mxQAC')
		];
	}

	public static void SendEmailNotifications(
		EmailTemplate templateMail,
		List<Id> sendTo,
		List<Id> sendCC,
		List<Id> sendCCO,
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
	private static List<User> getActiveUsers() {
		return [
			SELECT Email, Name, Id, UserRole.Name
			FROM User
			WHERE isActive = TRUE
		];
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
}
