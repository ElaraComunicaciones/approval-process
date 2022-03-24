public with sharing class ApprovalProcessControlRGUController {
	@AuraEnabled
	public static List<RGU__c> getRelatedReferences(Id recordId) {
		try {
			List<RGU__c> lRGUs = [SELECT Id, Name FROM RGU__c LIMIT 2];

			return lRGUs;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}
