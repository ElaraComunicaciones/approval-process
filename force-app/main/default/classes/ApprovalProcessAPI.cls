public with sharing class ApprovalProcessAPI {
	@testVisible
	private static List<ApprovalProcessMail__mdt> SetApprovalProcessMail() {
		return [
			SELECT
				Id,
				Activo__c,
				Correo_Elara__c,
				Label,
				Nombre_Completo__c,
				Rol__c
			FROM ApprovalProcessMail__mdt
			WHERE Activo__c = TRUE
		];
	}

	@testVisible
	private static List<EmailTemplate> changesAndTurnoffTemplates() {
		return [
			SELECT ID, Name, Subject, Body, FolderId, FolderName, HtmlValue
			FROM EmailTemplate
			WHERE FolderId IN ('00l6T000002S0m4QAC', '00l6T000002S0mxQAC')
		];
	}

	@testVisible
	public static List<User> getActiveUsers() {
		return [
			SELECT id, name, email, userrole.name
			FROM User
			WHERE isactive = TRUE
		];
	}

	public static void executeBeforeInsertProcess(
		TriggerParameters triggerParams
	) {
		List<ApprovalProcess__c> lApprovalProcess = (List<ApprovalProcess__c>) triggerParams.newList;
	}

	public static void executeBeforeUpdateProcess(
		TriggerParameters triggerParams
	) {
		//Obtenemos los procesos de aprobación que corresponden a bajas
		List<ApprovalProcess__c> lDeactivateApprovalProcess = DeactivateApprovalProcess(
			(List<ApprovalProcess__c>) triggerParams.newList
		);

		DeactivateApprovalProcess.executeBeforeUpdateProcess(
			triggerParams.oldMap,
			lDeactivateApprovalProcess
		);
	}

	public static List<ApprovalProcess__c> DeactivateApprovalProcess(
		List<ApprovalProcess__c> approvalProcess
	) {
		List<ApprovalProcess__c> approvalDeactivate = new List<ApprovalProcess__c>();

		for (ApprovalProcess__c currentApprovalProcess : approvalProcess) {
			if (currentApprovalProcess.Action__c == 'Baja definitiva') {
				approvalDeactivate.add(currentApprovalProcess);
			}
		}

		return approvalDeactivate;
	}

	public static void executeAfterUpdateProcesses(
		TriggerParameters triggerParams
	) {
		List<ApprovalProcessMail__mdt> approvalProcessMail = SetApprovalProcessMail();
		List<EmailTemplate> emailTemplates = changesAndTurnoffTemplates();
		List<User> users = getActiveUsers();

		//Obtenemos los procesos de aprobación que corresponden a bajas
		List<ApprovalProcess__c> lDeactivateApprovalProcess = DeactivateApprovalProcess(
			(List<ApprovalProcess__c>) triggerParams.newList
		);

		Map<Id, Opportunity> opportunities = getOpportunitiesByApprovalProcess(
			(List<ApprovalProcess__c>) triggerParams.newList
		);

		Map<Id, Account> accounts = getAccountsByApprovalProcess(
			(List<ApprovalProcess__c>) triggerParams.newList,
			opportunities
		);

		Map<Id, List<RGU__C>> RGUPerApprovalProcess = getRGUPerApprovalProcess(
			(List<ApprovalProcess__c>) triggerParams.newList
		);

		DeactivateApprovalProcess.executeAfterUpdate(
			approvalProcessMail,
			emailTemplates,
			triggerParams.oldMap,
			lDeactivateApprovalProcess,
			opportunities,
			accounts,
			RGUPerApprovalProcess,
			users
		);

		//En caso de que exista un rechzao de proceso de aprobación, se valida si pasó de solicitado a rechazado,
		//Si esté es el caso, entonces se notifica al aprobador que el solicitante canceló
		changeToCancelledStatus(
			triggerParams.newList,
			triggerParams.oldMap,
			emailTemplates,
			users
		);
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
						if (faseSiguiente < faseActual) {
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

	private static void changeToCancelledStatus(
		List<ApprovalProcess__c> newList,
		Map<id, SObject> oldMap,
		List<EmailTemplate> emailTemplates,
		List<User> users
	) {
		List<ApprovalProcess__c> approvalProcessToSendNotification = new List<ApprovalProcess__c>();

		for (ApprovalProcess__c approvalProcess : newList) {
			ApprovalProcess__c approvalProcessOld = (ApprovalProcess__c) oldMap.get(
				approvalProcess.id
			);

			if (
				approvalProcessOld.Stage__c == 'Solicitado' &&
				approvalProcess.Stage__c == 'Cancelado'
			) {
				approvalProcessToSendNotification.add(approvalProcess);
			}
		}

		sendApprovalCancelledNotifications(
			approvalProcessToSendNotification,
			emailTemplates,
			users
		);
	}

	@testVisible
	private static void sendApprovalCancelledNotifications(
		List<ApprovalProcess__c> approvalProcessToSendNotification,
		List<EmailTemplate> emailTemplates,
		List<User> users
	) {
		List<String> sendToComiteDirectivo = new List<String>();
		List<String> sendToControlComercial = new List<String>();
		List<String> documentadores = new List<String>();
		List<String> sendCC = new List<String>();
		List<String> sendCCO = new List<String>();

		EmailTemplate notificacionCancelacion;

		for (EmailTemplate template : emailTemplates) {
			if (template.name == 'NT_B3 Cancelación de proceso de aprobación') {
				notificacionCancelacion = template;
			}
		}

		sendToComiteDirectivo = getDirectorsMail(users);
		documentadores = getDocumentesMail(users);
		sendToControlComercial = getCommercialControlMail(users);

		for (
			ApprovalProcess__c approvalProcess : approvalProcessToSendNotification
		) {
			if (approvalProcess.Aprobacion_por_comite_directivo__c)
				SendEmailNotifications(
					notificacionCancelacion,
					sendToComiteDirectivo,
					documentadores,
					sendCCO,
					approvalProcess
				);
			else
				SendEmailNotifications(
					notificacionCancelacion,
					sendToControlComercial,
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
		mail.setSenderDisplayName(UserInfo.getName());
		mailsToSend.add(mail);
		Messaging.sendEmail(mailsToSend);
	}

	public static void setTotalProjectAndTotalAccount(
		Map<id, SObject> oldMap,
		List<ApprovalProcess__c> newList
	) {
		Map<Id, Opportunity> opportunities = getOpportunitiesByApprovalProcess(
			newList
		);

		Map<Id, Account> accounts = getAccountsByApprovalProcess(
			newList,
			opportunities
		);

		for (ApprovalProcess__c approvalProcess : newList) {
			ApprovalProcess__c oldValue = (ApprovalProcess__c) oldMap.get(
				approvalProcess.id
			);

			if (
				(oldValue.Stage__c != 'Solicitado' &&
				approvalProcess.Stage__c == 'Solicitado') ||
				(oldValue.Stage__c != 'Aprobado' &&
				approvalProcess.Stage__c == 'Aprobado')
			) {
				approvalProcess.Total_del_proyecto__c = opportunities.get(
						approvalProcess.Opportunity__c
					)
					.Total_Proyecto__c;

				approvalProcess.total_de_la_cuenta__c = accounts.get(
						opportunities.get(approvalProcess.Opportunity__c)
							.AccountId
					)
					.Total_Proyecto__c;
			}
		}
	}

	@testVisible
	private static Map<Id, Opportunity> getOpportunitiesByApprovalProcess(
		List<ApprovalProcess__c> approvedRecords
	) {
		List<Id> oppIds = new List<Id>();

		for (ApprovalProcess__c approvalProcess : approvedRecords) {
			oppIds.add(approvalProcess.Opportunity__c);
		}

		Map<Id, Opportunity> mOpprotunities = new Map<id, Opportunity>(
			[
				SELECT id, name, Total_Proyecto__c, AccountId
				FROM Opportunity
				WHERE id IN :oppIds
			]
		);

		return mOpprotunities;
	}

	@testVisible
	private static Map<Id, Account> getAccountsByApprovalProcess(
		List<ApprovalProcess__c> approvedRecords,
		Map<Id, Opportunity> opportunities
	) {
		List<Id> AccountIds = new List<Id>();

		for (ApprovalProcess__c approvalProcess : approvedRecords) {
			AccountIds.add(
				opportunities.get(approvalProcess.Opportunity__c).AccountId
			);
		}

		Map<Id, Account> mAccounts = new Map<id, Account>(
			[
				SELECT id, name, Total_Proyecto__c
				FROM Account
				WHERE id IN :AccountIds
			]
		);

		return mAccounts;
	}

	@testVisible
	private static Map<Id, List<RGU__C>> getRGUPerApprovalProcess(
		List<ApprovalProcess__c> approvalProcess
	) {
		Map<Id, List<RGU__C>> mapRGUSPerApprovalProcess = new Map<Id, List<RGU__C>>();

		List<RGU_Change_to_approve__c> lRGUClones = [
			SELECT Referencia_Elara_Original__c, Approval_Process__c
			FROM RGU_Change_to_approve__c
			WHERE Approval_Process__c IN :approvalProcess
		];

		List<Id> lIDRGUs = new List<Id>();

		for (RGU_Change_to_approve__c rguClon : lRGUClones) {
			lIDRGUs.add(rguClon.Referencia_Elara_Original__c);
		}

		Map<Id, RGU__c> lRGUS = new Map<Id, RGU__c>(
			[
				SELECT id, name, Date_deactive_by_Client__c
				FROM RGU__c
				WHERE id IN :lIDRGUs
			]
		);

		for (RGU_Change_to_approve__c rguClon : lRGUClones) {
			if (
				mapRGUSPerApprovalProcess.get(rguClon.Approval_Process__c) ==
				null
			) {
				List<RGU__C> listRGUs = new List<RGU__C>();
				listRGUs.add(lRGUS.get(rguClon.Referencia_Elara_Original__c));
				mapRGUSPerApprovalProcess.put(
					rguClon.Approval_Process__c,
					listRGUs
				);
			} else {
				mapRGUSPerApprovalProcess.get(rguClon.Approval_Process__c)
					.add(lRGUS.get(rguClon.Referencia_Elara_Original__c));
			}
		}

		System.debug(mapRGUSPerApprovalProcess);

		return mapRGUSPerApprovalProcess;
	}

	public static List<String> getDirectorsMail(List<User> users) {
		List<String> lDirectorsMail = new List<String>();

		for (User user : users) {
			if (user.userrole.name == 'Dirección General') {
				lDirectorsMail.add(user.email);
			}
		}
		return lDirectorsMail;
	}

	public static List<String> getDocumentesMail(List<User> users) {
		List<String> lDocumentersMail = new List<String>();

		for (User user : users) {
			if (user.userrole.name == 'Gerencia Legal') {
				lDocumentersMail.add(user.email);
			}

			if (user.userrole.name == 'Gerencia de infraestructura') {
				lDocumentersMail.add(user.email);
			}

			if (user.userrole.name == 'Coordinación de pricing') {
				lDocumentersMail.add(user.email);
			}

			if (user.userrole.name == 'Gerencia de Aseguramiento de Ingresos') {
				lDocumentersMail.add(user.email);
			}
		}
		return lDocumentersMail;
	}

	public static List<String> getCommercialControlMail(List<User> users) {
		List<String> lCommercialControlMail = new List<String>();

		for (User user : users) {
			if (user.userrole.name == 'Ejecutivo de control comercial') {
				lCommercialControlMail.add(user.email);
			}
		}
		return lCommercialControlMail;
	}
}
