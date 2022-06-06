import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['ApprovalProcess__c.AccountName__c'];

export default class EmailRouting extends NavigationMixin(LightningElement) {
	@api recordId;
	record = null;

	@api invoke() {
		console.log('invoke');
		if (this.record) {
			this.navigateToEmailComposer();
		}
	}

	@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
	approvalProcessWire({ error, data }) {
		if (data) {
			console.log('data');
			this.record = data;
			this.navigateToEmailComposer();
		} else if (error) {
			console.log('error', error);
		}
	}

	navigateToEmailComposer = () => {
		this[NavigationMixin.Navigate]({
			type: 'standard__webPage',
			attributes: {
				url:
					'/_ui/core/email/author/EmailAuthor?p2_lkid=' +
					this.record.fields.AccountName__c +
					'&rtype=003&p3_lkid=' +
					this.record.id +
					'&p24=alberto.hernandez@elara.com.mx&template_id=00X3J000000NWDRUA4&retURL=' +
					this.record.id
			}
		});
	};
}
