public with sharing class ApprovalProcessAfterUpdateHandler extends TriggerHandlerBase {
	public override void mainEntry(TriggerParameters triggerParams) {
		System.debug('ApprovalProcessAfterUpdateHandler...');

		ApprovalProcessAPI.executeAfterUpdateProcesses(triggerParams);
	}
}
