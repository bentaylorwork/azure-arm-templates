configuration VMad
{
   param
   (
        [Parameter(Mandatory = $true)]
        [String]
        $DomainName,
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Admincreds,
        [Parameter(Mandatory = $false)]
        [string]
        $driveLetter = 'F',
        [Parameter(Mandatory = $false)]
        [string]
        $diskPrefix = 'Data',
        [Parameter(Mandatory = $false)]
        [Int]
        $RetryCount = 20,
        [Parameter(Mandatory = $false)]
        [Int]
        $RetryIntervalSec = 30
    )

    Import-DscResource -ModuleName xActiveDirectory, xNetworking, PSDesiredStateConfiguration, xPendingReboot
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

	    WindowsFeature DNS
        {
            Ensure = "Present"
            Name   = "DNS"
        }

        Script EnableDNSDiags
	    {
      	    SetScript = {
		        Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics"
            }
            GetScript =  {
                @{}
            }
            TestScript = {
                $false
            }
	        DependsOn = "[WindowsFeature]DNS"
        }

        Script CreateStoragePool {
            GetScript = {
                return @{
                    Result     = ((Test-Path ($USING:driveLetter+':')) -and (Get-StoragePool -FriendlyName ($USING:diskPrefix + '-Pool')))
                    GetScript  = $GetScript
                    TestScript = $TestScript
                    SetScript  = $SetScript
                }
            }

            TestScript = {
                if ((Test-Path ($USING:driveLetter+':')) -and (Get-StoragePool -FriendlyName ($USING:diskPrefix + '-Pool')))
                {
                    Write-Verbose -Message 'Storage Space exists so not creating.'
                    $True
                }
                Else
                {
                    Write-Verbose -Message 'Storage Space exists so creating.'
                    $False
                }
            }

            SetScript = {
                $PhysicalDisks = Get-PhysicalDisk -CanPool $True
                New-StoragePool -FriendlyName ($USING:diskPrefix + '-Pool') -PhysicalDisks $PhysicalDisks -StorageSubsystemFriendlyName *Storage* |
                New-VirtualDisk -FriendlyName ($USING:diskPrefix + '-Disk') -UseMaximumSize -NumberOfColumns $PhysicalDisks.Count -ResiliencySettingName 'Simple' -ProvisioningType Fixed -Interleave 65536 |
                Initialize-Disk -Confirm:$False -PassThru |
                New-Partition -UseMaximumSize -DriveLetter $USING:driveLetter |
                Format-Volume -FileSystem NTFS -NewFileSystemLabel ($USING:diskPrefix + '-Volume') -AllocationUnitSize 64KB -Confirm:$False
            }
	        DependsOn = "[WindowsFeature]DNS"
        }

	    WindowsFeature DnsTools
	    {
	        Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
	    }

        xDnsServerAddress DnsServerAddress
        {
            Address        = '127.0.0.1'
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
	        DependsOn      = "[WindowsFeature]DNS"
        }

        WindowsFeature ADDSInstall
        {
            Ensure    = "Present"
            Name      = "AD-Domain-Services"
	        DependsOn ="[WindowsFeature]DNS"
        }

        WindowsFeature ADDSTools
        {
            Ensure    = "Present"
            Name      = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure    = "Present"
            Name      = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xADDomain FirstDS
        {
            DomainName                    = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath                  = ('{0}:\NTDS' -f $driveLetter)
            LogPath                       = ('{0}:\NTDS' -f $driveLetter)
            SysvolPath                    = ('{0}:\SYSVOL' -f $driveLetter)
	        DependsOn                     = "[Script]CreateStoragePool"
        }

        <#
        xADOrganizationalUnit OUDomainMembers
        {
           Name                            = 'Domain Members'
           Path                            = (-join ('DC=', ($DomainName.split('.') -join ', DC=')))
           ProtectedFromAccidentalDeletion = $true
           Description                     = 'Auto Created From Install'
           Ensure                          = 'Present'
           DependsOn                       = "[xADDomain]FirstDS"
        }
        #>
   }
}