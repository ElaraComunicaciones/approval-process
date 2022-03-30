import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class ApprovalProcessControlRGUManager extends LightningElement {
	@api recordId;

	closeScreen(event) {
		this.dispatchEvent(new CloseActionScreenEvent());
		location.reload();
	}
}
