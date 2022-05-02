public with sharing class ApprovalProcessBeforeUpdateHandler extends TriggerHandlerBase {
	public override void mainEntry(TriggerParameters triggerParams) {
		System.debug('ApprovalProcessBeforeUpdateHandler...');
		ApprovalProcessAPI.changeStage(
			(List<ApprovalProcess__c>) triggerParams.newList
		);

		ApprovalProcessAPI.setTotalProjectAndTotalAccount(
			triggerParams.oldMap,
			(List<ApprovalProcess__c>) triggerParams.newList
		);

		ApprovalProcessAPI.executeBeforeUpdateProcess(triggerParams);
	}
}
