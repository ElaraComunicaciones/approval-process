@isTest
public with sharing class ApprovalProcessAPITest {
	@istest
	public static void createEPWithApprovalProcess() {
		Test.setMock(HttpCalloutMock.class, new COSAPI_MockTesting());

		OpportunityTriggerSettings.setCurrentActiveValue(false);
		AccountTriggerSettings.setCurrentActiveValue(false);
		TipoDeSitioTriggerSettings.setCurrentActiveValue(false);
		RGUTriggerSettings.setCurrentActiveValue(false);

		Account testAccount = new Account(
			Name = 'Cuenta A',
			Razon_Social__c = 'CUENTA SA DE CV A',
			Industry = 'CAT',
			OrigenDeLaCuenta__c = 'Cliente Actual',
			RFC__c = 'POT151008L69',
			BillingPostalCode = '86037',
			ID_Fiscal__c = '',
			Tiene_Contratos_Activos__c = true
		);

		insert testAccount;

		Proyecto__c testProject = new Proyecto__c(
			Name = 'Test project with a long name',
			Unidad_de_Negocio__c = 'CONECTIVIDAD',
			Categoria_Unidad_Negocio__c = 'VSAT'
		);

		insert testProject;

		Pricebook2 testPricebook = new Pricebook2(
			Name = 'testStandardListPrice',
			IsActive = true
		);

		insert testPricebook;

		Product2 testProduct = new Product2(
			Name = 'Test product',
			IsActive = true,
			ConceptoFacturacion__c = 'PRODUCTO DE PRUEBA PT'
		);

		insert testProduct;

		PricebookEntry testEntry = new PricebookEntry(
			Product2Id = testProduct.Id,
			Pricebook2Id = Test.getStandardPricebookId(),
			IsActive = true,
			UnitPrice = 500
		);

		insert testEntry;

		Opportunity testOpportunity = new Opportunity(
			Sector_Comercial__c = 'Privado',
			StageName = 'Cierre',
			CloseDate = System.today(),
			Name = 'a',
			AccountId = testAccount.Id,
			NombreDelProyecto__c = testProject.Id,
			Pricebook2Id = Test.getStandardPricebookId()
		);

		insert testOpportunity;

		TipoDeSitio__c testSite = new TipoDeSitio__c(
			NumeroDeExpedienteDeProyecto__c = testOpportunity.Id,
			Nombre_Completo__c = 'testing site',
			NumeroDeSitios__c = 10
		);

		TipoDeSitioTriggerSettings.insertWithoutTriggers(
			new List<TipoDeSitio__c>{ testSite }
		);

		RGU__c testReference = new RGU__c(
			Tipo_de_sitio__c = testSite.Id,
			NumeroDeExpedienteDeProyecto__c = testOpportunity.Id
		);

		insert testReference;

		System.debug(testReference);

		List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();

		OpportunityLineItem testLineItemSite = new OpportunityLineItem(
			OpportunityId = testOpportunity.Id,
			Referencia_Elara__c = testReference.Id,
			PricebookEntryId = testEntry.Id,
			Tipo_de_sitio__c = testSite.Id,
			UnitPrice = 1000,
			UnitPrice__c = 1000,
			Quantity = 2,
			Forma_de_Cobro__c = 'Mensual',
			Fecha_Inicio_Ingreso__c = Date.today(),
			Fecha_Fin_Ingreso__c = Date.today(),
			Plazo__c = 3,
			Divisa_de_Cotizacion__c = 'USD',
			Linea_de_Negocio__c = 'Conectividad'
		);

		OpportunityLineItem testLineItemReference = new OpportunityLineItem(
			OpportunityId = testOpportunity.Id,
			PricebookEntryId = testEntry.Id,
			Referencia_Elara__c = testReference.Id,
			UnitPrice = 1000,
			UnitPrice__c = 1000,
			Quantity = 2,
			Forma_de_Cobro__c = 'Mensual',
			Fecha_Inicio_Ingreso__c = Date.today(),
			Plazo__c = 3,
			Divisa_de_Cotizacion__c = 'USD',
			Linea_de_Negocio__c = 'Conectividad'
		);

		lineItems.add(testLineItemSite);
		lineItems.add(testLineItemReference);

		insert lineItems;

		ApprovalProcess__c approval = new ApprovalProcess__c(
			Nombre__c = 'Proceso de prueba',
			Detail__c = 'Detalle',
			Action__c = 'Baja definitiva',
			Opportunity__c = testOpportunity.Id,
			Stage__c = 'Iniciado'
		);

		insert approval;

		List<RGU__c> referencia = ApprovalProcessControlRGUController.getRelatedReferences(
			approval.Id
		);

		ApprovalProcessControlRGUController.saveRGUChangeToApprove(
			approval.id,
			approval.stage__c,
			referencia
		);
	}

	@istest
	public static void testChangeStageToSolicitado() {
		createEPWithApprovalProcess();

		//Obtener todos los campos del proceso de aprobación
		SObjectType approvalProcessType = Schema.getGlobalDescribe()
			.get('ApprovalProcess__c');
		Map<String, Schema.SObjectField> mfields = approvalProcessType.getDescribe()
			.fields.getMap();

		String selectSentence = '';

		for (String fieldName : mfields.keySet()) {
			selectSentence += fieldName + ',';
		}

		List<ApprovalProcess__c> newList = Database.query(
			'select ' +
			selectSentence.Substring(0, selectSentence.length() - 1) +
			' from ApprovalProcess__c'
		);

		DeactivateApprovalProcess.validateCompleteInformation(newList[0]);

		newList[0].stage__c = 'Solicitado';

		//Validamos el cambio de etapa de iniciado a solicitado
		update newList;
	}

	@istest
	public static void testChangeStageToAprovado() {
		createEPWithApprovalProcess();

		//Obtener todos los campos del proceso de aprobación
		SObjectType approvalProcessType = Schema.getGlobalDescribe()
			.get('ApprovalProcess__c');
		Map<String, Schema.SObjectField> mfields = approvalProcessType.getDescribe()
			.fields.getMap();

		String selectSentence = '';

		for (String fieldName : mfields.keySet()) {
			selectSentence += fieldName + ',';
		}

		List<ApprovalProcess__c> newList = Database.query(
			'select ' +
			selectSentence.Substring(0, selectSentence.length() - 1) +
			' from ApprovalProcess__c'
		);

		DeactivateApprovalProcess.validateCompleteInformation(newList[0]);

		newList[0].stage__c = 'Solicitado';

		//Validamos el cambio de etapa de iniciado a solicitado
		ApprovalProcessTriggerSettings.updateWithoutTriggers(newList);

		newList[0].stage__c = 'Aprobado';
		update newList;
	}

	@istest
	public static void testChangeStageSolicitadoToCancelado() {
		createEPWithApprovalProcess();

		//Obtener todos los campos del proceso de aprobación
		SObjectType approvalProcessType = Schema.getGlobalDescribe()
			.get('ApprovalProcess__c');
		Map<String, Schema.SObjectField> mfields = approvalProcessType.getDescribe()
			.fields.getMap();

		String selectSentence = '';

		for (String fieldName : mfields.keySet()) {
			selectSentence += fieldName + ',';
		}

		List<ApprovalProcess__c> newList = Database.query(
			'select ' +
			selectSentence.Substring(0, selectSentence.length() - 1) +
			' from ApprovalProcess__c'
		);

		newList[0].stage__c = 'Solicitado';

		//Validamos el cambio de etapa de iniciado a solicitado
		update newList;

		//Con este update sin cambio, validamos el progreso de los campos a llenar cuando es por comité directivo
		update newList;

		newList[0].stage__c = 'Cancelado';
		newList[0].Motivo_rechazo_o_cancelacion__c = 'Porque puedo';
		update newList;
	}

	@istest
	public static void testChangeStageSolicitadoToRechazado() {
		createEPWithApprovalProcess();

		//Obtener todos los campos del proceso de aprobación
		SObjectType approvalProcessType = Schema.getGlobalDescribe()
			.get('ApprovalProcess__c');
		Map<String, Schema.SObjectField> mfields = approvalProcessType.getDescribe()
			.fields.getMap();

		String selectSentence = '';

		for (String fieldName : mfields.keySet()) {
			selectSentence += fieldName + ',';
		}

		List<ApprovalProcess__c> newList = Database.query(
			'select ' +
			selectSentence.Substring(0, selectSentence.length() - 1) +
			' from ApprovalProcess__c'
		);

		newList[0].stage__c = 'Solicitado';

		//Validamos el cambio de etapa de iniciado a solicitado
		update newList;

		//Con este update sin cambio, validamos el progreso de los campos a llenar cuando es por comité directivo
		update newList;

		newList[0].stage__c = 'Rechazado';
		newList[0].Motivo_rechazo_o_cancelacion__c = 'Porque puedo';
		update newList;
	}
}