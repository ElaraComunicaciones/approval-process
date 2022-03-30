public with sharing class ApprovalProcessBeforeInsertHandler extends TriggerHandlerBase {
	public override void mainEntry(TriggerParameters triggerParams) {
		System.debug('ApprovalProcessBeforeInsertHandler...');
		ApprovalProcessAPI.executeBeforeInsertProcess(triggerParams);
	}
}
