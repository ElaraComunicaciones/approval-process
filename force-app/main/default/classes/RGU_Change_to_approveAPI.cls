public with sharing class RGU_Change_to_approveAPI {
	public static void executeBeforeInsertProcess(
		TriggerParameters triggerParams
	) {
		//Convertimos los nuevos registros al tipo de Proceso de aprobacion
		List<RGU_Change_to_approve__c> lRGUToApprove = (List<RGU_Change_to_approve__c>) triggerParams.newList;

		setVTCPerRGUOriginal(lRGUToApprove);
	}

	//Establece el vtc para cada Referencia elara, es importante para poder validar si la aprobación es por comité directivo o control comercial
	@testVisible
	private static void setVTCPerRGUOriginal(
		List<RGU_Change_to_approve__c> lRGUsToChange
	) {
		//Obtenemos las id referencias Elara Originales

		List<id> idsRGUs = new List<id>();

		for (RGU_Change_to_approve__c rguToChange : lRGUsToChange) {
			idsRGUs.add(rguToChange.Referencia_Elara_Original__c);
		}

		Map<Id, List<OpportunityLineItem>> olisPerRGUs = new Map<Id, List<OpportunityLineItem>>();

		List<OpportunityLineItem> oppLineItems = [
			SELECT Id, Referencia_Elara__r.id, Partida_Ventas_MXN__c
			FROM OpportunityLineItem
			WHERE Referencia_Elara__r.id IN :idsRGUs
		];

		for (OpportunityLineItem oppLineItem : oppLineItems) {
			List<OpportunityLineItem> lOppLineItem;

			if (
				(lOppLineItem = olisPerRGUs.get(
					oppLineItem.Referencia_Elara__r.id
				)) == null
			) {
				lOppLineItem = new List<OpportunityLineItem>();
				olisPerRGUs.put(
					oppLineItem.Referencia_Elara__r.id,
					lOppLineItem
				);
			}
			lOppLineItem.add(oppLineItem);
		}

		for (RGU_Change_to_approve__c rguToChange : lRGUsToChange) {
			List<OpportunityLineItem> actualOlis = olisPerRGUs.get(
				rguToChange.Referencia_Elara_Original__c
			);
			Decimal vtcRGU = 0;
			for (OpportunityLineItem oli : actualOlis) {
				vtcRGU += oli.Partida_Ventas_MXN__c;
			}

			rguToChange.VTC_Referencia_Original__c = vtcRGU;
		}
	}
}
