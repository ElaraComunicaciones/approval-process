import { LightningElement, wire, api, track } from 'lwc';
import getRelatedReferences from '@salesforce/apex/ApprovalProcessControlRGUController.getRelatedReferences';
import saveRGUChangeToApprove from '@salesforce/apex/ApprovalProcessControlRGUController.saveRGUChangeToApprove';
import getRGUToApprove from '@salesforce/apex/ApprovalProcessControlRGUController.getRGUToApprove';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import STAGE from '@salesforce/schema/ApprovalProcess__c.Stage__c';
import ACCION from '@salesforce/schema/ApprovalProcess__c.Action__c';

const columns = [
	{
		label: 'Referencia elara',
		fieldName: 'Referencia__c',
		sortable: true,
		type: 'text'
	},
	{
		label: 'Nombre de Sitio',
		fieldName: 'Nombre_de_sitio__c',
		sortable: true,
		type: 'text'
	},
	{
		label: 'Número de sitio',
		fieldName: 'Numero_Sitio__c',
		sortable: true,
		type: 'text'
	},
	{
		label: 'Estatus en CoS',
		fieldName: 'Status_COS__c',
		sortable: true,
		type: 'text'
	}
];

export default class ApprovalProcessControlRGUBajas extends LightningElement {
	@api recordId;
	@track rgus = [];
	@api kindOfProces = 1;
	@track selectedRows = [];
	tituloMostrar = '';
	isLoading = true;
	columns = columns;
	defaultSortDirection = 'asc';
	sortDirection = 'asc';
	sortedBy;

	@track dataSaving = {
		isSaving: false,
		error: null,
		data: null
	};

	@track toastMessage = {
		variant: null,
		title: null,
		meessage: null
	};

	//Obtiene las referencias elara del EP asociado al proceso de aprobación
	@wire(getRelatedReferences, { recordId: '$recordId' })
	relatedReferences({ data, error }) {
		if (data) {
			this.rgus = data;
			this.selectedRGUToApprove();
			this.isLoading = false;

			switch (this.accion) {
				case 'Cancelación de referencias':
					this.tituloMostrar = 'Referencias Elara a Cancelar';
					break;

				case 'Baja definitiva':
					this.tituloMostrar = 'Referencias Elara a Dar de Baja';
					break;

				case 'Cambio - Actualización':
					this.tituloMostrar = 'Referencias Elara a Actualizar';
					break;

				case 'Baja por actualización':
					this.tituloMostrar = 'Referencias Elara a Actualizar';
					break;

				default:
					this.tituloMostrar = 'Tipo de proceso de aprobación no definido'
			}

		} else if (error) {
			console.log('Error' + JSON.stringify(error));
		}
	}

	@wire(getRecord, { recordId: '$recordId', fields: [STAGE, ACCION] })
	approvalProcess;

	get stage() {
		return getFieldValue(this.approvalProcess.data, STAGE);
	}

	get accion() {
		return getFieldValue(this.approvalProcess.data, ACCION);
	}

	//Metodos del datatable para realizar el ordenamiento de las columnas
	sortBy(field, reverse, primer) {
		const key = primer
			? function (x) {
				return primer(x[field]);
			}
			: function (x) {
				return x[field];
			};

		return function (a, b) {
			a = key(a);
			b = key(b);
			return reverse * ((a > b) - (b > a));
		};
	}

	onHandleSort(event) {
		const { fieldName: sortedBy, sortDirection } = event.detail;
		const cloneData = [...this.rgus];

		cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
		this.rgus = cloneData;
		this.sortDirection = sortDirection;
		this.sortedBy = sortedBy;
	}

	//Buscamos si ya hay referencias elara seleccionadas para dar de baja
	selectedRGUToApprove = function () {
		getRGUToApprove({ recordId: this.recordId })
			.then((result) => {
				let selectedRows =
					result == null || result === undefined ? [] : result;

				this.selectedRows = selectedRows;
			})
			.catch((error) => {
				this.dataSaving = {
					isSaving: false,
					error: error.body.message
				};

				this.toastMessage = {
					title: 'Error"!',
					message:
						'Ocurrio el siguiente error al tratar de guardar los cambios de las referencias elara: ' +
						error.body.message,
					variant: 'error'
				};

				const toastMessage = new ShowToastEvent(this.toastMessage);
				this.dispatchEvent(toastMessage);

				const closeScreen = new CustomEvent('closescreen', {
					detail: null
				});
				this.dispatchEvent(closeScreen);
			});
	};

	@api
	get showSpinner() {
		return this.isLoading ? true : this.dataSaving.isSaving ? true : false;
	}

	//Metodo que guarda las referencias para aprobación
	handleSave() {
		var datatable = this.template.querySelector('lightning-datatable');
		this.selectedRows = datatable.getSelectedRows();

		this.dataSaving = {
			isSaving: true
		};

		saveRGUChangeToApprove({
			recordId: this.recordId,
			stage: this.stage,
			referenciasSeleccionadas: this.selectedRows
		})
			.then(() => {
				this.dataSaving = {
					isSaving: false
				};

				this.toastMessage = {
					title: '¡Listo"!',
					message:
						'Se realizó el guardado de las ' + this.tituloMostrar,
					variant: 'success'
				};

				const toastMessage = new ShowToastEvent(this.toastMessage);
				this.dispatchEvent(toastMessage);

				const closeScreen = new CustomEvent('closescreen', {
					detail: null
				});
				this.dispatchEvent(closeScreen);
			})
			.catch((error) => {
				this.dataSaving = {
					isSaving: false,
					error: error.body.message
				};

				this.toastMessage = {
					title: 'Error"!',
					message:
						'Ocurrio el siguiente error al tratar de guardar los cambios de las referencias elara: ' +
						error.body.message,
					variant: 'error'
				};

				const toastMessage = new ShowToastEvent(this.toastMessage);
				this.dispatchEvent(toastMessage);

				const closeScreen = new CustomEvent('closescreen', {
					detail: null
				});
				this.dispatchEvent(closeScreen);
			});
	}

	handleCancel() {
		const closeScreen = new CustomEvent('closescreen', { detail: null });
		this.dispatchEvent(closeScreen);
	}
}