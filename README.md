# Información sobre el proyecto

## * Liberación de proyecto

1. Eliminar el layout de preceso de aprobación ``` ApprovalProcess__c-Formato Proceso de aprobación.layout-meta.xml```
2. Ejecutar script ```.\scripts\psh\deploymentSequence.ps1```
3. Reestablecer el layuut eliminado en el paso 1 y liberarlo desde clic derecho y ``` SFDX: Deploy source to org```