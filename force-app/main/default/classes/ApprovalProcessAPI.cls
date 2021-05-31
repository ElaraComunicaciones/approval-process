public with sharing class ApprovalProcessAPI {
	public static void executeAfterUpdateProcesses(
		TriggerParameters triggerParams
	) {
		List<ApprovalProcess__c> newRecords = getNewRecords(
			triggerParams.newList
		);

		List<ApprovalProcess__c> newRequestedRecords = filterNewRequestedRecords(
			triggerParams.oldMap,
			newRecords
		);

		List<ApprovalProcessControlRGU__c> referenceControls = getRelatedReferenceControls(
			newRequestedRecords
		);
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
			message.toAddresses = new List<String>{
				'0050W000007E7SbQAK'
			};
			message.ccAddresses = new List<String>{
				'005d0000004T3pwAAC'
			};
			message.optOutPolicy = 'SEND';
			message.subject = 'Solicitud de aprobación para el proceso ' + ;
			message.plainTextBody = 'This is the message body.';
			messages.add(message);
		}

		// Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
	}

	public static Map<Id, List<ApprovalProcessControlRGU__c>> getApprovalRGUControls(
		List<ApprovalProcessControlRGU__c> approvalRGUControls
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
				approvalRGUControls.put(relatedRGUControls);
			}
			relatedRGUControls.add(control);
		}

		return approvalRGUControls;
	}

	public static List<ApprovalProcessControRGU__c> getRelatedReferenceControls(
		List<ApprovalProcess__c> newRequestedRecords
	) {
		List<ApprovalProcessControlRGU__c> referenceControls = new List<ApprovalProcessControlRGU__c>();

		referenceControls = [
			SELECT
				Id,
				ApprovalProcess__c ApprovalProcess__r.Action__c,
				ApprovalProcess__r.Stage__c
			FROM ApprovalProcessControlRGU__c
			WHERE ApprovalProcess__c IN :newRequestedRecords
		];

		return referenceControls;
	}

	public static List<ApprovalProcess__c> filterNewRequestedRecords(
		Map<Id, SObject> oldMap,
		List<ApprovalProcess__c> newRecords
	) {
		List<ApprovalProcess__c> newRequestedRecords;

		for (ApprovalProcess__c newApproval : newRecords) {
			ApprovalProcess__c oldApproval = (ApprovalProcess__c) oldMap.get(
				newApproval.Id
			);
			if (
				oldApproval.Stage__c == 'Inciado' &&
				newApproval.Stage__c == 'Solicitado'
			) {
				newRequestedRecords.add(newApproval);
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
