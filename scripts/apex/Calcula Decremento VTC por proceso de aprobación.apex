//Decremento al VTC por RGU

//Obtenemos los procesos de aprobación
List<ApprovalProcess__C> newList = [
  SELECT id, name
  FROM ApprovalProcess__c
  WHERE name = 'AP00000031'
];

System.debug(newList);

//Obtenemos los clones de RGU de los procesos de aprobación
List<RGU_Change_to_approve__c> lRGUsToChange = [
  SELECT id, Approval_Process__c, Referencia_Elara_Original__c
  FROM RGU_Change_to_approve__c
  WHERE Approval_Process__c IN :newList
];


//Se genera mapa de Procesos de aprobacion con sus RGUs Clones
Map<id, List<RGU_Change_to_approve__c>> rgusPerApprovalProcess = new Map<id, List<RGU_Change_to_approve__c>>();

for (RGU_Change_to_approve__c rgu : lRGUsToChange) {
  List<RGU_Change_to_approve__c> lrgus;

  if ((lrgus = rgusPerApprovalProcess.get(rgu.Approval_Process__c)) == null) {
    lrgus = new List<RGU_Change_to_approve__c>();
    rgusPerApprovalProcess.put(rgu.Approval_Process__c, lrgus);
  }
  lrgus.add(rgu);
}

Set<Id> idsRGUs = new Set<Id>();

//Obtenemos los OLIS de 
for (RGU_Change_to_approve__c rguToChange : lRGUsToChange) {
  idsRGUs.add(rguToChange.Referencia_Elara_Original__c);
}

Map<Id, List<OpportunityLineItem>> olisPerRGUs = new Map<Id, List<OpportunityLineItem>>();

//Obtenemos los productos de oportunidad por referencias elara original
List<OpportunityLineItem> oppLineItems = [
  SELECT Id, Referencia_Elara__r.id, Fecha_Fin_Ingreso__c, Total_Renta_MXN__c
  FROM OpportunityLineItem
  WHERE Forma_de_Cobro__c != 'Diaria' AND Referencia_Elara__r.id IN :idsRGUs
];

for (OpportunityLineItem oppLineItem : oppLineItems) {
  List<OpportunityLineItem> lOppLineItem;

  if (
    (lOppLineItem = olisPerRGUs.get(oppLineItem.Referencia_Elara__r.id)) == null
  ) {
    lOppLineItem = new List<OpportunityLineItem>();
    olisPerRGUs.put(oppLineItem.Referencia_Elara__r.id, lOppLineItem);
  }
  lOppLineItem.add(oppLineItem);
}

System.debug(olisPerRGUs);

//Generamos los decrementos de VTC de las referencias ELARA
Map<id, Decimal> lDecrementPerRGU = new Map<Id, Decimal>();

for (RGU_Change_to_approve__c rguToChange : lRGUsToChange) {
  List<OpportunityLineItem> actualOlis = olisPerRGUs.get(
    rguToChange.Referencia_Elara_Original__c
  );
  Decimal decrementoVTC = 0;
  for (OpportunityLineItem oli : actualOlis) {
    //Se obtienen los meses que ya no se van a cobrar, con respecto al día de hoy
    Integer lapseBetweenEndDateToday = oli.Fecha_Fin_Ingreso__c.monthsBetween(
      System.today()
    );
    decrementoVTC +=
      Math.abs(lapseBetweenEndDateToday) * oli.Total_Renta_MXN__c;
  }
  lDecrementPerRGU.put(rguToChange.id, decrementoVTC);
}

System.debug(lDecrementPerRGU);
System.debug(rgusPerApprovalProcess);

Map<id, Decimal> decrementsPerApprovalProcess = new Map<Id, Decimal>();

for (Id key : rgusPerApprovalProcess.keySet()) {
  List<RGU_Change_to_approve__c> lRGUS = rgusPerApprovalProcess.get(key);
  Decimal decrementVTC = 0;
  for(RGU_Change_to_approve__c rgu : lRGUS){
    decrementVTC += lDecrementPerRGU.get(rgu.id);
  } 

  decrementsPerApprovalProcess.put(key, decrementVTC);
}

System.debug(decrementsPerApprovalProcess);