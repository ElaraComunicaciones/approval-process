import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['ApprovalProcess__c.AccountName__c'];

export default class MyCustomElement extends NavigationMixin(LightningElement) {
	recordIdValue;

	@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
	approvalProcessWire({ error, data }) {
		if (data) {
			console.log('data', data);

			this[NavigationMixin.Navigate]({
				type: 'standard__webPage',
				attributes: {
					url:
						'/_ui/core/email/author/EmailAuthor?p2_lkid=' +
						data.fields.AccountName__c +
						'&rtype=003&p3_lkid=' +
						data.id +
						'&p24="alberto.hernandez@elara.com.mx"&template_id=00X3J000000NWDRUA4&retURL=' +
						data.id
				}
			});

			// this[NavigationMixin.Navigate]({
			// 	type: 'standard__webPage',
			// 	attributes: {
			// 		url:
			// 			'/_ui/core/email/author/EmailAuthor?p26=support@mycompany.net:US Support'

			// 	}
			// });
		} else if (error) {
			console.log('data', error);
		}
	}

	@api
	get recordId() {
		return this.recordIdValue;
	}

	set recordId(value) {
		this.recordIdValue = value;
		console.log('recordId now is available ', this.recordId);
	}
}
