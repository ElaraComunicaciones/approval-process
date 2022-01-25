public with sharing class ApprovalProcessTriggerSettings {
	private static Boolean isActive = false;
	private static Schema.sObjectType SObjectType = ApprovalProcess__c.sObjectType;

	static {
		isActive = isTriggerActive(SObjectType);
	}

	public static Boolean isTriggerActive(Schema.sObjectType SObjectType) {
		return TriggerSettings.isTriggerActive(SObjectType);
	}

	public static Boolean getCurrentActiveValue() {
		return isActive;
	}

	public static void setCurrentActiveValue(Boolean value) {
		isActive = value;
	}

	public static List<SObject> insertWithoutTriggers(List<SObject> records) {
		Boolean previousValue = getCurrentActiveValue();
		setCurrentActiveValue(false);
		insert records;
		setCurrentActiveValue(previousValue);

		return records;
	}

	public static List<SObject> updateWithoutTriggers(List<SObject> records) {
		Boolean previousValue = getCurrentActiveValue();
		setCurrentActiveValue(false);
		update records;
		setCurrentActiveValue(previousValue);

		return records;
	}

	public static List<SObject> deleteWithoutTriggers(List<SObject> records) {
		Boolean previousValue = getCurrentActiveValue();
		setCurrentActiveValue(false);
		delete records;
		setCurrentActiveValue(previousValue);

		return records;
	}
}
