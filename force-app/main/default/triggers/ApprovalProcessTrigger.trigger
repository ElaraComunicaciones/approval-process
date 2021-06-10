trigger ApprovalProcessTrigger on ApprovalProcess__c(
	after insert,
	after update,
	after delete,
	before insert,
	before update,
	before delete,
	after undelete
) {
	TriggerFactory.createTriggerDispatcher(ApprovalProcess__c.sObjectType);
}
