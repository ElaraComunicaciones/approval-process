public with sharing class addOLIManagerController {
	@AuraEnabled
	public static String getRelatedOLIs(Id recordId) {
		List<SObject> relatedOLIS = null;
		String jsonResponse = null;
		String dynamicQuery = null;

		dynamicQuery =
			'select id, (SELECT Id, Name, PricebookEntryId__c, Product2Id__r.Name, Quantity__c, ' +
			' Divisa_de_Cotizacion__c,Forma_de_Cobro__c,TipoDeCambioCotizado__c, Partida_Ventas_MXN__c, ' +
			' Partida_Ventas_USD__c, Description__c, UnitPrice__c, Plazo__c,Fecha_Inicio_de_Ingreso__c, ' +
			' Fecha_Fin_Ingreso__c, Tipo_de_ingreso__c  from Productos_de_oportunidad_por_aprobar__r) ' +
			' from ApprovalProcess__c where id = \'' +
			recordId +
			'\'';

		List<SObject> records = Database.query(dynamicQuery);

		for (SObject record : records) {
			relatedOLIS = getChildOLIs(record);
		}

		System.debug(relatedOLIS);
		relatedOLIS = (relatedOLIS != null) ? relatedOLIS : new List<SObject>();

		jsonResponse = JSON.serialize(relatedOLIS);

		return jsonResponse;
	}

	private static List<SObject> getChildOLIs(SObject record) {
		List<SObject> relatedOLIS = null;
		String sObjectName = null;
		Id recordId = null;

		recordId = record.Id;
		sObjectName = recordId.getSobjectType().getDescribe().getName();
		relatedOLIS = record.getSObjects(
			'Productos_de_oportunidad_por_aprobar__r'
		);

		return relatedOLIS;
	}

	@AuraEnabled
	public static TransactionResults saveOLIs(Id recordId, String products) {
		TransactionResults results;

		List<OpportunityItemConsent__c> olis = (List<OpportunityItemConsent__c>) JSON.deserialize(
			products,
			List<OpportunityItemConsent__c>.class
		);

		System.debug(recordId);
		System.debug(olis);

		map<Id, Product2> mProductos = queryProduct2(olis);

		List<RGU_Change_to_approve__c> rgusToApprove = getRGUSPerApprovalProcess(
			recordId
		);

		List<OpportunityItemConsent__c> olisToInsert = new List<OpportunityItemConsent__c>();

		for (Integer i = 0; i < olis.size(); i++) {
			for (
				Integer cantidad = 0; cantidad < olis[i].Quantity__c; cantidad++
			) {
				if (cantidad < rgusToApprove.size()) {
					OpportunityItemConsent__c oli = new OpportunityItemConsent__c();

					oli.Proceso_de_aprobacion__c = recordId;
					oli.Referencia_Elara_por_aprobar__c = rgusToApprove[
							cantidad
						]
						.id;

					oli.Product2Id__c = olis[i].Product2Id__c;
					oli.PricebookEntryId__c = olis[i].PricebookEntryId__c;

					oli.Description__c = olis[i].Description__c != null
						? olis[i].Description__c.abbreviate(255)
						: null;
					oli.UnitPrice__c = olis[i].UnitPrice__c;
					oli.Quantity__c = 1;
					oli.Divisa_de_Cotizacion__c = olis[i]
						.Divisa_de_Cotizacion__c;
					oli.Forma_de_Cobro__c = olis[i].Forma_de_Cobro__c;
					oli.TipoDeCambioCotizado__c = olis[i]
						.TipoDeCambioCotizado__c;
					oli.Plazo__c = olis[i].Plazo__c;
					oli.Fecha_Inicio_de_Ingreso__c = olis[i]
						.Fecha_Inicio_de_Ingreso__c;
					oli.Fecha_Fin_Ingreso__c = olis[i].Fecha_Fin_Ingreso__c;
					oli.Tipo_de_ingreso__c = olis[i].Tipo_de_ingreso__c;
					oli.Categoria_Costos__c = mProductos.get(oli.Product2Id__c)
						.Categoria_Costos__c;
					oli.Subcategoria_Costos__c = mProductos.get(
							oli.Product2Id__c
						)
						.Subcategoria_Costos__c;
					oli.Equipo_en_renta__c = mProductos.get(oli.Product2Id__c)
						.Equipo_en_renta__c;

					olisToInsert.add(oli);
				}
			}
		}

		try {
			insert olisToInsert;
			results = new TransactionResults(JSON.serialize(olisToInsert));
		} catch (DmlException e) {
			CustomException exceptionLog = exceptionTransactionResult(e, olis);
			results = new TransactionResults(exceptionLog);
			exceptionLog.recordExceptionLog();
		}

		return results;
	}

	private static List<RGU_Change_to_approve__c> getRGUSPerApprovalProcess(
		id recordID
	) {
		List<RGU_Change_to_approve__c> lRGUToApprove = [
			SELECT id, name, Nombre_RGU_Original__c
			FROM RGU_Change_to_approve__c
			WHERE Approval_Process__c = :recordID
		];

		return lRGUToApprove;
	}

	private static map<Id, Product2> queryProduct2(
		List<OpportunityItemConsent__c> lLineItems
	) {
		Set<Id> setIdsProduct2 = new Set<Id>();

		for (OpportunityItemConsent__c lineItem : lLineItems) {
			setIdsProduct2.add(lineItem.Product2Id__c);
		}

		List<Product2> productos = [
			SELECT
				Categoria_Costos__c,
				Equipo_en_renta__c,
				Id,
				Subcategoria_Costos__c
			FROM Product2
			WHERE id = :setIdsProduct2
		];

		Map<id, Product2> mProductos = new Map<id, Product2>(productos);

		return mProductos;
	}

	@testVisible
	private static CustomException exceptionTransactionResult(
		DmlException e,
		list<OpportunityItemConsent__c> olis
	) {
		return new CustomException(
			e.getMessage(),
			'No se pudieron guardar los productos de oportunidad',
			e.getTypeName(),
			e.getStackTraceString(),
			'OLIManagerToApproveController.saveOLIs',
			JSON.serialize(olis),
			UserInfo.getUserId()
		);
	}
}