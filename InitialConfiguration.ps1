### 1. IF NOT ALREADY PRESENT REGISTER THE AZURE IMAGE BUILDER SERVICE WHILST IN PREVIEW###
#Register AIB
Install-Module Az -Force
Connect-AzAccount
Set-AzContext -Subscription "CSP Subscription (WVD)"
Register-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview
#Check Registration status
Get-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages
#Check Provider Registration status
Get-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview
Get-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages | Select-Object RegistrationState
Get-AzResourceProvider -ProviderNamespace Microsoft.Storage | Select-Object RegistrationState

#If not "Registered" Then run these
Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
Register-AzResourceProvider -ProviderNamespace Microsoft.Compute
Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVault

##Once registered begin your AIB image deployment##

## 2. AIB - CREATE VARIABLES
# Get existing context
$currentAzContext = Get-AzContext
# Get your current subscription ID. 
$subscriptionID=$currentAzContext.Subscription.Id
# Destination image resource group
$imageResourceGroup="Encevogroup-WVD-AzureImageBuilder"
# Location
$location="westeurope"
# Image distribution metadata reference name
$runOutputName="aibCustWinManImg02ro"
# Image template name
$imageTemplateName="ImageTemplateWin10AIB"
# Distribution properties object name (runOutput).
# This gives you the properties of the managed image on completion.
$runOutputName="winclientR01"

# 2.1 Create a resource group for Image Template and Shared Image Gallery
New-AzResourceGroup `
   -Name $imageResourceGroup `
   -Location $location

##CREATE A USER ASSIGNED IDENTITY, THIS WILL BE USED TO ADD THE IMAGE TO THE SIG
# setup role def names, these need to be unique
$timeInt=$(get-date -UFormat "%s")
$imageRoleDefName="Azure Image Builder Image Def"+$timeInt
$identityName="aibIdentity"+$timeInt
$identityName="aibIdentity"

## Add AZ PS module to support AzUserAssignedIdentity
Install-Module -Name Az.ManagedServiceIdentity

# Create identity
# New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName
$identityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId

## ASSIGN PERMISSIONS FOR THIS IDENTITY TO DISTRIBUTE IMAGES
$aibRoleImageCreationUrl="https://raw.githubusercontent.com/KevinJagiella/WVDAIB/main/aibRoleImageCreation.json"
$aibRoleImageCreationPath = "aibRoleImageCreation.json"

# Download config
Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

# Create the  role definition
New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json

# Grant role definition to image builder service principal
New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve:
https://docs.microsoft.com/azure/role-based-access-control/troubleshooting


