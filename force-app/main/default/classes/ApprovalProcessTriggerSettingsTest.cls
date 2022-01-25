@IsTest
public with sharing class ApprovalProcessTriggerSettingsTest {
	@isTest
	public static void insertWithoutTriggersTest() {
		List<SObject> approvalProcess = [SELECT Id FROM ApprovalProcess__c];
		List<SObject> dmlResults = ApprovalProcessTriggerSettings.insertWithoutTriggers(
			approvalProcess
		);
		System.assertEquals(approvalProcess.size(), dmlResults.size());
	}
	@IsTest
	public static void updateWithoutTriggersTest() {
		List<SObject> approvalProcess = [SELECT Id FROM ApprovalProcess__c];
		List<SObject> dmlResults = ApprovalProcessTriggerSettings.updateWithoutTriggers(
			approvalProcess
		);
		System.assertEquals(approvalProcess.size(), dmlResults.size());
	}

	@IsTest
	public static void deleteWithoutTriggersTest() {
		List<SObject> approvalProcess = [SELECT Id FROM ApprovalProcess__c];
		List<SObject> dmlResults = ApprovalProcessTriggerSettings.deleteWithoutTriggers(
			approvalProcess
		);
		System.assertEquals(approvalProcess.size(), dmlResults.size());
	}
}
