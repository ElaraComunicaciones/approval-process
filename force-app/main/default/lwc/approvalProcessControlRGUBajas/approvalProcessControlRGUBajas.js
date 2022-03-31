import { LightningElement, wire, api, track } from 'lwc';
import getRelatedReferences from '@salesforce/apex/ApprovalProcessControlRGUController.getRelatedReferences';
import saveRGUChangeToApprove from '@salesforce/apex/ApprovalProcessControlRGUController.saveRGUChangeToApprove';
import getRGUToApprove from '@salesforce/apex/ApprovalProcessControlRGUController.getRGUToApprove';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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
		} else if (error) {
			console.log('Error' + JSON.stringify(error));
		}
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
					error: error
				};

				this.toastMessage = {
					title: 'Error"!',
					message:
						'Ocurrio el siguiente error al tratar de guardar los cambios de las referencias elara: ' +
						error,
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
			referenciasSeleccionadas: this.selectedRows
		})
			.then(() => {
				this.dataSaving = {
					isSaving: false
				};

				this.toastMessage = {
					title: '¡Listo"!',
					message:
						'Se realizó el guardado de las referencias elara a dar de baja',
					variant: 'success'
				};

				const toastMessage = new ShowToastEvent(this.toastMessage);
				this.dispatchEvent(toastMessage);

				const closeScreen = new CustomEvent('closescreen', {
					detail: null
				});
				this.dispatchEvent(closeScreen);
				//location.reload();
				document.dispatchEvent(new CustomEvent('aura://refreshView'));
			})
			.catch((error) => {
				this.dataSaving = {
					isSaving: false,
					error: error
				};

				this.toastMessage = {
					title: 'Error"!',
					message:
						'Ocurrio el siguiente error al tratar de guardar los cambios de las referencias elara: ' +
						error,
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
