public with sharing class ApprovalProcessAPI {
	public static void executeAfterUpdateProcesses(
		TriggerParameters triggerParams
	) {
		List<ApprovalProcess__c> newRecords = getNewRecords(
			triggerParams.newList
		);

		System.debug(newRecords);

		List<ApprovalProcess__c> newRequestedRecords = filterNewRequestedRecords(
			triggerParams.oldMap,
			newRecords
		);

		System.debug(newRequestedRecords);

		List<ApprovalProcess__c> newApprovedRecords = filterNewApprovedRecords(
			triggerParams.oldMap,
			newRecords
		);

		if (newApprovedRecords != null) {
			List<ApprovalProcessControlRGU__c> approvedReferenceControls = getRelatedReferenceControls(
				newApprovedRecords
			);
			copyApprovedRecords(approvedReferenceControls);
		}

		if (newRequestedRecords != null) {
			List<ApprovalProcessControlRGU__c> referenceControls = getRelatedReferenceControls(
				newRequestedRecords
			);

			System.debug(referenceControls);

			sendNotifications(referenceControls);
		}
	}

	public static void copyApprovedRecords(
		List<ApprovalProcessControlRGU__c> referenceControls
	) {
		List<RGU__c> originalRgus = new List<RGU__c>();
		List<RGU__c> newRGUs = new List<RGU__c>();


		for (ApprovalProcessControlRGU__c control : referenceControls) {
			if (control.oldRGU__c == null) {
				RGU__c newRecord = new RGU__c(
					Id = control.newRGU__c,
					BWBajadaKbps__c = control.newRGU__r.BWBajadaKbps__c,
					ApprovalStatus__c = 'Aprobado'
				);
				newRGUs.add(newRecord);
			} else {
				RGU__c original = new RGU__c(
					Id = control.oldRGU__c,
					BWBajadaKbps__c = control.oldRGU__r.BWBajadaKbps__c
				);
				RGU__c newRecord = new RGU__c(
					Id = control.newRGU__c,
					BWBajadaKbps__c = control.newRGU__r.BWBajadaKbps__c,
					ApprovalStatus__c = 'Aprobado'
				);

				original.BWBajadaKbps__c = newRecord.BWBajadaKbps__c;  
				originalRgus.add(original);
				newRGUs.add(newRecord);
			}
		}

		update originalRgus;
		update newRGUs;
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
			message.ccAddresses = new List<String>{ '005d0000004T3pwAAC', '005d00000025U5kAAE' };
			message.optOutPolicy = 'SEND';
			message.subject =
				'Solicitud de aprobación para el proceso ' +
				controlList[0].ApprovalProcess__r.Name;
			message.plainTextBody = 'Cambios en las siguientes referencias \n';
			for (ApprovalProcessControlRGU__c control : controlList) {
				message.plainTextBody +=
					control.NewRGU__r.Referencia_Elara__c + '\n';
			}
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
				NewRGU__r.Referencia_Elara__c,
				ApprovalProcess__r.Action__c,
				ApprovalProcess__r.Stage__c, 
				oldRGU__c,
				oldRGU__r.BWBajadaKbps__c,
				newRGU__c,
				newRGU__r.BWBajadaKbps__c
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
}
