public with sharing class ApprovalProcessTriggerDispatcher extends TriggerDispatcherBase {
	private static Boolean isAfterUpdateProcessing = false;
	private static Boolean isBeforeInsertProcessing = false;
	private static Boolean isBeforeUpdateProcessing = false;

	public virtual override void beforeInsert(TriggerParameters triggerParams) {
		if (!isBeforeInsertProcessing) {
			isBeforeInsertProcessing = true;
			execute(
				new ApprovalProcessBeforeInsertHandler(),
				triggerParams,
				TriggerParameters.TriggerEvent.BEFORE_INSERT
			);
			isBeforeInsertProcessing = false;
		}
	}

	public virtual override void beforeUpdate(TriggerParameters triggerParams) {
		if (!isBeforeUpdateProcessing) {
			isBeforeUpdateProcessing = true;
			execute(
				new ApprovalProcessBeforeUpdateHandler(),
				triggerParams,
				TriggerParameters.TriggerEvent.BEFORE_UPDATE
			);
			isBeforeUpdateProcessing = false;
		}
	}

	public virtual override void afterUpdate(TriggerParameters triggerParams) {
		if (!isAfterUpdateProcessing) {
			isAfterUpdateProcessing = true;
			execute(
				new ApprovalProcessAfterUpdateHandler(),
				triggerParams,
				TriggerParameters.TriggerEvent.AFTER_UPDATE
			);
			isAfterUpdateProcessing = false;
		}
	}
}
