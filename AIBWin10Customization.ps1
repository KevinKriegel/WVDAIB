#Script to setup golden image with Azure Image Builder
#Kevin Jagiella - Elgon

#Create temp folder
New-Item -Path 'C:\temp' -ItemType Directory -Force | Out-Null

#InstallFSLogix
Invoke-WebRequest -Uri 'https://aka.ms/fslogix_download' -OutFile 'c:\temp\fslogix.zip'
Start-Sleep -Seconds 10
Expand-Archive -Path 'C:\temp\fslogix.zip' -DestinationPath 'C:\temp\fslogix\'  -Force
Invoke-Expression -Command 'C:\temp\fslogix\x64\Release\FSLogixAppsSetup.exe /install /quiet /norestart'

#Start sleep
Start-Sleep -Seconds 10

#Install Zoom Client
Invoke-WebRequest -Uri 'https://zoom.us/client/latest/ZoomInstallerFull.msi' -OutFile 'c:\temp\ZoomInstallerFull.msi'
Start-Sleep -Seconds 10
Invoke-Expression -Command 'msiexec /i c:\temp\ZoomInstallerFull.msi /quiet /qn /norestart'

#Start sleep
Start-Sleep -Seconds 10

#Install VC++ & WebSocket Service
Invoke-WebRequest -Uri 'https://support.microsoft.com/help/2977003/the-latest-supported-visual-c-downloads' -OutFile 'c:\temp\vc.msi'
Invoke-Expression -Command 'c:\temp\vc.msi /quiet'
#Start sleep
Start-Sleep -Seconds 10
Invoke-WebRequest -Uri 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4vkL6' -OutFile 'c:\temp\websocket.msi'
Invoke-Expression -Command 'c:\temp\websocket.msi /quiet'

#Start sleep
Start-Sleep -Seconds 10

<#
#Install WVD Optimization script 
#Initialization Part
$verboseSettings = $VerbosePreference
$VerbosePreference = 'Continue'
$toolsPath = "C:\Temp"
$optimalizationScriptURL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/master.zip'
$optimalizationScriptZIP = "$toolsPath\Virtual-Desktop-Optimization-Tool-master.zip"
$OptimalizationFolderName = "$toolsPath\" + [System.IO.Path]::GetFileNameWithoutExtension("Virtual-Desktop-Optimization-Tool-master.zip")
 
$toolsTest = Test-Path -Path $toolsPath
if ($toolsTest -eq $false){
    Write-Verbose "Creating '$toolsPath' directory"
    New-Item -ItemType Directory -Path $toolsPath | Out-Null
}
else {
    Write-Verbose "Directory '$toolsPath' already exists."
}
 
#Installation Part
Write-Verbose "Downloading '$optimalizationScriptURL' into '$optimalizationScriptZIP'"
Invoke-WebRequest -Uri $optimalizationScriptURL -OutFile $optimalizationScriptZIP
New-Item -ItemType Directory -Path "$OptimalizationFolderName"
Write-Verbose "Expanding Archive '$optimalizationScriptZIP ' into '$OptimalizationFolderName'"
Expand-Archive -LiteralPath $optimalizationScriptZIP -DestinationPath $OptimalizationFolderName
Set-Location "$OptimalizationFolderName\Virtual-Desktop-Optimization-Tool-master"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
Invoke-Expression -Command '.\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2009 -Verbose'
#>

Start sleep
Start-Sleep -Seconds 10
