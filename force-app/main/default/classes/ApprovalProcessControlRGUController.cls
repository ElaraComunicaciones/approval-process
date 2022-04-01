public with sharing class ApprovalProcessControlRGUController {
	@AuraEnabled(cacheable=true)
	public static List<RGU__c> getRelatedReferences(Id recordId) {
		try {
			ApprovalProcess__c approvalProcess = [
				SELECT id, Opportunity__c
				FROM ApprovalProcess__c
				WHERE id = :recordId
			];

			List<RGU__c> lRGUs = [
				SELECT
					Id,
					Name,
					Referencia__c,
					Nombre_de_sitio__c,
					Status_COS__c,
					Numero_Sitio__c
				FROM RGU__c
				WHERE
					NumeroDeExpedienteDeProyecto__c = :approvalProcess.Opportunity__c
			];

			return lRGUs;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void saveRGUChangeToApprove(
		Id recordId,
		List<RGU__c> referenciasSeleccionadas
	) {
		try {
			System.debug(referenciasSeleccionadas);
			//Eliminamos los

			List<RGU_Change_to_approve__c> RGUsToApprove = [
				SELECT id
				FROM RGU_Change_to_approve__c
				WHERE Approval_Process__c = :recordId
			];

			delete RGUsToApprove;

			if (referenciasSeleccionadas.size() > 0) {
				//Obtenemos todos los campos de Referencia Elara
				SObjectType accountType = Schema.getGlobalDescribe()
					.get('RGU__C');
				Map<String, Schema.SObjectField> mfields = accountType.getDescribe()
					.fields.getMap();

				String selectSentence = '';

				for (String fieldName : mfields.keySet()) {
					selectSentence += fieldName + ',';
				}

				String whereSentence = '';

				for (RGU__c references : referenciasSeleccionadas) {
					whereSentence += '\'' + references.id + '\',';
				}

				//Hacemos select all de rgu, de los que se seleccionó para dar de baja el servicio
				List<RGU__c> lRGUs = Database.query(
					'select ' +
					selectSentence.Substring(0, selectSentence.length() - 1) +
					' from RGU__c where id in (' +
					whereSentence.Substring(0, whereSentence.length() - 1) +
					')'
				);

				//Generamos los objetos clones de las referencias de los que van a entrar en proceso de aprobación
				List<RGU_Change_to_approve__c> lRGUToApprove = new List<RGU_Change_to_approve__c>();

				for (RGU__c referenciaOriginal : lRGUs) {
					RGU_Change_to_approve__c RGUToApprove = new RGU_Change_to_approve__c(
						Referencia_Elara_Personalizada__c = referenciaOriginal.Referencia_Elara_Personalizada__c,
						Nombre_de_sitio__c = referenciaOriginal.Nombre_de_sitio__c,
						Nmero_de_sitio_del_cliente__c = referenciaOriginal.N_mero_de_sitio_del_cliente__c,
						Numero_Sitio__c = referenciaOriginal.Numero_Sitio__c,
						Lugar__c = referenciaOriginal.Lugar__c,
						Direccin_del_sitio__c = referenciaOriginal.Direcci_n_del_sitio__c,
						Soporte_para_pago_del_servicio__c = referenciaOriginal.Soporte_para_pago_del_servicio__c,
						Status_Reconocido_Cliente__c = referenciaOriginal.Status_Reconocido_Cliente__c,
						Id_Compra__c = referenciaOriginal.Id_Compra__c,
						Fecha_Solicitud_de_Cancelacion_Cliente__c = referenciaOriginal.Fecha_Solicitud_de_Cancelacion_Cliente__c,
						Tipo_de_Ingreso__c = referenciaOriginal.Tipo_de_Ingreso__c,
						Categoria_Unidad_de_Negocio__c = referenciaOriginal.Categoria_Unidad_Negocio__c,
						Conceptos_por_categor_a__c = referenciaOriginal.Concepto_Categoria__c,
						Servicio__c = referenciaOriginal.Servicio__c,
						Tipo_de_Enlace__c = referenciaOriginal.Tipo_de_Enlace__c,
						Esquema__c = referenciaOriginal.Esquema__c,
						Banda__c = referenciaOriginal.Banda__c,
						BWBajadaKbps__c = referenciaOriginal.BWBajadaKbps__c,
						BWSubidaKbps__c = referenciaOriginal.BWSubidaKbps__c,
						SS_DW__c = referenciaOriginal.SS_DW__c,
						SS_UP__c = referenciaOriginal.SS_UP__c,
						Paquete_KA__c = referenciaOriginal.Paquete_KA__c,
						Numero_de_lineas__c = referenciaOriginal.Numero_de_lineas__c,
						Cap_Fap_GB__c = referenciaOriginal.Cap_Fap_GB__c,
						Orden_de_Aprovisionamiento_IOM_TMX__c = referenciaOriginal.Orden_de_Aprovisionamiento_IOM_TMX__c,
						Folio_IOM__c = referenciaOriginal.Folio_IOM__c,
						Fecha_de_emisin_IOM__c = referenciaOriginal.Fecha_de_emisi_n_IOM__c,
						Tipo_de_servicio_IOM__c = referenciaOriginal.Tipo_de_servicio_IOM__c,
						Nmero_de_parte_Contratacin_IOM__c = referenciaOriginal.N_mero_de_parte_Contrataci_n_IOM__c,
						Id_del_componente_Contratacin_IOM__c = referenciaOriginal.Id_del_componente_Contrataci_n_IOM__c,
						Nmero_de_parte_Renta_IOM__c = referenciaOriginal.N_mero_de_parte_Renta_IOM__c,
						Id_del_componente_Renta_IOM__c = referenciaOriginal.Id_del_componente_Renta_IOM__c,
						EQUIPO_FINAL__c = referenciaOriginal.EQUIPO_FINAL__c,
						FECHA_DE_BAJA_TMX_RURAL__c = referenciaOriginal.FECHA_DE_BAJA_TMX_RURAL__c,
						FASE_TMX_RURAL__c = referenciaOriginal.FASE_TMX_RURAL__c,
						FECHA_VALIDACION_IVR_TMX__c = referenciaOriginal.FECHA_VALIDACION_IVR_TMX__c,
						NUEVA_DIVISION_TMX_RURAL__c = referenciaOriginal.NUEVA_DIVISION_TMX_RURAL__c,
						ESTATUS_SITIO_TMX_RURAL__c = referenciaOriginal.ESTATUS_SITIO_TMX_RURAL__c,
						DIVISION_TMX_RURAL__c = referenciaOriginal.DIVISION_TMX_RURAL__c,
						NUMERO_DE_LINEAS_MIGRADAS_ACTIVAS__c = referenciaOriginal.NUMERO_DE_LINEAS_MIGRADAS_ACTIVAS__c,
						ESTATUS_FACTURACION__c = referenciaOriginal.ESTATUS_FACTURACION__c,
						LINEAS_MIGRADAS_ACTIVAS__c = referenciaOriginal.LINEAS_MIGRADAS_ACTIVAS__c,
						OBSERVACIONES_TMX_RURAL__c = referenciaOriginal.OBSERVACIONES_TMX_RURAL__c,
						Approval_Process__c = recordId,
						Referencia_Elara_Original__c = referenciaOriginal.Id
					);
					lRGUToApprove.add(RGUToApprove);
				}

				insert lRGUToApprove;
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static List<Id> getRGUToApprove(Id recordId) {
		List<Id> lSelectedRows = new List<Id>();

		for (RGU_Change_to_approve__c rguToApprove : [
			SELECT Referencia_Elara_Original__c
			FROM RGU_Change_to_approve__c
			WHERE Approval_Process__c = :recordId
		]) {
			lSelectedRows.add(rguToApprove.Referencia_Elara_Original__c);
		}
		return lSelectedRows;
	}
}