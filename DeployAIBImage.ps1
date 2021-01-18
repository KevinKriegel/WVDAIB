## 2. AIB - CREATE VARIABLES
# Get existing context
Set-AzContext -Subscription "CSP Subscription (WVD)"
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
$imageTemplateName="EncevogroupImgTemplateWin10AIB"
# Distribution properties object name (runOutput).
# This gives you the properties of the managed image on completion.
$runOutputName="winclientR01"

# 2.1 Create a resource group for Image Template and Shared Image Gallery
New-AzResourceGroup `
   -Name $imageResourceGroup `
   -Location $location

## 3. CREATE THE SHARED IMAGE GALLERY
# Set Image gallery name
$sigGalleryName= "AIBSIG"

# Image definition name - define an appropriate name
# Server:
#$imageDefName ="winSvrimage"
# Or Win 10 Client 
$imageDefName ="EncevoGroup-WVD-BaseImageAIB"

# Additional replication region, this is the secondary Azure region in addition to the $location above.
#$replRegion2="westeurope"

# Create the gallery
New-AzGallery `
   -GalleryName $sigGalleryName `
   -ResourceGroupName $imageResourceGroup  `
   -Location $location

# 3.1 Create the image "definition", Windows Server or Windows client below - choose one.
   New-AzGalleryImageDefinition `
   -GalleryName $sigGalleryName `
   -ResourceGroupName $imageResourceGroup `
   -Location $location `
   -Name $imageDefName `
   -OsState generalized `
   -OsType Windows `
   -Publisher 'EncevoGroup' `
   -Offer 'Standard' `
   -Sku 'Standard'


## 3.2 DOWNLOAD AND CONFIGURE THE TEMPLATE WITH YOUR PARAMS
   $templateFilePath = "armTemplateWinSIG.json"

Invoke-WebRequest `
   -Uri "https://raw.githubusercontent.com/KevinJagiella/WVDAIB/main/AIBWin10MS.json" `
   -OutFile $templateFilePath `
   -UseBasicParsing

(Get-Content -path $templateFilePath -Raw ) `
   -replace '<subscriptionID>',$subscriptionID | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<rgName>',$imageResourceGroup | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<runOutputName>',$runOutputName | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<imageDefName>',$imageDefName | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<sharedImageGalName>',$sigGalleryName | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<region1>',$location | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<region2>',$replRegion2 | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>',$identityNameResourceId) | Set-Content -Path $templateFilePath

##CREATE THE IMAGE VERSION
New-AzResourceGroupDeployment `
   -ResourceGroupName $imageResourceGroup `
   -TemplateFile $templateFilePath `
   -api-version "2019-05-01-preview" `
   -imageTemplateName $imageTemplateName `
   -svclocation $location

   ##BUILD THE IMAGE
   Invoke-AzResourceAction `
   -ResourceName $imageTemplateName `
   -ResourceGroupName $imageResourceGroup `
   -ResourceType Microsoft.VirtualMachineImages/imageTemplates `
   -ApiVersion "2019-05-01-preview" `
   -Action Run


   #This has now kicked of a build into the AIB service which will do its stuff. To check the Image Build Process run the cmd below. 
   #It will go from Building, to Distributing to Complete, it will take some time.
   (Get-AzResource -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $ImageTemplateName).Properties.lastRunStatus
