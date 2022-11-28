public with sharing class UpdatesApprovalProcess {
	public static void executeBeforeUpdateProcess(
		Map<id, SObject> oldMap,
		List<ApprovalProcess__c> newList
	) {
		List<ApprovalProcess__c> newRequestedRecords = filterNewRequestedRecords(
			oldMap,
			newList
		);

		validateConditions(newRequestedRecords);
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

		operationsWithApprovedRecords(
			newApprovedRecords,
			opportunities,
			accounts
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
				when 'RS_C2 Aprobación de cambios denegada por Comité Directivo' {
					denegadoComiteDirectivoBajas = template;
				}
				when 'RS_C3 Aprobación de cambios denegada por Control Comercial' {
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
		//Obtenemos los productos de oportunidad de los expedientes proyecto
		Map<Id, List<OpportunityItemConsent__c>> opportunitiesLineItemsPerApproval = getOpportunityLineItemPerApprovalProcess(
			newList
		);

		List<RGU_Change_to_approve__c> referenciasElara = getRGUToApprovePerApprovalProcess(
			newList
		);

		for (ApprovalProcess__c approvalApproved : newList) {
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
	private static List<RGU_Change_to_approve__c> getRGUToApprovePerApprovalProcess(
		List<ApprovalProcess__c> newList
	) {
		Map<Id, List<OpportunityItemConsent__c>> olisPerApproval = new Map<Id, List<OpportunityItemConsent__c>>();

		List<RGU_Change_to_approve__c> lRGUToApprove = [
			SELECT Id, Name
			FROM RGU_Change_to_approve__c
			WHERE Approval_Process__c IN :newList
		];

		return lRGUToApprove;
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
			} else if (oppotunityLineItems.Forma_de_cobro__c != 'Pago Único') {
				message += ' La forma de cobro es diferente a pago único ';
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

	@testVisible
	private static void operationsWithApprovedRecords(
		List<ApprovalProcess__c> approvedRecords,
		Map<Id, Opportunity> opportunities,
		Map<Id, Account> accounts
	) {
		List<Opportunity> lOpp = new List<Opportunity>();
		for (Opportunity oli : opportunities.values()) {
			lOpp.add(oli);
		}

		if (approvedRecords.size() > 0) {
			List<OpportunityItemConsent__c> lOlist = OrganicGrowthUtils.getOlisPerApprovalProcess(
				approvedRecords
			);
			updateDatesForOlis(lOlist);

			List<ApprovalProcess__c> lApprovalUpdated = getApprovalProcessIncreseUpdated(
				approvedRecords
			);

			createProjectHistoryValue(lApprovalUpdated, opportunities);
			createAccountHistoryValue(
				lApprovalUpdated,
				opportunities,
				accounts
			);
			migrateInformation(lApprovalUpdated);
		}
	}

	@testVisible
	private static List<ApprovalProcess__c> getApprovalProcessIncreseUpdated(
		List<ApprovalProcess__c> lApproval
	) {
		List<ApprovalProcess__c> lApprovalProcessUpdated = [
			SELECT id, Opportunity__c, Incremento_en_VTC__c
			FROM ApprovalProcess__c
			WHERE id IN :lApproval
		];

		return lApprovalProcessUpdated;
	}

	@testVisible
	private static void createProjectHistoryValue(
		List<ApprovalProcess__c> approvedRecords,
		Map<Id, Opportunity> opportunities
	) {
		List<TotalProjectValueHistory__c> lHistoryValue = new List<TotalProjectValueHistory__c>();

		for (ApprovalProcess__c approvalProcess : approvedRecords) {
			TotalProjectValueHistory__c historyValue = new TotalProjectValueHistory__c();
			Opportunity currentOpp = opportunities.get(
				approvalProcess.Opportunity__c
			);
			historyValue.Opportunity__c = approvalProcess.Opportunity__c;
			historyValue.Total_Proyecto_OldValue__c = currentOpp.Total_Proyecto__c;
			historyValue.Total_Proyecto_NewValue__c =
				currentOpp.Total_Proyecto__c +
				approvalProcess.Incremento_en_VTC__c;

			lHistoryValue.add(historyValue);
		}

		insert lHistoryValue;
	}

	@testVisible
	private static void createAccountHistoryValue(
		List<ApprovalProcess__c> approvedRecords,
		Map<Id, Opportunity> opportunities,
		Map<Id, Account> accounts
	) {
		List<TotalAccountValueHistory__c> lHistoryValue = new List<TotalAccountValueHistory__c>();

		for (ApprovalProcess__c approvalProcess : approvedRecords) {
			TotalAccountValueHistory__c historyValue = new TotalAccountValueHistory__c();
			Account currentAccount = accounts.get(
				opportunities.get(approvalProcess.Opportunity__c).AccountId
			);
			historyValue.Account__c = currentAccount.Id;
			historyValue.Total_Account_OldValue__c = currentAccount.Total_Proyecto__c;
			historyValue.Total_Account_NewValue__c =
				currentAccount.Total_Proyecto__c +
				approvalProcess.Incremento_en_VTC__c;

			lHistoryValue.add(historyValue);
		}

		insert lHistoryValue;
	}

	@testVisible
	private static void migrateInformation(
		List<ApprovalProcess__c> lApprovalProcess
	) {
		List<OpportunityItemConsent__c> olisConcent = [
			SELECT
				Categoria_Costos__c,
				Description__c,
				Divisa_de_Cotizacion__c,
				Equipo_en_renta__c,
				Fecha_Fin_Ingreso__c,
				Fecha_Inicio_de_Ingreso__c,
				Forma_de_cobro__c,
				LineItemTemplateToApprove__c,
				ListPrice__c,
				Name,
				NombreProducto__c,
				PricebookEntryId__c,
				Proceso_de_aprobacion__c,
				Product2Id__c,
				Quantity__c,
				Referencia_Elara_por_aprobar__c,
				Revenue_Status__c,
				Subcategoria_Costos__c,
				TipoDeCambioCotizado__c,
				Tipo_de_ingreso__c,
				UnitPrice__c,
				Plazo__c,
				Proceso_de_aprobacion__r.Opportunity__c,
				Referencia_Elara_por_aprobar__r.Referencia_Elara_Original__c
			FROM OpportunityItemConsent__c
			WHERE Proceso_de_aprobacion__c IN :lApprovalProcess
		];

		OpportunityTriggerSettings.setCurrentActiveValue(false);
		TipoDeSitioTriggerSettings.setCurrentActiveValue(false);
		RGUTriggerSettings.setCurrentActiveValue(false);
		List<OpportunityLineItem> olisToInsert = generateOLI(olisConcent);

		insert olisToInsert;
	}

	@testvisible
	private static List<OpportunityLineItem> generateOLI(
		List<OpportunityItemConsent__c> lOpportunityItemConset
	) {
		List<OpportunityLineItem> lOlis = new List<OpportunityLineItem>();

		for (
			OpportunityItemConsent__c opporunityItemConset : lOpportunityItemConset
		) {
			OpportunityLineItem opportunityLineItem = new OpportunityLineItem();

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
			opportunityLineItem.Referencia_Elara__c = opporunityItemConset.Referencia_Elara_por_aprobar__r.Referencia_Elara_Original__c;
			opportunityLineItem.Tipo_Ingreso__c = opporunityItemConset.Tipo_de_ingreso__c;
			opportunityLineItem.OpportunityId = opporunityItemConset.Proceso_de_aprobacion__r.Opportunity__c;

			lOlis.add(opportunityLineItem);
		}
		return lOlis;
	}

	public static void updateDatesForOlis(
		List<OpportunityItemConsent__c> olis
	) {
		for (OpportunityItemConsent__c oli : olis) {
			if (oli.Proceso_de_aprobacion__r.Fecha_Inicio_Pactada__c != null) {
				oli.Fecha_Inicio_de_Ingreso__c = oli.Proceso_de_aprobacion__r.Fecha_Inicio_Pactada__c;
			} else {
				oli.Fecha_Inicio_de_Ingreso__c = Date.today();
			}

			if (oli.Proceso_de_aprobacion__r.Fecha_final_pactada__c != null) {
				if (oli.Forma_de_Cobro__c == 'Pago Único') {
					oli.Fecha_Fin_Ingreso__c = oli.Fecha_Inicio_de_Ingreso__c;
				} else {
					oli.Fecha_Fin_Ingreso__c = oli.Proceso_de_aprobacion__r.Fecha_final_pactada__c;
				}

				oli.plazo__c = IncomeType.calcularPlazo(
					oli.Fecha_Inicio_de_Ingreso__c,
					oli.Fecha_Fin_Ingreso__c,
					oli.Forma_de_Cobro__c
				);
			} else {
				if (oli.Forma_de_Cobro__c == 'Pago Único') {
					oli.Fecha_Fin_Ingreso__c = oli.Fecha_Inicio_de_Ingreso__c;
				} else {
					oli.Fecha_Fin_Ingreso__c = oli.Fecha_Inicio_de_Ingreso__c.addMonths(
						Integer.valueOf(
							oli.Proceso_de_aprobacion__r.Vigencia_del_servicio__c
						)
					);

					oli.plazo__c = oli.Proceso_de_aprobacion__r.Vigencia_del_servicio__c;
				}
			}
		}

		OpportunityItemConsentTriggerSettings.updateWithoutTriggers(olis);
	}
}