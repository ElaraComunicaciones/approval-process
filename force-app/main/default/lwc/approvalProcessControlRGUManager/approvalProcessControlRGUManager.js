import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { loadStyle } from 'lightning/platformResourceLoader';
import CustomModal from '@salesforce/resourceUrl/CustomModal';

export default class ApprovalProcessControlRGUManager extends LightningElement {
	@api recordId;

	connectedCallback() {
		loadStyle(this, CustomModal);
	}

	closeScreen(event) {
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}
