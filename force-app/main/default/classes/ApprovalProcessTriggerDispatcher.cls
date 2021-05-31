public with sharing class ApprovalProcessTriggerDispatcher extends TriggerDispatcherBase  {
    private static Boolean isAfterUpdateProcessing = false;

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
