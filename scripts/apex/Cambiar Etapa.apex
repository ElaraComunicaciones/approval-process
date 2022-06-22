List<ApprovalProcess__c> procesoAprobacion = [
	SELECT id, name, Stage__c
	FROM ApprovalProcess__c
	WHERE id = 'a0v8N0000008PMsQAM'
	LIMIT 1
];

System.debug(procesoAprobacion);

procesoAprobacion[0].Stage__c = 'Solicitado';

ApprovalProcessTriggerSettings.updateWithoutTriggers(procesoAprobacion);
