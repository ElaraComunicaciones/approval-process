public with sharing class RGU_Change_to_approveTriggerDispatcher extends TriggerDispatcherBase {
	private static Boolean isBeforeInsertProcessing = false;
	private static Boolean isAfterUpdateProcessing = false;

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

	public virtual override void afterUpdate(TriggerParameters triggerParams) {
		if (!isAfterUpdateProcessing) {
			isAfterUpdateProcessing = true;
			execute(
				new RGU_Change_to_approveAfterUpdateHandler(),
				triggerParams,
				TriggerParameters.TriggerEvent.AFTER_UPDATE
			);
			isAfterUpdateProcessing = false;
		}
	}
}
