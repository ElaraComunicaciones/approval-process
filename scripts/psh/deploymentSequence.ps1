$tmpDir = '.\tmp-package-dir'
$chgSetZip = '.\changes-set.zip'

if ( Test-Path -Path $tmpDir ) {
    Remove-Item -Path $tmpDir -Recurse -Force
} 
if ( Test-Path -Path $chgSetZip ) {
    Remove-Item -Path $chgSetZip -Force
}

sfdx project convert source -d tmp-package-dir
tar.exe -a -c -f changes-set.zip tmp-package-dir
sfdx force:mdapi:deploy --zipfile changes-set.zip --testlevel RunSpecifiedTests --runtests ApprovalProcessAPITest,ApprovalProcessTriggerSettingsTest,RGU_Change_to_approveAPITest,RGU_Change_to_approveTriggerSettingsTest,OrganicGrowthApprovalProcessTest,CancellationApprovalProcessTest,addOLIManagerControllerTest,UpdatesApprovalProcessTest,DeactingByUpdateTest  -w 3 --checkonly
