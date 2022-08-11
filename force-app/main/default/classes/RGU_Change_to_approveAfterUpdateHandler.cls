public with sharing class RGU_Change_to_approveAfterUpdateHandler extends TriggerHandlerBase {
	public override void mainEntry(TriggerParameters triggerParams) {
		System.debug('RGU_Change_to_approveAfterUpdateHandler...');
		RGU_Change_to_approveAPI.executeAfterUpdateProcess(triggerParams);
	}
}