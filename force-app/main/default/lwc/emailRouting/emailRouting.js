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
			this.record = data;
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
					'&template_id=00X8N000000HqvOUAS&retURL=' +
					this.record.id
			}
		});
	};
}
