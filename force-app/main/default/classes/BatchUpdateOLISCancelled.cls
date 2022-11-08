public with sharing class BatchUpdateOLISCancelled implements Database.Batchable<SObject>, Database.stateful {
	private Set<Id> setIdsOlis;
	private String query;

	public BatchUpdateOLISCancelled(String query, Set<Id> setIdsOlis) {
		this.query = query;
		this.setIdsOlis = setIdsOlis;
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		for (OpportunityLineItem oli : (List<OpportunityLineItem>) scope) {
			oli.UnitPrice__c = 0;
		}

		OpportunityTriggerSettings.setCurrentActiveValue(false);
		OpportunityLineItemTriggerSettings.setCurrentActiveValue(false);
		TipoDeSitioTriggerSettings.setCurrentActiveValue(false);
		update scope;
	}

	public void finish(Database.BatchableContext BC) {
		String query =
			'SELECT Id ' +
			' FROM OpportunityLineItemSchedule ' +
			' WHERE OpportunityLineItemId IN :items';

		List<OpportunityLineItem> newList = [
			SELECT id
			FROM OpportunityLineItem
			WHERE id IN :setIdsOlis
		];

		ID batchprocessid = Database.executeBatch(
			new BatchDeleteCreateScheduledItems(query, newList),
			200
		);
	}
}