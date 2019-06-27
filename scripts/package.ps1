$ErrorActionPreference = "Stop"

. a:\Test-Command.ps1

Enable-RemoteDesktop
netsh advfirewall firewall add rule name="Remote Desktop" dir=in localport=3389 protocol=TCP action=allow

Update-ExecutionPolicy -Policy Unrestricted

if (Test-Command -cmdname 'Uninstall-WindowsFeature') {
  # need to install certain features to preserve them, as the remove block
  # below breaks the ability to install them afterwards
  Write-BoxstarterMessage "Installing required features..."
  Install-WindowsFeature -Name Web-Server
  Install-WindowsFeature -Name Web-Http-Redirect
  Install-WindowsFeature -Name Web-Basic-Auth
  Install-WindowsFeature -Name Web-Client-Auth
  Install-WindowsFeature -Name Web-Cert-Auth
  Install-WindowsFeature -Name Web-Net-Ext45
  Install-WindowsFeature -Name Web-ASP
  Install-WindowsFeature -Name Web-Asp-Net45
  Install-WindowsFeature -Name Web-ISAPI-Ext
  Install-WindowsFeature -Name Web-ISAPI-Filter
  Install-WindowsFeature -Name Web-Ftp-Server
  Install-WindowsFeature -Name Web-Mgmt-Tools

#  Write-BoxstarterMessage "Removing unused features..."
#  Remove-WindowsFeature -Name 'Powershell-ISE'
#  Get-WindowsFeature | 
#  ? { $_.InstallState -eq 'Available' } | 
#  Uninstall-WindowsFeature -Remove
}

Install-WindowsUpdate -AcceptEula

Write-BoxstarterMessage "Removing page file"
$pageFileMemoryKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $pageFileMemoryKey -Name PagingFiles -Value ""

if(Test-PendingReboot){ Invoke-Reboot }

Write-BoxstarterMessage "Setting up winrm"
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow

$enableArgs=@{Force=$true}
try {
 $command=Get-Command Enable-PSRemoting
  if($command.Parameters.Keys -contains "skipnetworkprofilecheck"){
      $enableArgs.skipnetworkprofilecheck=$true
  }
}
catch {
  $global:error.RemoveAt(0)
}
Enable-PSRemoting @enableArgs
Enable-WSManCredSSP -Force -Role Server
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
Write-BoxstarterMessage "winrm setup complete"
