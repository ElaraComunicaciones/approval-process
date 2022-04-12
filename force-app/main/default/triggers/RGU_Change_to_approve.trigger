trigger RGU_Change_to_approve on RGU_Change_to_approve__c(
	after insert,
	after update,
	after delete,
	before insert,
	before update,
	before delete,
	after undelete
) {
	if (RGU_Change_to_approveTriggerSettings.getCurrentActiveValue())
		TriggerFactory.createTriggerDispatcher(
			RGU_Change_to_approve__c.sObjectType
		);
}
