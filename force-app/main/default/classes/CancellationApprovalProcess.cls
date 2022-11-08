public with sharing class CancellationApprovalProcess {
	public static void executeBeforeUpdateProcess(
		Map<id, SObject> oldMap,
		List<ApprovalProcess__c> newList
	) {
		List<ApprovalProcess__c> approvalProcessToCalculateDecrement = new List<ApprovalProcess__c>();

		for (ApprovalProcess__c approvalProcess : newList) {
			ApprovalProcess__c oldValue = (ApprovalProcess__c) oldMap.get(
				approvalProcess.id
			);

			//Si el proceso de aprobación cambia a solicitado o aprobado, entonces calculamos el decremento que
			//tendran las bajas en el VTC del EP
			if (
				(oldValue.Stage__c != 'Solicitado' &&
				approvalProcess.Stage__c == 'Solicitado') ||
				(oldValue.Stage__c != 'Aprobado' &&
				approvalProcess.Stage__c == 'Aprobado')
			)
				approvalProcessToCalculateDecrement.add(approvalProcess);
		}
		CalculateDecrementByCancelation(approvalProcessToCalculateDecrement);
	}

	private static void CalculateDecrementByCancelation(
		List<ApprovalProcess__c> approvalProcessToCalculateDecrement
	) {
		//Obtenemos los clones de RGU de los procesos de aprobación
		List<RGU_Change_to_approve__c> lRGUsToChange = [
			SELECT id, Approval_Process__c, Referencia_Elara_Original__c
			FROM RGU_Change_to_approve__c
			WHERE Approval_Process__c IN :approvalProcessToCalculateDecrement
		];

		Map<id, ApprovalProcess__c> mapApprovalProcess = new Map<id, ApprovalProcess__c>(
			approvalProcessToCalculateDecrement
		);

		//Se genera mapa de Procesos de aprobacion con sus RGUs Clones
		Map<id, List<RGU_Change_to_approve__c>> rgusPerApprovalProcess = new Map<id, List<RGU_Change_to_approve__c>>();
		Set<Id> idsRGUSWithoutSinglePayment = new Set<Id>();

		for (RGU_Change_to_approve__c rgu : lRGUsToChange) {
			List<RGU_Change_to_approve__c> lrgus;

			if (
				(lrgus = rgusPerApprovalProcess.get(rgu.Approval_Process__c)) ==
				null
			) {
				lrgus = new List<RGU_Change_to_approve__c>();
				rgusPerApprovalProcess.put(rgu.Approval_Process__c, lrgus);
			}
			lrgus.add(rgu);

			/*Generamos un Set de ids de referencias cuyo proceso de aprobación no considera cobros únicos
			 mas adelante lo usaremos para no considerar los productos cuyo forma de cobro sea diferente Pago Único*/
			if (
				mapApprovalProcess.get(rgu.Approval_Process__c)
					.Considerar_cobros_unicos__c == 'No'
			) {
				idsRGUSWithoutSinglePayment.add(
					rgu.Referencia_Elara_Original__c
				);
			}
		}

		Set<Id> idsRGUs = new Set<Id>();

		//Obtenemos los OLIS de
		for (RGU_Change_to_approve__c rguToChange : lRGUsToChange) {
			idsRGUs.add(rguToChange.Referencia_Elara_Original__c);
		}

		Map<Id, List<OpportunityLineItem>> olisPerRGUs = new Map<Id, List<OpportunityLineItem>>();

		//Obtenemos los productos de oportunidad por referencias elara original
		List<OpportunityLineItem> oppLineItems = [
			SELECT
				Id,
				Referencia_Elara__r.id,
				Fecha_Fin_Ingreso__c,
				Total_Renta_Conv_MXN__c,
				Partida_de_Ventas_Conv_MXN__c,
				Forma_de_Cobro__c
			FROM OpportunityLineItem
			WHERE
				Forma_de_Cobro__c != 'Diaria'
				AND Referencia_Elara__r.id IN :idsRGUs
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

			if (
				(idsRGUSWithoutSinglePayment.contains(
					oppLineItem.Referencia_Elara__r.id
				) && oppLineItem.Forma_de_Cobro__c != 'Pago Único') ||
				!idsRGUSWithoutSinglePayment.contains(
					oppLineItem.Referencia_Elara__r.id
				)
			) {
				lOppLineItem.add(oppLineItem);
			}
		}

		System.debug(olisPerRGUs);

		//Generamos los decrementos de VTC de las referencias ELARA
		Map<id, Decimal> lDecrementPerRGU = new Map<Id, Decimal>();

		for (RGU_Change_to_approve__c rguToChange : lRGUsToChange) {
			List<OpportunityLineItem> actualOlis = olisPerRGUs.get(
				rguToChange.Referencia_Elara_Original__c
			);
			Decimal decrementoVTC = 0;
			for (OpportunityLineItem oli : actualOlis) {
				decrementoVTC += oli.Partida_de_Ventas_Conv_MXN__c;
			}
			lDecrementPerRGU.put(rguToChange.id, decrementoVTC);
		}

		System.debug(lDecrementPerRGU);
		System.debug(rgusPerApprovalProcess);

		Map<id, Decimal> decrementsPerApprovalProcess = new Map<Id, Decimal>();

		for (Id key : rgusPerApprovalProcess.keySet()) {
			List<RGU_Change_to_approve__c> lRGUS = rgusPerApprovalProcess.get(
				key
			);
			Decimal decrementVTC = 0;
			for (RGU_Change_to_approve__c rgu : lRGUS) {
				decrementVTC += lDecrementPerRGU.get(rgu.id);
			}

			decrementsPerApprovalProcess.put(key, decrementVTC);
		}

		System.debug(decrementsPerApprovalProcess);

		for (
			ApprovalProcess__c approvalProcess : approvalProcessToCalculateDecrement
		) {
			approvalProcess.Decremento_en_VTC__c = decrementsPerApprovalProcess.get(
				approvalProcess.id
			);
		}
	}

	private static Set<Id> getOlisToUpdateSalePrice(
		List<ApprovalProcess__c> approvalProcessToCalculateDecrement
	) {
		Map<id, ApprovalProcess__c> mapApprovalProcess = new Map<id, ApprovalProcess__c>(
			approvalProcessToCalculateDecrement
		);

		//Obtenemos los clones de RGU de los procesos de aprobación
		List<RGU_Change_to_approve__c> lRGUsToChange = [
			SELECT id, Approval_Process__c, Referencia_Elara_Original__c
			FROM RGU_Change_to_approve__c
			WHERE Approval_Process__c IN :approvalProcessToCalculateDecrement
		];

		//Se genera mapa de Procesos de aprobacion con sus RGUs Clones
		Map<id, List<RGU_Change_to_approve__c>> rgusPerApprovalProcess = new Map<id, List<RGU_Change_to_approve__c>>();
		Set<Id> idsRGUSWithoutSinglePayment = new Set<Id>();

		for (RGU_Change_to_approve__c rgu : lRGUsToChange) {
			List<RGU_Change_to_approve__c> lrgus;

			if (
				(lrgus = rgusPerApprovalProcess.get(rgu.Approval_Process__c)) ==
				null
			) {
				lrgus = new List<RGU_Change_to_approve__c>();
				rgusPerApprovalProcess.put(rgu.Approval_Process__c, lrgus);
			}
			lrgus.add(rgu);

			/*Generamos un Set de ids de referencias cuyo proceso de aprobación no considera cobros únicos
			 mas adelante lo usaremos para no considerar los productos cuyo forma de cobro sea diferente Pago Único*/
			if (
				mapApprovalProcess.get(rgu.Approval_Process__c)
					.Considerar_cobros_unicos__c == 'No'
			) {
				idsRGUSWithoutSinglePayment.add(
					rgu.Referencia_Elara_Original__c
				);
			}
		}

		Set<Id> idsRGUs = new Set<Id>();

		//Obtenemos los OLIS de
		for (RGU_Change_to_approve__c rguToChange : lRGUsToChange) {
			idsRGUs.add(rguToChange.Referencia_Elara_Original__c);
		}

		//Obtenemos los productos de oportunidad por referencias elara original
		List<OpportunityLineItem> oppLineItems = [
			SELECT
				Id,
				Referencia_Elara__r.id,
				Fecha_Fin_Ingreso__c,
				Total_Renta_Conv_MXN__c,
				Forma_de_Cobro__c
			FROM OpportunityLineItem
			WHERE
				Forma_de_Cobro__c != 'Diaria'
				AND Referencia_Elara__r.id IN :idsRGUs
		];

		Set<Id> setOppLoneItem = new Set<Id>();

		for (OpportunityLineItem oppLineItem : oppLineItems) {
			if (
				(idsRGUSWithoutSinglePayment.contains(
					oppLineItem.Referencia_Elara__r.id
				) && oppLineItem.Forma_de_Cobro__c != 'Pago Único') ||
				!idsRGUSWithoutSinglePayment.contains(
					oppLineItem.Referencia_Elara__r.id
				)
			) {
				setOppLoneItem.add(oppLineItem.id);
			}
		}
		return setOppLoneItem;
	}
}