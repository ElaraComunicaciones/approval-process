public with sharing class OrganicGrowthUtils {
	public OrganicGrowthUtils() {
	}

	//Generamos los tipos de sitio a partir de tipos de sitio clon
	public static Map<id, TipoDeSitio__c> generateTipoSitio(
		List<TipoDeSitioPorAprobar__c> lTiposSitiosPorAprobar
	) {
		List<TipoDeSitio__c> lTiposDeSitios = new List<TipoDeSitio__c>();

		Map<id, TipoDeSitio__c> mapTiposDeSitio = new Map<id, TipoDeSitio__c>();

		for (
			TipoDeSitioPorAprobar__c tiposSitioPorAprobar : lTiposSitiosPorAprobar
		) {
			TipoDeSitio__c tipoSitio = new TipoDeSitio__c();
			tipoSitio.Lugar__c = tiposSitioPorAprobar.Lugar__c;
			tipoSitio.Nombre_Completo__c = tiposSitioPorAprobar.Nombre_Completo__c;
			tipoSitio.ID_Orden_de_compra_cliente__c = tiposSitioPorAprobar.ID_Orden_de_compra_cliente__c;
			tipoSitio.NumeroDeSitios__c = tiposSitioPorAprobar.NumeroDeSitios__c;
			tipoSitio.Esquema_comercial__c = tiposSitioPorAprobar.Esquema_comercial__c;
			tipoSitio.Fase__c = tiposSitioPorAprobar.Fase__c;
			tipoSitio.Tipo_de_Configuracion__c = tiposSitioPorAprobar.Tipo_de_Configuracion__c;
			tipoSitio.NumeroDeExpedienteDeProyecto__c = tiposSitioPorAprobar.Proceso_de_aprobacion__r.Opportunity__c;
			tipoSitio.Tipo_Solicitud__c = tiposSitioPorAprobar.Tipo_de_solicitud__c;
			tipoSitio.Categoria_Unidad_Negocio__c = tiposSitioPorAprobar.Categoria_Unidad_Negocio__c;
			tipoSitio.Concepto_Categoria__c = tiposSitioPorAprobar.Concepto_Categoria__c;
			tipoSitio.Servicio__c = tiposSitioPorAprobar.Servicio__c;
			tipoSitio.Tipo_de_Enlace__c = tiposSitioPorAprobar.Tipo_de_Enlace__c;
			tipoSitio.Esquema__c = tiposSitioPorAprobar.Esquema__c;
			tipoSitio.Banda__c = tiposSitioPorAprobar.Banda__c;
			tipoSitio.BWBajadaKbps__c = tiposSitioPorAprobar.BWBajadaKbps__c;
			tipoSitio.BWSubidaKbps__c = tiposSitioPorAprobar.BWSubidaKbps__c;
			tipoSitio.SS_DW__c = tiposSitioPorAprobar.SS_DW__c;
			tipoSitio.SS_UP__c = tiposSitioPorAprobar.SS_UP__c;
			tipoSitio.Paquete_KA__c = tiposSitioPorAprobar.Paquete_KA__c;
			tipoSitio.Numero_de_lineas__c = tiposSitioPorAprobar.Numero_de_lineas__c;
			tipoSitio.Cap_Fap_GB__c = tiposSitioPorAprobar.Cap_Fap_GB__c;
			tipoSitio.Propietario_antena__c = tiposSitioPorAprobar.Propietario_antena__c;
			tipoSitio.Propietario_BUC__c = tiposSitioPorAprobar.Propietario_BUC__c;
			tipoSitio.Propietario_costo_Segmento_Espacial__c = tiposSitioPorAprobar.Propietario_costo_Segmento_Espacial__c;
			tipoSitio.Propietario_equipo_adicional__c = tiposSitioPorAprobar.Propietario_equipo_adicional__c;
			tipoSitio.Propietario_LNB__c = tiposSitioPorAprobar.Propietario_LNB__c;
			tipoSitio.Propietario_modem__c = tiposSitioPorAprobar.Propietario_modem__c;
			tipoSitio.Propietario_transeiver__c = tiposSitioPorAprobar.Propietario_transceiver__c;

			mapTiposDeSitio.put(tiposSitioPorAprobar.id, tipoSitio);
		}

		return mapTiposDeSitio;
	}

	//Generamos las referencias elara a partir de referencias elara clon
	public static Map<Id, RGU__C> generateRGUs(
		Map<id, TipoDeSitio__c> mapTiposSitio,
		List<RGU_Change_to_approve__c> lRGUsToApprove
	) {
		Map<id, RGU__C> mapRGUS = new Map<id, RGU__C>();

		for (RGU_Change_to_approve__c rguToApprove : lRGUsToApprove) {
			RGU__c rgu = new RGU__c();

			ID tipoDeSitioId = mapTiposSitio.get(
					rguToApprove.Tipo_de_sitio_por_aprobar__c
				)
				.id;
			ID numeroEP = mapTiposSitio.get(
					rguToApprove.Tipo_de_sitio_por_aprobar__c
				)
				.NumeroDeExpedienteDeProyecto__c;

			rgu.Referencia_Elara_Personalizada__c = rguToApprove.Referencia_Elara_Personalizada__c;
			rgu.Nombre_de_sitio__c = rguToApprove.Nombre_de_sitio__c;
			rgu.Tipo_de_sitio__c = tipoDeSitioId;
			rgu.NumeroDeExpedienteDeProyecto__c = numeroEP;
			rgu.N_mero_de_sitio_del_cliente__c = rguToApprove.Nmero_de_sitio_del_cliente__c;
			rgu.Lugar__c = rguToApprove.Lugar__c;
			rgu.Referencia_Elara_Anterior__c = rguToApprove.Referencia_Elara_Anterior__c;
			rgu.Direcci_n_del_sitio__c = rguToApprove.Direccin_del_sitio__c;
			rgu.Soporte_para_pago_del_servicio__c = rguToApprove.Soporte_para_pago_del_servicio__c;
			rgu.Status_Reconocido_Cliente__c = rguToApprove.Status_Reconocido_Cliente__c;
			rgu.Id_Compra__c = rguToApprove.Id_Compra__c;
			rgu.Fecha_Solicitud_de_Cambio_Cliente__c = rguToApprove.Fecha_Solicitud_de_Cambio_Cliente__c;
			rgu.Categoria_Unidad_Negocio__c = rguToApprove.Categoria_Unidad_de_Negocio__c;
			rgu.Concepto_Categoria__c = rguToApprove.Conceptos_por_categor_a__c;
			rgu.Servicio__c = rguToApprove.Servicio__c;
			rgu.Tipo_de_Enlace__c = rguToApprove.Tipo_de_Enlace__c;
			rgu.Esquema__c = rguToApprove.Esquema__c;
			rgu.Banda__c = rguToApprove.Banda__c;
			rgu.BWBajadaKbps__c = rguToApprove.BWBajadaKbps__c;
			rgu.BWSubidaKbps__c = rguToApprove.BWSubidaKbps__c;
			rgu.SS_UP__c = rguToApprove.SS_UP__c;
			rgu.SS_DW__c = rguToApprove.SS_DW__c;
			rgu.Paquete_KA__c = rguToApprove.Paquete_KA__c;
			rgu.Numero_de_lineas__c = rguToApprove.Numero_de_lineas__c;
			rgu.Cap_Fap_GB__c = rguToApprove.Cap_Fap_GB__c;
			rgu.Folio_IOM__c = rguToApprove.Folio_IOM__c;
			rgu.Tipo_de_movimiento_IOM__c = rguToApprove.Tipo_de_movimiento_IOM__c;
			rgu.Fecha_de_emisi_n_IOM__c = rguToApprove.Fecha_de_emisin_IOM__c;
			rgu.QO_IOM__c = rguToApprove.QO_IOM__c;
			rgu.CO_IOM__c = rguToApprove.CO_IOM__c;
			rgu.Orden_de_Aprovisionamiento_IOM_TMX__c = rguToApprove.Orden_de_Aprovisionamiento_IOM_TMX__c;
			rgu.Tipo_de_servicio_IOM__c = rguToApprove.Tipo_de_servicio_IOM__c;
			rgu.N_mero_de_parte_Contrataci_n_IOM__c = rguToApprove.Nmero_de_parte_Contratacin_IOM__c;
			rgu.Id_del_componente_Contrataci_n_IOM__c = rguToApprove.Id_del_componente_Contratacin_IOM__c;
			rgu.N_mero_de_parte_Renta_IOM__c = rguToApprove.Nmero_de_parte_Renta_IOM__c;
			rgu.EQUIPO_FINAL__c = rguToApprove.EQUIPO_FINAL__c;
			rgu.FECHA_DE_BAJA_TMX_RURAL__c = rguToApprove.FECHA_DE_BAJA_TMX_RURAL__c;
			rgu.FASE_TMX_RURAL__c = rguToApprove.FASE_TMX_RURAL__c;
			rgu.FECHA_VALIDACION_IVR_TMX__c = rguToApprove.FECHA_VALIDACION_IVR_TMX__c;
			rgu.NUEVA_DIVISION_TMX_RURAL__c = rguToApprove.NUEVA_DIVISION_TMX_RURAL__c;
			rgu.ESTATUS_SITIO_TMX_RURAL__c = rguToApprove.ESTATUS_SITIO_TMX_RURAL__c;
			rgu.DIVISION_TMX_RURAL__c = rguToApprove.DIVISION_TMX_RURAL__c;
			rgu.NUMERO_DE_LINEAS_MIGRADAS_ACTIVAS__c = rguToApprove.NUMERO_DE_LINEAS_MIGRADAS_ACTIVAS__c;
			rgu.ESTATUS_FACTURACION__c = rguToApprove.ESTATUS_FACTURACION__c;
			rgu.LINEAS_MIGRADAS_ACTIVAS__c = rguToApprove.LINEAS_MIGRADAS_ACTIVAS__c;
			rgu.OBSERVACIONES_TMX_RURAL__c = rguToApprove.OBSERVACIONES_TMX_RURAL__c;

			mapRGUS.put(rguToApprove.id, rgu);
		}

		return mapRGUS;
	}

	public static Map<Id, OpportunityLineItem> generateOLI(
		Map<Id, RGU__C> mapRGUS,
		List<OpportunityItemConsent__c> lOpportunityItemConset
	) {
		Map<id, OpportunityLineItem> mapOLIs = new Map<id, OpportunityLineItem>();

		for (
			OpportunityItemConsent__c opporunityItemConset : lOpportunityItemConset
		) {
			OpportunityLineItem opportunityLineItem = new OpportunityLineItem();

			ID idRGU = mapRGUS.get(
					opporunityItemConset.Referencia_Elara_por_aprobar__c
				)
				.id;
			ID numeroEP = mapRGUS.get(
					opporunityItemConset.Referencia_Elara_por_aprobar__c
				)
				.NumeroDeExpedienteDeProyecto__c;

			opportunityLineItem.PricebookEntryId = opporunityItemConset.PricebookEntryId__c;
			opportunityLineItem.Quantity = opporunityItemConset.Quantity__c;
			opportunityLineItem.Divisa_de_Cotizacion__c = opporunityItemConset.Divisa_de_Cotizacion__c;
			opportunityLineItem.Forma_de_Cobro__c = opporunityItemConset.Forma_de_cobro__c;
			opportunityLineItem.TipoDeCambioCotizado__c = opporunityItemConset.TipoDeCambioCotizado__c;
			opportunityLineItem.Description = (opporunityItemConset.Description__c !=
				null)
				? opporunityItemConset.Description__c.abbreviate(255)
				: null;
			opportunityLineItem.UnitPrice = opporunityItemConset.UnitPrice__c;
			opportunityLineItem.UnitPrice__c = opporunityItemConset.UnitPrice__c;
			opportunityLineItem.Plazo__c = opporunityItemConset.Plazo__c;
			opportunityLineItem.Fecha_Inicio_Ingreso__c = opporunityItemConset.Fecha_Inicio_de_Ingreso__c;
			opportunityLineItem.Fecha_Fin_Ingreso__c = opporunityItemConset.Fecha_Fin_Ingreso__c;
			opportunityLineItem.Referencia_Elara__c = idRGU;
			opportunityLineItem.Tipo_Ingreso__c = opporunityItemConset.Tipo_de_ingreso__c;
			opportunityLineItem.OpportunityId = numeroEP;

			mapOLIs.put(opporunityItemConset.id, opportunityLineItem);
		}
		return mapOLIs;
	}

	public static List<TipoDeSitioPorAprobar__c> getTiposSitioPerApprovalProcess(
		List<ApprovalProcess__c> lApprovalProcess
	) {
		//Obtenemos todos los campos de tipo de sitio por aprobar
		SObjectType accountType = Schema.getGlobalDescribe()
			.get('TipoDeSitioPorAprobar__c');
		Map<String, Schema.SObjectField> mfields = accountType.getDescribe()
			.fields.getMap();

		String selectSentence = '';

		for (String fieldName : mfields.keySet()) {
			selectSentence += fieldName + ',';
		}

		selectSentence += 'Proceso_de_aprobacion__r.Opportunity__c,';

		String whereSentence = '';

		for (ApprovalProcess__c approvalProcess : lApprovalProcess) {
			whereSentence += '\'' + approvalProcess.id + '\',';
		}

		//Hacemos select all de rgu, de los que se seleccionó para dar de baja el servicio
		List<TipoDeSitioPorAprobar__c> lTiposSitioPorApprobar = Database.query(
			'select ' +
			selectSentence.Substring(0, selectSentence.length() - 1) +
			' from TipoDeSitioPorAprobar__c where Proceso_de_aprobacion__c in (' +
			whereSentence.Substring(0, whereSentence.length() - 1) +
			')'
		);

		return lTiposSitioPorApprobar;
	}

	public static List<RGU_Change_to_approve__c> getRGUsPerTipoSitioPorAprobar(
		List<TipoDeSitioPorAprobar__c> lTipoSitios
	) {
		//Obtenemos todos los campos de Referencia Elara
		SObjectType accountType = Schema.getGlobalDescribe()
			.get('RGU_Change_to_approve__c');
		Map<String, Schema.SObjectField> mfields = accountType.getDescribe()
			.fields.getMap();

		String selectSentence = '';

		for (String fieldName : mfields.keySet()) {
			selectSentence += fieldName + ',';
		}

		String whereSentence = '';

		for (TipoDeSitioPorAprobar__c tipoSitio : lTipoSitios) {
			whereSentence += '\'' + tipoSitio.id + '\',';
		}

		//Hacemos select all de rgu, de los que se seleccionó para dar de baja el servicio
		List<RGU_Change_to_approve__c> lRGUs = Database.query(
			'select ' +
			selectSentence.Substring(0, selectSentence.length() - 1) +
			' from RGU_Change_to_approve__c where Tipo_de_sitio_por_aprobar__c in (' +
			whereSentence.Substring(0, whereSentence.length() - 1) +
			')'
		);

		return lRGUs;
	}

	public static List<OpportunityItemConsent__c> getOlisPerRGUs(
		List<RGU_Change_to_approve__c> lRGUs
	) {
		//Obtenemos todos los campos de Referencia Elara
		SObjectType accountType = Schema.getGlobalDescribe()
			.get('OpportunityItemConsent__c');
		Map<String, Schema.SObjectField> mfields = accountType.getDescribe()
			.fields.getMap();

		String selectSentence = '';

		for (String fieldName : mfields.keySet()) {
			selectSentence += fieldName + ',';
		}

		selectSentence += 'Proceso_de_aprobacion__r.Fecha_Inicio_Pactada__c,Proceso_de_aprobacion__r.Fecha_final_pactada__c,';

		String whereSentence = '';

		for (RGU_Change_to_approve__c rgu : lRGUs) {
			whereSentence += '\'' + rgu.id + '\',';
		}

		//Hacemos select all de rgu, de los que se seleccionó para dar de baja el servicio
		List<OpportunityItemConsent__c> lOlis = Database.query(
			'select ' +
			selectSentence.Substring(0, selectSentence.length() - 1) +
			' from OpportunityItemConsent__c where Referencia_Elara_por_aprobar__c in (' +
			whereSentence.Substring(0, whereSentence.length() - 1) +
			')'
		);

		return lOlis;
	}
}