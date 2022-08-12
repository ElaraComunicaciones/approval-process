public with sharing class OrganicGrowthApprovalProcess {
	public static void executeBeforeUpdateProcess(
		Map<id, SObject> oldMap,
		List<ApprovalProcess__c> newList
	) {
		List<ApprovalProcess__c> newApprovedRecords = filterNewApprovedRecords(
			oldMap,
			newList
		);

		validateConditions(newApprovedRecords);
	}

	public static void executeAfterUpdate(
		List<ApprovalProcessMail__mdt> approvalProcessMail,
		List<EmailTemplate> emailTemplates,
		Map<Id, SObject> oldMap,
		List<ApprovalProcess__c> lApprovalProcess,
		Map<Id, Opportunity> opportunities,
		Map<Id, Account> accounts,
		List<User> users
	) {
		List<ApprovalProcess__c> newRequestedRecords = filterNewRequestedRecords(
			oldMap,
			lApprovalProcess
		);

		List<ApprovalProcess__c> sendNotificationProgress = filterRecordsToSendDocumentationProgress(
			oldMap,
			lApprovalProcess
		);

		List<ApprovalProcess__c> newApprovedRecords = filterNewApprovedRecords(
			oldMap,
			lApprovalProcess
		);

		List<ApprovalProcess__c> newRejectRecords = filterRejectedRecords(
			oldMap,
			lApprovalProcess
		);

		sendRejectNotifications(
			newRejectRecords,
			emailTemplates,
			approvalProcessMail,
			users
		);

		sendApprovalRequestNotifications(
			newRequestedRecords,
			emailTemplates,
			users
		);

		sendApprovalProgressNotifications(
			sendNotificationProgress,
			emailTemplates,
			users
		);

		sendApprovedNotifications(
			newApprovedRecords,
			emailTemplates,
			approvalProcessMail,
			users
		);
	}

	@testVisible
	private static List<ApprovalProcess__c> filterNewRequestedRecords(
		Map<Id, SObject> oldMap,
		List<ApprovalProcess__c> lApprovalProcessOfDeactivate
	) {
		List<ApprovalProcess__c> newRequestedRecords = new List<ApprovalProcess__c>();

		System.debug(oldMap);

		for (ApprovalProcess__c newApproval : lApprovalProcessOfDeactivate) {
			ApprovalProcess__c oldApproval = (ApprovalProcess__c) oldMap.get(
				newApproval.Id
			);

			System.debug(oldApproval.Stage__c);

			if (oldApproval != null) {
				if (
					oldApproval.Stage__c == 'Iniciado' &&
					newApproval.Stage__c == 'Solicitado'
				) {
					newRequestedRecords.add(newApproval);
				}
			}
		}

		return newRequestedRecords;
	}

	@testVisible
	private static List<ApprovalProcess__c> filterRecordsToSendDocumentationProgress(
		Map<Id, SObject> oldMap,
		List<ApprovalProcess__c> newRecords
	) {
		List<ApprovalProcess__c> newRequestedRecords = new List<ApprovalProcess__c>();

		System.debug(oldMap);

		for (ApprovalProcess__c newApproval : newRecords) {
			ApprovalProcess__c oldApproval = (ApprovalProcess__c) oldMap.get(
				newApproval.Id
			);

			System.debug(oldApproval.Stage__c);

			if (oldApproval != null) {
				if (
					oldApproval.Stage__c == 'Solicitado' &&
					newApproval.Stage__c == 'Solicitado' &&
					newApproval.Aprobacion_por_comite_directivo__c
				) {
					newRequestedRecords.add(newApproval);
				}
			}
		}

		return newRequestedRecords;
	}

	@testVisible
	private static List<ApprovalProcess__c> filterRejectedRecords(
		Map<Id, SObject> oldMap,
		List<ApprovalProcess__c> newRecords
	) {
		List<ApprovalProcess__c> newRejectedRecords = new List<ApprovalProcess__c>();

		for (ApprovalProcess__c newApproval : newRecords) {
			ApprovalProcess__c oldApproval = (ApprovalProcess__c) oldMap.get(
				newApproval.Id
			);

			System.debug(oldApproval.Stage__c);

			if (oldApproval != null) {
				if (
					oldApproval.Stage__c == 'Solicitado' &&
					newApproval.Stage__c == 'Rechazado'
				) {
					newRejectedRecords.add(newApproval);
				}
			}
		}

		return newRejectedRecords;
	}

	@testVisible
	private static void sendRejectNotifications(
		List<ApprovalProcess__c> newRejectedRecords,
		List<EmailTemplate> emailTemplates,
		List<ApprovalProcessMail__mdt> approvalProcessMail,
		List<User> users
	) {
		EmailTemplate denegadoComiteDirectivoBajas;
		EmailTemplate denegadoControlComercialBajas;

		List<String> sendTo;
		List<String> sendCC = ApprovalProcessAPI.getProcessMail(users);
		List<String> sendCCO;

		for (EmailTemplate template : emailTemplates) {
			switch on template.name {
				when 'RS_B2 Aprobación baja denegada por Comité Directivo' {
					denegadoComiteDirectivoBajas = template;
				}
				when 'RS_B3 Aprobación baja denegada por Control Comercial' {
					denegadoControlComercialBajas = template;
				}
			}
		}

		for (ApprovalProcess__c approvalProcess : newRejectedRecords) {
			if (approvalProcess.Aprobacion_por_comite_directivo__c) {
				sendTo = new List<String>();
				sendCCO = new List<String>();
				for (User userMail : users) {
					if (userMail.id == approvalProcess.OwnerId) {
						sendTo.add(userMail.email);
						break;
					}
				}

				ApprovalProcessAPI.SendEmailNotifications(
					denegadoComiteDirectivoBajas,
					sendTo,
					sendCC,
					sendCCO,
					approvalProcess
				);
			} else {
				sendTo = new List<String>();
				sendCCO = new List<String>();
				for (User userMail : users) {
					if (userMail.id == approvalProcess.OwnerId) {
						sendTo.add(userMail.email);
						break;
					}
				}

				ApprovalProcessAPI.SendEmailNotifications(
					denegadoControlComercialBajas,
					sendTo,
					sendCC,
					sendCCO,
					approvalProcess
				);
			}
		}
	}

	@testVisible
	private static void sendApprovalRequestNotifications(
		List<ApprovalProcess__c> newRequestedRecords,
		List<EmailTemplate> emailTemplates,
		List<User> users
	) {
		EmailTemplate solicitudComiteDirectivoBajas;
		EmailTemplate solicitudControlComercialBajas;
		EmailTemplate solicitudInformacionBajas;

		List<String> sendTo;
		List<String> sendCC;
		List<String> sendCCO;

		List<String> directosMail = ApprovalProcessAPI.getDirectorsMail(users);
		List<String> documenters = ApprovalProcessAPI.getDocumentersMail(users);
		List<String> commericial = ApprovalProcessAPI.getCommercialControlMail(
			users
		);
		List<String> proccesMail = ApprovalProcessAPI.getProcessMail(users);

		for (EmailTemplate template : emailTemplates) {
			switch on template.name {
				when 'SL_C1 Aprobación Comité Directivo cambios' {
					solicitudComiteDirectivoBajas = template;
				}
				when 'SL_C3 Información para aprobación de cambios' {
					solicitudInformacionBajas = template;
				}
				when 'SL_C2 Aprobación Control Comercial cambios' {
					solicitudControlComercialBajas = template;
				}
			}
		}

		for (ApprovalProcess__c approvalProcess : newRequestedRecords) {
			if (approvalProcess.Aprobacion_por_comite_directivo__c) {
				sendCCO = new List<String>();
				sendTo = directosMail;
				sendCC = documenters;
				sendCC.addAll(commericial);
				sendCC.addAll(proccesMail);

				ApprovalProcessAPI.SendEmailNotifications(
					solicitudComiteDirectivoBajas,
					sendTo,
					sendCC,
					sendCCO,
					approvalProcess
				);
				ApprovalProcessAPI.SendEmailNotifications(
					solicitudInformacionBajas,
					sendTo,
					sendCC,
					sendCCO,
					approvalProcess
				);
			} else {
				sendTo = ApprovalProcessAPI.getCommercialControlMail(users);
				sendCC = ApprovalProcessAPI.getCEOMail(users);
				sendCC.addAll(proccesMail);
				sendCCO = new List<String>();

				ApprovalProcessAPI.SendEmailNotifications(
					solicitudControlComercialBajas,
					sendTo,
					sendCC,
					sendCCO,
					approvalProcess
				);
			}
		}
	}

	@testVisible
	private static void sendApprovalProgressNotifications(
		List<ApprovalProcess__c> sendNotificationProgressRecords,
		List<EmailTemplate> emailTemplates,
		List<User> users
	) {
		EmailTemplate solicitudAvance;
		EmailTemplate solicitudCompleta;

		List<String> sendTo;
		List<String> sendCC = ApprovalProcessAPI.getProcessMail(users);

		for (EmailTemplate template : emailTemplates) {
			switch on template.name {
				when 'NT_C1 Avance de Documentación para Cambios' {
					solicitudAvance = template;
				}
				when 'NT_C2 Documentación Completa para cambios' {
					solicitudCompleta = template;
				}
			}
		}

		sendTo = ApprovalProcessAPI.getDirectorsMail(users);

		for (
			ApprovalProcess__c approvalProcess : sendNotificationProgressRecords
		) {
			if (validateCompleteInformation(approvalProcess)) {
				ApprovalProcessAPI.SendEmailNotifications(
					solicitudCompleta,
					sendTo,
					sendCC,
					new List<String>(),
					approvalProcess
				);
			} else {
				ApprovalProcessAPI.SendEmailNotifications(
					solicitudAvance,
					sendTo,
					sendCC,
					new List<String>(),
					approvalProcess
				);
			}
		}
	}

	public static void sendApprovedNotifications(
		List<ApprovalProcess__c> approvedNotification,
		List<EmailTemplate> emailTemplates,
		List<ApprovalProcessMail__mdt> approvalProcessMail,
		List<User> users
	) {
		EmailTemplate solicitudBaja;
		EmailTemplate solicitudAceptada;
		List<String> sendTo;
		List<String> sendCC;
		List<String> sendCCO;
		List<String> commercialMail = ApprovalProcessAPI.getCommercialControlMail(
			users
		);
		List<String> processMail = ApprovalProcessAPI.getProcessMail(users);

		for (EmailTemplate template : emailTemplates) {
			switch on template.name {
				when 'SL_C4 Implementación de Cambios OM' {
					solicitudBaja = template;
				}
				when 'RS_C1 Aprobación de cambios aceptada' {
					solicitudAceptada = template;
				}
			}
		}

		for (ApprovalProcess__c approvalProcess : approvedNotification) {
			sendTo = new List<String>();
			sendCC = new List<String>();
			sendCCO = new List<String>();
			for (ApprovalProcessMail__mdt approvalMail : approvalProcessMail) {
				if (approvalMail.Rol__c == 'Notificacion aprobado')
					sendTo.add(approvalMail.Correo_Elara__c);
			}

			for (User userMail : users) {
				if (approvalProcess.OwnerId == userMail.Id)
					sendCC.add(userMail.Email);
			}

			sendCC.addAll(commercialMail);
			sendCC.addAll(processMail);

			ApprovalProcessAPI.SendEmailNotifications(
				solicitudBaja,
				sendTo,
				sendCC,
				sendCCO,
				approvalProcess
			);

			ApprovalProcessAPI.SendEmailNotifications(
				solicitudAceptada,
				sendCC,
				new List<String>(),
				sendCCO,
				approvalProcess
			);
		}
	}

	@testVisible
	private static Boolean validateCompleteInformation(
		ApprovalProcess__c approvalProcess
	) {
		Boolean isComplete = true;

		if (approvalProcess.Saldo_cubierto_a_la_fecha__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Saldo_pendiente_de_pago__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Cantidad_de_facturas_pendientes__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Margen_Bruto__c == null) {
			isComplete = false;
		}

		if (approvalProcess.CAPEX__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Divisa_CAPEX__c == null) {
			isComplete = false;
		}

		if (approvalProcess.EBITDA__c == null) {
			isComplete = false;
		}

		if (approvalProcess.EBIT__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Payback__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Par_metros_de_rentabilidad__c == null) {
			isComplete = false;
		}

		if (approvalProcess.ROI__c == null) {
			isComplete = false;
		}

		if (approvalProcess.TIR__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Ingresos_por_cubrir__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Costos_por_cubrir__c == null) {
			isComplete = false;
		}

		if (String.isBlank(approvalProcess.Proveedor_es_y_banda_del_SE__c)) {
			isComplete = false;
		}

		if (approvalProcess.Vigencia_contrato_proveedor_satelital__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Proxima_fecha_cambio_segmento__c == null) {
			isComplete = false;
		}

		if (approvalProcess.Monto_Cambio_SE__c == null) {
			isComplete = false;
		}

		return isComplete;
	}

	@testVisible
	private static List<ApprovalProcess__c> filterNewApprovedRecords(
		Map<Id, SObject> oldMap,
		List<ApprovalProcess__c> newRecords
	) {
		List<ApprovalProcess__c> newRequestedRecords = new List<ApprovalProcess__c>();

		System.debug(oldMap);

		for (ApprovalProcess__c newApproval : newRecords) {
			ApprovalProcess__c oldApproval = (ApprovalProcess__c) oldMap.get(
				newApproval.Id
			);

			System.debug(oldApproval.Stage__c);

			if (oldApproval != null) {
				if (
					oldApproval.Stage__c != 'Aprobado' &&
					newApproval.Stage__c == 'Aprobado'
				) {
					newRequestedRecords.add(newApproval);
				}
			}
		}

		return newRequestedRecords;
	}

	public static void validateConditions(List<ApprovalProcess__c> newList) {
		//Obtenemos los tipos de sitio de de los expedientes proyecto
		Map<Id, List<TipoDeSitioPorAprobar__c>> tiposSitioPerApproval = getTiposSitioPerApprovalProcess(
			newList
		);

		//Obtenemos los productos de oportunidad de los expedientes proyecto
		Map<Id, List<OpportunityItemConsent__c>> opportunitiesLineItemsPerApproval = getOpportunityLineItemPerApprovalProcess(
			newList
		);

		//Obtenermos las referencias Elara de los expedientes proyecto
		Map<Id, List<RGU_Change_to_approve__c>> referenciasElaraPerApproval = getReferenciasElaraPerApprovalProcess(
			newList
		);

		for (ApprovalProcess__c approvalApproved : newList) {
			List<TipoDeSitioPorAprobar__c> tiposSitios = tiposSitioPerApproval.get(
				approvalApproved.id
			);

			if (tiposSitios.size() > 0) {
				//Validamos los campos de tipo de sitio, del expediente proyecto en curso
				String opportunitiesTipoSitioError = validateTiposSitio(
					tiposSitios
				);

				if (String.isNotBlank(opportunitiesTipoSitioError)) {
					approvalApproved.addError(
						'Ocurrio el siguiente error a nivel tipos de sitio: ' +
						opportunitiesTipoSitioError
					);
				}
			} else {
				approvalApproved.addError(
					' Ocurrio el siguiente error a nivel tipos de sitio: Deben de existir tipos de sitio para el proceso de aprobación ' +
					approvalApproved.Name
				);
			}

			//Obtenermos las referencias elara de las oportunidades
			List<RGU_Change_to_approve__c> referenciasElara = new List<RGU_Change_to_approve__c>();

			if (referenciasElaraPerApproval.containsKey(approvalApproved.Id)) {
				referenciasElara = referenciasElaraPerApproval.get(
					approvalApproved.Id
				);
			}

			if (referenciasElara.size() > 0) {
				//Validamos los campos de referencia elara, del expediente proyecto en curso
				String referenciasElaraError = validateReferenciasElara(
					referenciasElara
				);

				if (String.isNotBlank(referenciasElaraError)) {
					approvalApproved.addError(
						' Ocurrio el siguiente error a nivel Referencia Elara: ' +
						referenciasElaraError
					);
				}

				String tipoSitioSinRGU = validateExistRGUPerTipoSitio(
					tiposSitios,
					referenciasElara
				);

				if (String.isNotBlank(tipoSitioSinRGU)) {
					approvalApproved.addError(
						' Ocurrio el siguiente error a nivel tipo de sitio: ' +
						tipoSitioSinRGU
					);
				}
			} else {
				approvalApproved.addError(
					'Ocurrio el siguiente error a nivel referencias elara: Deben de existir referencias elara para el cierre del Expediete proyecto'
				);
			}

			//Obtenermos las productos de oportunidad de las oportunidades
			List<OpportunityItemConsent__c> opportunitiesLineItems = new List<OpportunityItemConsent__c>();

			if (
				opportunitiesLineItemsPerApproval.containsKey(
					approvalApproved.Id
				)
			) {
				opportunitiesLineItems = opportunitiesLineItemsPerApproval.get(
					approvalApproved.Id
				);
			}

			if (opportunitiesLineItems.size() > 0) {
				//Obtenemos los Productos de oportunida, del expediente proyecto

				String opportunitiesOliError = validateOpportunityLineItem(
					opportunitiesLineItems
				);

				if (String.isNotBlank(opportunitiesOliError)) {
					approvalApproved.addError(
						' Ocurrio el siguiente error a nivel productos de oportunidad: ' +
						opportunitiesOliError
					);
				}

				String sitioSinOli = validateExistOLIPerRGU(
					referenciasElara,
					opportunitiesLineItems
				);

				if (String.isNotBlank(sitioSinOli)) {
					approvalApproved.addError(
						' Ocurrio el siguiente error a nivel Sitio: ' +
						sitioSinOli
					);
				}
			} else {
				approvalApproved.addError(
					'Ocurrio el siguiente error a nivel productos de oportunidad: Deben de existir productos de oportunidad'
				);
			}
		}
	}

	@TestVisible
	private static Map<Id, List<TipoDeSitioPorAprobar__c>> getTiposSitioPerApprovalProcess(
		List<ApprovalProcess__c> newList
	) {
		Map<Id, List<TipoDeSitioPorAprobar__c>> tiposSitioPerApprovalProcess = new Map<Id, List<TipoDeSitioPorAprobar__c>>();

		List<TipoDeSitioPorAprobar__c> tiposDeSitioList = [
			SELECT
				Id,
				Name,
				Proceso_de_aprobacion__c,
				NumeroDeSitios__c,
				Lugar__c,
				ID_Orden_de_compra_cliente__c,
				Categoria_Unidad_Negocio__c,
				Concepto_Categoria__c,
				Servicio__c,
				Tipo_de_Enlace__c,
				Esquema__c,
				Banda__c,
				BWBajadaKbps__c,
				BWSubidaKbps__c,
				SS_DW__c,
				SS_UP__c,
				Paquete_KA__c,
				Cap_Fap_GB__c
			FROM TipoDeSitioPorAprobar__c
			WHERE Proceso_de_aprobacion__c IN :newList
		];

		for (TipoDeSitioPorAprobar__c tipoSitio : tiposDeSitioList) {
			List<TipoDeSitioPorAprobar__c> lTipoSitios;

			if (
				(lTipoSitios = tiposSitioPerApprovalProcess.get(
					tipoSitio.Proceso_de_aprobacion__c
				)) == null
			) {
				lTipoSitios = new List<TipoDeSitioPorAprobar__c>();
				tiposSitioPerApprovalProcess.put(
					tipoSitio.Proceso_de_aprobacion__c,
					lTipoSitios
				);
			}
			lTipoSitios.add(tipoSitio);
		}

		return tiposSitioPerApprovalProcess;
	}

	@TestVisible
	private static Map<Id, List<OpportunityItemConsent__c>> getOpportunityLineItemPerApprovalProcess(
		List<ApprovalProcess__c> newList
	) {
		Map<Id, List<OpportunityItemConsent__c>> olisPerApproval = new Map<Id, List<OpportunityItemConsent__c>>();

		List<OpportunityItemConsent__c> oppLineItems = [
			SELECT
				Id,
				Name,
				Proceso_de_aprobacion__c,
				Product2Id__c,
				Quantity__c,
				Tipo_de_ingreso__c,
				Fecha_Inicio_de_Ingreso__c,
				Fecha_Fin_Ingreso__c,
				Plazo__c,
				Referencia_Elara_por_aprobar__c,
				Forma_de_cobro__c
			FROM OpportunityItemConsent__c
			WHERE Proceso_de_aprobacion__c IN :newList
		];

		for (OpportunityItemConsent__c oppLineItem : oppLineItems) {
			List<OpportunityItemConsent__c> lOppLineItem;

			if (
				(lOppLineItem = olisPerApproval.get(
					oppLineItem.Proceso_de_aprobacion__c
				)) == null
			) {
				lOppLineItem = new List<OpportunityItemConsent__c>();
				olisPerApproval.put(
					oppLineItem.Proceso_de_aprobacion__c,
					lOppLineItem
				);
			}

			lOppLineItem.add(oppLineItem);
		}

		return olisPerApproval;
	}

	@TestVisible
	private static Map<Id, List<RGU_Change_to_approve__c>> getReferenciasElaraPerApprovalProcess(
		List<ApprovalProcess__c> newList
	) {
		Map<Id, List<RGU_Change_to_approve__c>> referenciaElaraPerApproval = new Map<Id, List<RGU_Change_to_approve__c>>();

		List<RGU_Change_to_approve__c> referenciasElaraList = [
			SELECT
				Nombre_de_sitio__c,
				Name,
				Approval_Process__c,
				Tipo_de_sitio_por_aprobar__r.Categoria_Unidad_Negocio__c,
				Tipo_de_sitio_por_aprobar__c
			FROM RGU_Change_to_approve__c
			WHERE Approval_Process__c IN :newList
		];

		for (RGU_Change_to_approve__c referenciaElara : referenciasElaraList) {
			List<RGU_Change_to_approve__c> lReferenciasElara;

			if (
				(lReferenciasElara = referenciaElaraPerApproval.get(
					referenciaElara.Approval_Process__c
				)) == null
			) {
				lReferenciasElara = new List<RGU_Change_to_approve__c>();
				referenciaElaraPerApproval.put(
					referenciaElara.Approval_Process__c,
					lReferenciasElara
				);
			}
			lReferenciasElara.add(referenciaElara);
		}

		return referenciaElaraPerApproval;
	}

	//Validamos los campos a nivel Tipo de sitio
	@TestVisible
	private static String validateTiposSitio(
		List<TipoDeSitioPorAprobar__c> tiposSitios
	) {
		String message = '';
		for (TipoDeSitioPorAprobar__c tipoSitio : tiposSitios) {
			if (tipoSitio.NumeroDeSitios__c == null) {
				message +=
					' Para el tipo de sitio ' +
					tipoSitio.Name +
					' el numero de sitio es obligatorio';
			}

			if (String.isBlank(tipoSitio.Lugar__c)) {
				message +=
					' Para el tipo de sitio ' +
					tipoSitio.Name +
					' el lugar es obligatorio ';
			}

			if (String.isBlank(tipoSitio.ID_Orden_de_compra_cliente__c)) {
				message +=
					' Para el tipo de sitio ' +
					tipoSitio.Name +
					' la orden de compra es obligatorio ';
			}

			if (String.isBlank(tipoSitio.Categoria_Unidad_Negocio__c)) {
				message +=
					' Para el tipo de sitio ' +
					tipoSitio.Name +
					' La categoria de unidad de negocio es obligatorio ';
			}

			if (String.isBlank(tipoSitio.Concepto_Categoria__c)) {
				//El concepto por categoría solo aplica cuando es VSAT
				if (tipoSitio.Categoria_Unidad_Negocio__c != 'VSAT') {
					message +=
						' Para el tipo de sitio ' +
						tipoSitio.Name +
						' El concepto de categoria es obligatorio ';
				}
			}

			//Ventas - Conectividad
			if (String.isBlank(tipoSitio.Servicio__c)) {
				if (tipoSitio.Categoria_Unidad_Negocio__c == 'VSAT') {
					message +=
						' Para el tipo de sitio ' +
						tipoSitio.Name +
						' El servicio es obligatorio ';
				}
			}

			if (String.isBlank(tipoSitio.Esquema__c)) {
				if (tipoSitio.Categoria_Unidad_Negocio__c == 'VSAT') {
					message +=
						' Para el tipo de sitio ' +
						tipoSitio.Name +
						' El esquema es obligatorio ';
				}
			}

			//El campo tiene etiqueta de arquitectura
			if (String.isBlank(tipoSitio.Tipo_de_Enlace__c)) {
				if (tipoSitio.Categoria_Unidad_Negocio__c == 'VSAT') {
					message +=
						' Para el tipo de sitio ' +
						tipoSitio.Name +
						' La arquitectura es obligatoria ';
				}
			}

			if (String.isBlank(tipoSitio.Banda__c)) {
				if (tipoSitio.Categoria_Unidad_Negocio__c == 'VSAT') {
					message +=
						' Para el tipo de sitio ' +
						tipoSitio.Name +
						' La banda es obligatorio ';
				}
			}

			if (tipoSitio.BWBajadaKbps__c == null) {
				if (tipoSitio.Categoria_Unidad_Negocio__c == 'VSAT') {
					message +=
						' Para el tipo de sitio ' +
						tipoSitio.Name +
						' El BW de bajada en Kbps es obligatorio ';
				}
			}

			if (tipoSitio.BWSubidaKbps__c == null) {
				if (tipoSitio.Categoria_Unidad_Negocio__c == 'VSAT') {
					message +=
						' Para el tipo de sitio ' +
						tipoSitio.Name +
						' El BW de subida en Kbps es obligatorio ';
				}
			}

			if (tipoSitio.SS_DW__c == null) {
				if (tipoSitio.Categoria_Unidad_Negocio__c == 'VSAT') {
					message +=
						' Para el tipo de sitio ' +
						tipoSitio.Name +
						' EL SS DW es obligatorio ';
				}
			}

			if (tipoSitio.SS_UP__c == null) {
				if (tipoSitio.Categoria_Unidad_Negocio__c == 'VSAT') {
					message +=
						' Para el tipo de sitio ' +
						tipoSitio.Name +
						' EL SS UP es obligatorio ';
				}
			}

			if (String.isBlank(tipoSitio.Paquete_KA__c)) {
				if (tipoSitio.Banda__c == 'HTS KA') {
					message +=
						' Para el tipo de sitio ' +
						tipoSitio.Name +
						' EL paquete KA es obligatorio ';
				}
			}

			if (tipoSitio.Cap_Fap_GB__c == null) {
				if (tipoSitio.Banda__c == 'HTS KA') {
					message +=
						' Para el tipo de sitio ' +
						tipoSitio.Name +
						' El campo CAP/FAP GB es obligatorio ';
				}
			}
		}

		return message;
	}

	//Validamos los campos a nivel producto de oportunidad
	@TestVisible
	private static String validateOpportunityLineItem(
		List<OpportunityItemConsent__c> lOppotunityLineItems
	) {
		String message = '';
		for (
			OpportunityItemConsent__c oppotunityLineItems : lOppotunityLineItems
		) {
			if (
				oppotunityLineItems.Quantity__c == null ||
				oppotunityLineItems.Quantity__c == 0
			) {
				message += ' La cantidad debe de ser mayor a 0 ';
			}

			if (oppotunityLineItems.Fecha_Inicio_de_Ingreso__c == null) {
				message += ' La fecha de inicio de ingreso es obligatorio ';
			}

			if (oppotunityLineItems.Fecha_Fin_Ingreso__c == null) {
				message += ' La fecha fin de ingreso es obligatorio ';
			}

			if (oppotunityLineItems.Forma_de_cobro__c == null) {
				message += ' La forma de cobro es obligatorio ';
			}

			if (
				oppotunityLineItems.Plazo__c == null ||
				oppotunityLineItems.Plazo__c == 0
			) {
				message += ' El plazo debe de ser mayor a 0 ';
			}
		}
		return message;
	}

	//Validamos los campos a nivel sitio
	@TestVisible
	private static String validateReferenciasElara(
		List<RGU_Change_to_approve__c> referenciasElara
	) {
		String message = '';
		for (RGU_Change_to_approve__c referencia : referenciasElara) {
			if (
				referencia.Tipo_de_sitio_por_aprobar__r.Categoria_Unidad_Negocio__c ==
				'VSAT'
			)
				if (String.isBlank(referencia.Nombre_de_sitio__c)) {
					message +=
						' Para la referencia ' +
						referencia.Name +
						' el nombre de sitio es obligatorio';
				}
		}
		return message;
	}

	@TestVisible
	private static String validateExistRGUPerTipoSitio(
		List<TipoDeSitioPorAprobar__c> tiposSitios,
		List<RGU_Change_to_approve__c> referenciasElara
	) {
		String message = '';
		for (TipoDeSitioPorAprobar__c tipoSitio : tiposSitios) {
			Boolean tieneRGUs = false;
			for (RGU_Change_to_approve__c referencia : referenciasElara) {
				//Si entra en esta condición significa que el tipo de sitio actual, tiene referencias elara
				if (referencia.Tipo_de_sitio_por_aprobar__c == tipoSitio.id) {
					tieneRGUs = true;
					break;
				}
			}
			if (!tieneRGUs) {
				message +=
					' El tipo de sitio ' +
					tipoSitio.name +
					' no tiene Referencias Elara';
			}
		}

		return message;
	}

	@TestVisible
	private static String validateExistOLIPerRGU(
		List<RGU_Change_to_approve__c> referenciasElara,
		List<OpportunityItemConsent__c> olis
	) {
		String message = '';
		for (RGU_Change_to_approve__c referencia : referenciasElara) {
			Boolean tieneOLI = false;
			for (OpportunityItemConsent__c oli : olis) {
				//Si entra en esta condición significa que el tipo de sitio actual, tiene referencias elara
				if (oli.Referencia_Elara_por_aprobar__c == referencia.id) {
					tieneOLI = true;
					break;
				}
			}
			if (!tieneOLI) {
				message +=
					'El sitio ' +
					referencia.name +
					' no tiene productos de oportunidad';
			}
		}

		return message;
	}
}