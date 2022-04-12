trigger ApprovalProcessTrigger on ApprovalProcess__c(
	after insert,
	after update,
	after delete,
	before insert,
	before update,
	before delete,
	after undelete
) {
	if (ApprovalProcessTriggerSettings.getCurrentActiveValue())
		TriggerFactory.createTriggerDispatcher(ApprovalProcess__c.sObjectType);
}
