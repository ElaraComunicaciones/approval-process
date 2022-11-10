public with sharing class CancellationApprovalProcess {
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
		CalculateDecrementByCancelation(approvalProcessToCalculateDecrement);
	}

	private static void CalculateDecrementByCancelation(
		List<ApprovalProcess__c> approvalProcessToCalculateDecrement
	) {
		//Obtenemos los clones de RGU de los procesos de aprobación
		List<RGU_Change_to_approve__c> lRGUsToChange = [
			SELECT id, Approval_Process__c, Referencia_Elara_Original__c
			FROM RGU_Change_to_approve__c
			WHERE Approval_Process__c IN :approvalProcessToCalculateDecrement
		];

		Map<id, ApprovalProcess__c> mapApprovalProcess = new Map<id, ApprovalProcess__c>(
			approvalProcessToCalculateDecrement
		);

		//Se genera mapa de Procesos de aprobacion con sus RGUs Clones
		Map<id, List<RGU_Change_to_approve__c>> rgusPerApprovalProcess = new Map<id, List<RGU_Change_to_approve__c>>();
		Set<Id> idsRGUSWithoutSinglePayment = new Set<Id>();

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

			/*Generamos un Set de ids de referencias cuyo proceso de aprobación no considera cobros únicos
			 mas adelante lo usaremos para no considerar los productos cuyo forma de cobro sea diferente Pago Único*/
			if (
				mapApprovalProcess.get(rgu.Approval_Process__c)
					.Considerar_cobros_unicos__c == 'No'
			) {
				idsRGUSWithoutSinglePayment.add(
					rgu.Referencia_Elara_Original__c
				);
			}
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
				Total_Renta_Conv_MXN__c,
				Partida_de_Ventas_Conv_MXN__c,
				Forma_de_Cobro__c
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

			if (
				(idsRGUSWithoutSinglePayment.contains(
					oppLineItem.Referencia_Elara__r.id
				) && oppLineItem.Forma_de_Cobro__c != 'Pago Único') ||
				!idsRGUSWithoutSinglePayment.contains(
					oppLineItem.Referencia_Elara__r.id
				)
			) {
				lOppLineItem.add(oppLineItem);
			}
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
				decrementoVTC += oli.Partida_de_Ventas_Conv_MXN__c;
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

	private static Set<Id> getOlisToUpdateSalePrice(
		List<ApprovalProcess__c> approvalProcessToCalculateDecrement
	) {
		Map<id, ApprovalProcess__c> mapApprovalProcess = new Map<id, ApprovalProcess__c>(
			approvalProcessToCalculateDecrement
		);

		//Obtenemos los clones de RGU de los procesos de aprobación
		List<RGU_Change_to_approve__c> lRGUsToChange = [
			SELECT id, Approval_Process__c, Referencia_Elara_Original__c
			FROM RGU_Change_to_approve__c
			WHERE Approval_Process__c IN :approvalProcessToCalculateDecrement
		];

		//Se genera mapa de Procesos de aprobacion con sus RGUs Clones
		Map<id, List<RGU_Change_to_approve__c>> rgusPerApprovalProcess = new Map<id, List<RGU_Change_to_approve__c>>();
		Set<Id> idsRGUSWithoutSinglePayment = new Set<Id>();

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

			/*Generamos un Set de ids de referencias cuyo proceso de aprobación no considera cobros únicos
			 mas adelante lo usaremos para no considerar los productos cuyo forma de cobro sea diferente Pago Único*/
			if (
				mapApprovalProcess.get(rgu.Approval_Process__c)
					.Considerar_cobros_unicos__c == 'No'
			) {
				idsRGUSWithoutSinglePayment.add(
					rgu.Referencia_Elara_Original__c
				);
			}
		}

		Set<Id> idsRGUs = new Set<Id>();

		//Obtenemos los OLIS de
		for (RGU_Change_to_approve__c rguToChange : lRGUsToChange) {
			idsRGUs.add(rguToChange.Referencia_Elara_Original__c);
		}

		//Obtenemos los productos de oportunidad por referencias elara original
		List<OpportunityLineItem> oppLineItems = [
			SELECT
				Id,
				Referencia_Elara__r.id,
				Fecha_Fin_Ingreso__c,
				Total_Renta_Conv_MXN__c,
				Forma_de_Cobro__c
			FROM OpportunityLineItem
			WHERE
				Forma_de_Cobro__c != 'Diaria'
				AND Referencia_Elara__r.id IN :idsRGUs
		];

		Set<Id> setOppLoneItem = new Set<Id>();

		for (OpportunityLineItem oppLineItem : oppLineItems) {
			if (
				(idsRGUSWithoutSinglePayment.contains(
					oppLineItem.Referencia_Elara__r.id
				) && oppLineItem.Forma_de_Cobro__c != 'Pago Único') ||
				!idsRGUSWithoutSinglePayment.contains(
					oppLineItem.Referencia_Elara__r.id
				)
			) {
				setOppLoneItem.add(oppLineItem.id);
			}
		}
		return setOppLoneItem;
	}

	public static void executeAfterUpdate(
		List<ApprovalProcessMail__mdt> approvalProcessMail,
		List<EmailTemplate> emailTemplates,
		Map<Id, SObject> oldMap,
		List<ApprovalProcess__c> lCancellationApprovalProcess,
		Map<Id, Opportunity> opportunities,
		Map<Id, Account> accounts,
		List<User> users
	) {
		List<ApprovalProcess__c> newRequestedRecords = filterNewRequestedRecords(
			oldMap,
			lCancellationApprovalProcess
		);

		List<ApprovalProcess__c> newApprovedRecords = filterNewApprovedRecords(
			oldMap,
			lCancellationApprovalProcess
		);

		List<ApprovalProcess__c> newRejectRecords = filterRejectedRecords(
			oldMap,
			lCancellationApprovalProcess
		);

		sendRejectNotifications(
			newRejectRecords,
			emailTemplates,
			approvalProcessMail,
			users
		);

		sendApprovalRequestNotifications(
			newRequestedRecords,
			emailTemplates,
			users
		);

		operationsWithApprovedRecords(
			newApprovedRecords,
			opportunities,
			accounts
		);

		sendApprovedNotifications(
			newApprovedRecords,
			emailTemplates,
			approvalProcessMail,
			users
		);
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
	private static List<ApprovalProcess__c> filterRejectedRecords(
		Map<Id, SObject> oldMap,
		List<ApprovalProcess__c> newRecords
	) {
		List<ApprovalProcess__c> newRejectedRecords = new List<ApprovalProcess__c>();

		for (ApprovalProcess__c newApproval : newRecords) {
			ApprovalProcess__c oldApproval = (ApprovalProcess__c) oldMap.get(
				newApproval.Id
			);

			System.debug(oldApproval.Stage__c);

			if (oldApproval != null) {
				if (
					oldApproval.Stage__c == 'Solicitado' &&
					newApproval.Stage__c == 'Rechazado'
				) {
					newRejectedRecords.add(newApproval);
				}
			}
		}

		return newRejectedRecords;
	}

	@testVisible
	private static void operationsWithApprovedRecords(
		List<ApprovalProcess__c> approvedRecords,
		Map<Id, Opportunity> opportunities,
		Map<Id, Account> accounts
	) {
		createProjectHistoryValue(approvedRecords, opportunities);
		createAccountHistoryValue(approvedRecords, opportunities, accounts);

		Set<Id> setIdsOlis = getOlisToUpdateSalePrice(approvedRecords);

		String query = 'Select id, UnitPrice__c from OpportunityLineItem where id in: setIdsOlis';

		if (setIdsOlis.size() > 0) {
			ID batchprocessid = Database.executeBatch(
				new BatchUpdateOLISCancelled(query, setIdsOlis),
				200
			);
		}
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
			historyValue.Account__c = currentAccount.Id;
			historyValue.Total_Account_OldValue__c = currentAccount.Total_Proyecto__c;
			historyValue.Total_Account_NewValue__c =
				currentAccount.Total_Proyecto__c -
				approvalProcess.Decremento_en_VTC__c;

			lHistoryValue.add(historyValue);
		}

		insert lHistoryValue;
	}

	@testVisible
	private static void sendApprovalRequestNotifications(
		List<ApprovalProcess__c> newRequestedRecords,
		List<EmailTemplate> emailTemplates,
		List<User> users
	) {
		EmailTemplate solicitudControlComercialCancelacion;

		List<String> sendTo;
		List<String> sendCC;
		List<String> sendCCO;

		List<String> commericial = ApprovalProcessAPI.getCommercialControlMail(
			users
		);
		List<String> proccesMail = ApprovalProcessAPI.getProcessMail(users);

		for (EmailTemplate template : emailTemplates) {
			switch on template.name {
				when 'SL_B2 Aprobación de cancelación durante la implementación Control Comercial' {
					solicitudControlComercialCancelacion = template;
				}
			}
		}

		for (ApprovalProcess__c approvalProcess : newRequestedRecords) {
			sendTo = ApprovalProcessAPI.getCommercialControlMail(users);
			sendCC = ApprovalProcessAPI.getCEOMail(users);
			sendCC.addAll(proccesMail);
			sendCCO = new List<String>();

			ApprovalProcessAPI.SendEmailNotifications(
				solicitudControlComercialCancelacion,
				sendTo,
				sendCC,
				sendCCO,
				approvalProcess
			);
		}
	}

	@testVisible
	private static void sendRejectNotifications(
		List<ApprovalProcess__c> newRejectedRecords,
		List<EmailTemplate> emailTemplates,
		List<ApprovalProcessMail__mdt> approvalProcessMail,
		List<User> users
	) {
		EmailTemplate denegadoControlComercialCancelacion;

		List<String> sendTo;
		List<String> sendCC = ApprovalProcessAPI.getProcessMail(users);
		List<String> sendCCO;

		for (EmailTemplate template : emailTemplates) {
			switch on template.name {
				when 'RS_B3 Aprobación baja denegada por Control Comercial' {
					denegadoControlComercialCancelacion = template;
				}
			}
		}

		for (ApprovalProcess__c approvalProcess : newRejectedRecords) {
			sendTo = new List<String>();
			sendCCO = new List<String>();
			for (User userMail : users) {
				if (userMail.id == approvalProcess.OwnerId) {
					sendTo.add(userMail.email);
					break;
				}
			}

			ApprovalProcessAPI.SendEmailNotifications(
				denegadoControlComercialCancelacion,
				sendTo,
				sendCC,
				sendCCO,
				approvalProcess
			);
		}
	}

	public static void sendApprovedNotifications(
		List<ApprovalProcess__c> approvedNotification,
		List<EmailTemplate> emailTemplates,
		List<ApprovalProcessMail__mdt> approvalProcessMail,
		List<User> users
	) {
		EmailTemplate solicitudCancelacion;
		EmailTemplate solicitudAceptada;
		List<String> sendTo;
		List<String> sendCC;
		List<String> sendCCO;
		List<String> commercialMail = ApprovalProcessAPI.getCommercialControlMail(
			users
		);
		List<String> processMail = ApprovalProcessAPI.getProcessMail(users);

		for (EmailTemplate template : emailTemplates) {
			switch on template.name {
				when 'SL_B4 Implementación de Baja' {
					solicitudCancelacion = template;
				}
				when 'RS_B1 Aprobación baja aceptada' {
					solicitudAceptada = template;
				}
			}
		}

		for (ApprovalProcess__c approvalProcess : approvedNotification) {
			sendTo = new List<String>();
			sendCC = new List<String>();
			sendCCO = new List<String>();
			for (ApprovalProcessMail__mdt approvalMail : approvalProcessMail) {
				if (approvalMail.Rol__c == 'Notificacion aprobado')
					sendTo.add(approvalMail.Correo_Elara__c);
			}

			for (User userMail : users) {
				if (approvalProcess.OwnerId == userMail.Id)
					sendCC.add(userMail.Email);
			}

			sendCC.addAll(commercialMail);
			sendCC.addAll(processMail);

			ApprovalProcessAPI.SendEmailNotifications(
				solicitudCancelacion,
				sendTo,
				sendCC,
				sendCCO,
				approvalProcess
			);

			ApprovalProcessAPI.SendEmailNotifications(
				solicitudAceptada,
				sendCC,
				new List<String>(),
				sendCCO,
				approvalProcess
			);
		}
	}
}