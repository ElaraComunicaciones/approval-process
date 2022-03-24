import { LightningElement, wire, api } from 'lwc';
import getRelatedReferences from '@salesforce/apex/ApprovalProcessControlRGUController.getRelatedReferences';

export default class ApprovalProcessControlRGUBajas extends LightningElement {
	@api recordId;
	@api foo = 'foo';

	@wire(getRelatedReferences, { recordId: '$recordId' })
	relatedReferences = [];

	connectedCallback() {}
}
