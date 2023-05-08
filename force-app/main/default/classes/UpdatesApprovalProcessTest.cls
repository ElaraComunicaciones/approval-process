@istest
public with sharing class UpdatesApprovalProcessTest {
	@TestSetup
	static void makeData() {
		Test.setMock(HttpCalloutMock.class, new COSAPI_MockTesting());

		OpportunityTriggerSettings.setCurrentActiveValue(false);
		AccountTriggerSettings.setCurrentActiveValue(false);
		TipoDeSitioTriggerSettings.setCurrentActiveValue(false);
		RGUTriggerSettings.setCurrentActiveValue(false);
		OpportunityLineItemTriggerSettings.setCurrentActiveValue(false);

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

		insert testSite;

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
			Fecha_Fin_Ingreso__c = Date.today().ADDMONTHS(3),
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
			Fecha_Fin_Ingreso__c = Date.today().ADDMONTHS(3),
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
			Action__c = 'Cambio - Actualización',
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

		RGU_Change_to_approve__c reference = [
			SELECT Id, Name
			FROM RGU_Change_to_approve__c
			LIMIT 1
		];

		OpportunityItemConsent__c oli = new OpportunityItemConsent__c();
		oli.Proceso_de_aprobacion__c = approval.id;
		oli.PricebookEntryId__c = testEntry.Id;
		oli.Referencia_Elara_por_aprobar__c = reference.Id;
		oli.UnitPrice__c = 1000;
		oli.Quantity__c = 1;
		oli.Fecha_Inicio_de_Ingreso__c = Date.today();
		oli.Forma_de_Cobro__c = 'Pago Único';
		oli.Plazo__c = 1;

		insert oli;

		UpdatesApprovalProcess.validateCompleteInformation(Approval);
	}

	@istest
	static void TestingRequestApproval() {
		OpportunityTriggerSettings.setCurrentActiveValue(false);
		AccountTriggerSettings.setCurrentActiveValue(false);
		TipoDeSitioTriggerSettings.setCurrentActiveValue(false);
		RGUTriggerSettings.setCurrentActiveValue(false);
		OpportunityLineItemTriggerSettings.setCurrentActiveValue(false);

		ApprovalProcess__c approval = [
			SELECT id, Stage__c
			FROM ApprovalProcess__c
			LIMIT 1
		];

		approval.Stage__c = 'Solicitado';

		Test.startTest();
		update approval;
		Test.stopTest();
	}

	@istest
	static void TestingApprovedApproval() {
		OpportunityTriggerSettings.setCurrentActiveValue(false);
		AccountTriggerSettings.setCurrentActiveValue(false);
		TipoDeSitioTriggerSettings.setCurrentActiveValue(false);
		RGUTriggerSettings.setCurrentActiveValue(false);
		OpportunityLineItemTriggerSettings.setCurrentActiveValue(false);

		ApprovalProcess__c approval = [
			SELECT id, Stage__c
			FROM ApprovalProcess__c
			LIMIT 1
		];

		approval.Stage__c = 'Solicitado';
		ApprovalProcessTriggerSettings.updateWithoutTriggers(
			new List<ApprovalProcess__c>{ approval }
		);

		approval.Stage__c = 'Aprobado';

		update approval;
	}

	// @istest
	// static void TestingRejectApproval() {
	// 	OpportunityTriggerSettings.setCurrentActiveValue(false);
	// 	AccountTriggerSettings.setCurrentActiveValue(false);
	// 	TipoDeSitioTriggerSettings.setCurrentActiveValue(false);
	// 	RGUTriggerSettings.setCurrentActiveValue(false);
	// 	OpportunityLineItemTriggerSettings.setCurrentActiveValue(false);

	// 	ApprovalProcess__c approval = [
	// 		SELECT
	// 			id,
	// 			Stage__c,
	// 			Saldo_cubierto_a_la_fecha__c,
	// 			Saldo_pendiente_de_pago__c,
	// 			Cantidad_de_facturas_pendientes__c,
	// 			Margen_Bruto__c,
	// 			CAPEX__c,
	// 			Divisa_CAPEX__c,
	// 			EBITDA__c,
	// 			EBIT__c,
	// 			Payback__c,
	// 			Par_metros_de_rentabilidad__c,
	// 			ROI__c,
	// 			TIR__c,
	// 			Ingresos_por_cubrir__c,
	// 			Costos_por_cubrir__c,
	// 			Proveedor_es_y_banda_del_SE__c,
	// 			Vigencia_contrato_proveedor_satelital__c,
	// 			Proxima_fecha_cambio_segmento__c,
	// 			Monto_Cambio_SE__c
	// 		FROM ApprovalProcess__c
	// 		LIMIT 1
	// 	];

	// 	UpdatesApprovalProcess.validateCompleteInformation(Approval);

	// 	approval.Stage__c = 'Solicitado';

	// 	update approval;

	// 	approval.Stage__c = 'Rechazado';
	// 	approval.Motivo_rechazo_o_cancelacion__c = 'Motivo Rechazo';

	// 	update approval;
	// }
}