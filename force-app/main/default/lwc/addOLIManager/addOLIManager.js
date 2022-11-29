import { LightningElement, api } from 'lwc';
import getRelatedOLIs from '@salesforce/apex/addOLIManagerController.getRelatedOLIs';
import saveOLIs from '@salesforce/apex/addOLIManagerController.saveOLIs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    {
        label: 'Producto',
        fieldName: 'recordUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'productName' } }
    },
    {
        label: 'Cantidad',
        fieldName: 'Quantity__c',
        type: 'number'
    },
    {
        label: 'Precio de venta',
        fieldName: 'UnitPrice__c',
        type: 'currency',
        typeAttributes: {
            currencyCode: { fieldName: 'Divisa_de_Cotizacion__c' }
        }
    },
    {
        label: 'Partida ventas MXN',
        fieldName: 'Partida_Ventas_MXN__c',
        type: 'currency',
        typeAttributes: {
            currencyCode: 'MXN'
        }
    },
    {
        label: 'Partida ventas USD',
        fieldName: 'Partida_Ventas_USD__c',
        type: 'currency',
        typeAttributes: {
            currencyCode: 'USD'
        }
    },
    {
        label: 'Plazo',
        fieldName: 'Plazo__c',
        type: 'number'
    }
];

export default class AddOLIManager extends LightningElement {
    @api objectApiName;
    @api recordId;
    isSpinnerVisible = false;
    columns = columns;
    data = [];

    connectedCallback() {
        this.isSpinnerVisible = true;
        this.callGetProductsAction();
    }


    callGetProductsAction() {
        getRelatedOLIs({ recordId: this.recordId })
            .then(results => {
                console.debug(results);

                if (results) {
                    const opportunityLineItems = JSON.parse(results);
                    this.data = opportunityLineItems.map(this.formatOLI);
                }

                this.isSpinnerVisible = false;
            })
            .catch(error => {
                console.error(error);
                console.error(error.body.message);
                console.error(error.ok);

                const errorLoadingEvent = new ShowToastEvent({
                    title: 'Error al obtener productos.',
                    message: error,
                    variant: 'error'
                });

                this.dispatchEvent(errorLoadingEvent);
                this.isSpinnerVisible = false;
            });
    }

    formatOLI = opportunityLineItem => {
        const formattedRecord = opportunityLineItem;

        formattedRecord.productName = opportunityLineItem.Product2Id__r.Name;
        formattedRecord.recordUrl = '/' + opportunityLineItem.Id;

        return formattedRecord;
    };

    showProductSelector = () => {
        const producSelector = this.template.querySelector(
            'c-product-selector-card-to-approve '
        );
        producSelector.classList.remove('slds-hide');
    };

    hideProductSelector = () => {
        const producSelector = this.template.querySelector(
            'c-product-selector-card-to-approve '
        );
        producSelector.classList.add('slds-hide');
    };

    handleCancel = event => {
        this.hideProductSelector(event);
    };

    handleSave = event => {
        this.template
            .querySelector('c-product-selector-card-to-approve')
            .classList.add('slds-hide');
        const stagedProducts = event.detail.stagedProducts;

        let opportunityLineItems = stagedProducts.map(item => {
            let opportunityLineItem = {};

            opportunityLineItem.attributes = { type: 'OpportunityItemConsent__c' };
            opportunityLineItem.Product2Id__c = item.Product2.Id;
            opportunityLineItem.PricebookEntryId__c = item.id;
            opportunityLineItem.Quantity__c = item.Quantity;
            opportunityLineItem.Divisa_de_Cotizacion__c =
                item.Divisa_de_Cotizacion__c;
            opportunityLineItem.Forma_de_Cobro__c = item.Forma_de_Cobro__c;
            opportunityLineItem.TipoDeCambioCotizado__c =
                item.TipoDeCambioCotizado__c;
            opportunityLineItem.Description__c = item.Description;
            opportunityLineItem.UnitPrice__c = item.UnitPrice__c;
            opportunityLineItem.Plazo__c = item.Plazo__c;
            opportunityLineItem.Fecha_Inicio_de_Ingreso__c = Date.parse(
                item.Fecha_Inicio_Ingreso__c
            );
            opportunityLineItem.Fecha_Fin_Ingreso__c = Date.parse(
                item.Fecha_Fin_Ingreso__c
            );
            opportunityLineItem.Tipo_de_ingreso__c = item.Tipo_Ingreso__c;
            return opportunityLineItem;
        });

        if (opportunityLineItems.length !== 0) {
            this.isSpinnerVisible = true;

            console.log(JSON.parse(JSON.stringify(opportunityLineItems)));

            console.log('Saving...');

            saveOLIs({
                recordId: this.recordId,
                products: JSON.stringify(opportunityLineItems)
            })
                .then((results) => {

                    this.isSpinnerVisible = false;

                    if (results.status === 200) {
                        const successEvent = new ShowToastEvent({
                            title: 'Producto de Oportunidad guardado',
                            message:
                                'Los productos han sido asociados al registro de forma exitosa.',
                            variant: 'success'
                        });

                        this.dispatchEvent(successEvent);

                        this.callGetProductsAction();
                    } else if (results.status === 500) {
                        console.error(results.name + results.message);

                        const errorEvent = new ShowToastEvent({
                            title: results.name,
                            message: results.message,
                            variant: 'error'
                        });

                        this.dispatchEvent(errorEvent);

                    }

                })
        }
    };
}