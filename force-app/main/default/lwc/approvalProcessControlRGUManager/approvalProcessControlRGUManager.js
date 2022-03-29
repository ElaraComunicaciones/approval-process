import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ApprovalProcessControlRGUManager extends LightningElement {
	@api recordId;

	closeScreen(event){
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}