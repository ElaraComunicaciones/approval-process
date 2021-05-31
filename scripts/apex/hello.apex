
List<ApprovalProcess__c> controls = [
    SELECT
    Id,
    Name
    FROM ApprovalProcess__c
];

delete controls;