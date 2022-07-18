public with sharing class RGU_Change_to_approveTriggerDispatcher extends TriggerDispatcherBase {
	private static Boolean isBeforeInsertProcessing = false;

	public virtual override void beforeInsert(TriggerParameters triggerParams) {
		if (!isBeforeInsertProcessing) {
			isBeforeInsertProcessing = true;
			execute(
				new RGU_Change_to_approveBeforeInsertHandler(),
				triggerParams,
				TriggerParameters.TriggerEvent.BEFORE_INSERT
			);
			isBeforeInsertProcessing = false;
		}
	}
}