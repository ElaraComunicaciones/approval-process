@IsTest
public with sharing class RGU_Change_to_approveTriggerSettingsTest {
	@isTest
	public static void insertWithoutTriggersTest() {
		List<SObject> rguToApprove = [SELECT Id FROM RGU_Change_to_approve__c];
		List<SObject> dmlResults = RGU_Change_to_approveTriggerSettings.insertWithoutTriggers(
			rguToApprove
		);
		System.assertEquals(rguToApprove.size(), dmlResults.size());
	}
	@IsTest
	public static void updateWithoutTriggersTest() {
		List<SObject> rguToApprove = [SELECT Id FROM RGU_Change_to_approve__c];
		List<SObject> dmlResults = RGU_Change_to_approveTriggerSettings.updateWithoutTriggers(
			rguToApprove
		);
		System.assertEquals(rguToApprove.size(), dmlResults.size());
	}

	@IsTest
	public static void deleteWithoutTriggersTest() {
		List<SObject> rguToApprove = [SELECT Id FROM RGU_Change_to_approve__c];
		List<SObject> dmlResults = RGU_Change_to_approveTriggerSettings.deleteWithoutTriggers(
			rguToApprove
		);
		System.assertEquals(rguToApprove.size(), dmlResults.size());
	}
}