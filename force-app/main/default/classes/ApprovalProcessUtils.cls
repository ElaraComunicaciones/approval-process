public with sharing class ApprovalProcessUtils {
	public static List<String> getSObjectFields(String sObjectName) {
		List<String> requestedFields = new List<String>();
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
		Schema.SObjectType sobjectType = globalDescribe.get(sObjectName);
		Schema.DescribeSObjectResult r = sobjectType.getDescribe();
		Map<String, Schema.SObjectField> fieldsMap = r.fields.getMap();

		for (String fieldName : fieldsMap.keySet()) {
			Schema.SObjectField field = fieldsMap.get(fieldName);
			Schema.DescribeFieldResult fieldResult = field.getDescribe();
			System.debug('field --> ' + field);
			System.debug('fieldResult --> ' + fieldResult.getType()); //type of field
			requestedFields.add(field);
		}

		System.debug(requestedFields);

		return requestedFields;
	}

	public static List<String> getFieldSet(String sObjectFieldSet) {
	}
}
