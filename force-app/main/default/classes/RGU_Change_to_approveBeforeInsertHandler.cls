public with sharing class RGU_Change_to_approveBeforeInsertHandler extends TriggerHandlerBase {
	public override void mainEntry(TriggerParameters triggerParams) {
		System.debug('RGU_Change_to_approveBeforeInsertHandler...');
		RGU_Change_to_approveAPI.executeBeforeInsertProcess(triggerParams);
	}
}
