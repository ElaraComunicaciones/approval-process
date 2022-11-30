@isTest
public with sharing class addOLIManagerControllerTest {
	@isTest
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
			Action__c = 'Cambio - Altas crecimiento orgánico',
			Opportunity__c = testOpportunity.Id,
			Stage__c = 'Iniciado'
		);

		insert approval;

		TipoDeSitioPorAprobar__c tipoDeSitio = new TipoDeSitioPorAprobar__c(
			Lugar__c = 'AEROPUERTO',
			ID_Orden_de_compra_cliente__c = 'Id Orden de Compra',
			NumeroDeSitios__c = 1,
			Esquema_comercial__c = 'Esquema comercial',
			Fase__c = 2,
			Tipo_de_Configuracion__c = 'ESTÁNDAR',
			Tipo_de_solicitud__c = 'STD',
			Proceso_de_aprobacion__c = approval.id,
			Categoria_Unidad_Negocio__c = 'VSAT',
			Servicio__c = 'ISE',
			Tipo_de_Enlace__c = 'PRIMARIO',
			Esquema__c = 'FIJO',
			Banda__c = 'KU',
			BWBajadaKbps__c = 1024,
			BWSubidaKbps__c = 1024,
			SS_DW__c = 10,
			SS_UP__c = 10
		);

		TipoDeSitioPorAprobarTriggerSettings.insertWithoutTriggers(
			new List<TipoDeSitioPorAprobar__c>{ tipoDeSitio }
		);

		RGU_Change_to_approve__c reference = new RGU_Change_to_approve__c();
		reference.Tipo_de_sitio_por_aprobar__c = tipoDeSitio.Id;
		reference.Categoria_Unidad_de_Negocio__c = tipoDeSitio.Categoria_Unidad_Negocio__c;
		reference.Servicio__c = tipoDeSitio.Servicio__c;
		reference.Tipo_de_Enlace__c = tipoDeSitio.Tipo_de_Enlace__c;
		reference.Esquema__c = tipoDeSitio.Esquema__c;
		reference.Banda__c = tipoDeSitio.Banda__c;
		reference.BWBajadaKbps__c = tipoDeSitio.BWBajadaKbps__c;
		reference.SS_DW__c = tipoDeSitio.SS_DW__c;
		reference.BWSubidaKbps__c = tipoDeSitio.BWSubidaKbps__c;
		reference.SS_UP__c = tipoDeSitio.SS_UP__c;
		reference.Approval_Process__c = tipoDeSitio.Proceso_de_aprobacion__c;
		reference.Lugar__c = tipoDeSitio.Lugar__c;
		reference.Tipo_de_sitio_por_aprobar__c = tipoDeSitio.id;

		RGU_Change_to_approveTriggerSettings.insertWithoutTriggers(
			new List<RGU_Change_to_approve__c>{ reference }
		);

		testProduct = new Product2(
			Name = 'Test product',
			IsActive = true,
			ConceptoFacturacion__c = 'INSTALACION DE EQUIPO VSAT PARA PRESTACIÓN DE SERVICIO DE CONEXIÓN SATELITAL'
		);

		insert testProduct;

		PricebookEntry pricebookEntry = new PricebookEntry(
			Product2Id = testProduct.Id,
			Pricebook2Id = Test.getStandardPricebookId(),
			IsActive = true,
			UnitPrice = 500
		);

		insert pricebookEntry;

		OpportunityItemConsent__c oliWithoutTrigger = new OpportunityItemConsent__c(
			Product2Id__c = testProduct.id,
			Proceso_de_aprobacion__c = approval.id,
			Description__c = 'INSTALACION DE EQUIPO VSAT PARA PRESTACIÓN DE SERVICIO DE CONEXIÓN SATELITAL',
			PricebookEntryId__c = pricebookEntry.Id,
			Referencia_Elara_por_aprobar__c = reference.Id,
			UnitPrice__c = 1000,
			Tipo_de_ingreso__c = 'VENTA NUEVA',
			Divisa_de_Cotizacion__c = 'MXN',
			Quantity__c = 2,
			Fecha_Inicio_de_Ingreso__c = Date.today(),
			Forma_de_Cobro__c = 'Mensual',
			Plazo__c = 1
		);

		List<OpportunityItemConsent__c> lOlis = new List<OpportunityItemConsent__c>{
			oliWithoutTrigger
		};

		String jsonOlis = JSON.serialize(lOlis);

		addOLIManagerController.getRelatedOLIs(approval.id);

		addOLIManagerController.saveOLIs(approval.id, jsonOlis);

		DmlException ex = new DmlException();
		addOLIManagerController.exceptionTransactionResult(ex, lOlis);
	}
}