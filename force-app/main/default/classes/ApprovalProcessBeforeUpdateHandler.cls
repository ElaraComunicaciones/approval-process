public with sharing class ApprovalProcessBeforeUpdateHandler extends TriggerHandlerBase {
	public override void mainEntry(TriggerParameters triggerParams) {
		System.debug('ApprovalProcessBeforeUpdateHandler...');
		ApprovalProcessAPI.changeStage(triggerParams.newList);
	}
}
