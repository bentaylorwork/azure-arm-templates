configuration VMrds
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $domainName,
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $adminCreds,
        [Parameter(Mandatory = $false)]
        [String]
        $collectionName = 'Collection',
        [Parameter(Mandatory = $false)]
        [String]
        $collectionDescription = 'This is a default session collection',
        [Parameter(Mandatory = $false)]
        [string]
        $driveLetter = 'F',
        [Parameter(Mandatory = $false)]
        [string]
        $diskPrefix = 'Data'
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xRemoteDesktopSessionHost

    $localhost   = [System.Net.Dns]::GetHostByName($env:computerName).hostname
    $domainCreds = New-Object System.Management.Automation.PSCredential ("$domainName\$($adminCreds.UserName)", $adminCreds.Password)
        
    Node "localhost"
    {
   
        LocalConfigurationManager
        {
            RebootNodeIfNeeded   = $true
        }
        
        WindowsFeature Remote-Desktop-Services
        {
            Ensure = "Present"
            Name   = "Remote-Desktop-Services"
        }
        
        WindowsFeature RDS-RD-Server
        {
            Ensure = "Present"
            Name   = "RDS-RD-Server"
        }
        
        WindowsFeature RSAT-RDS-Tools
        {
            Ensure               = "Present"
            Name                 = "RSAT-RDS-Tools"
            IncludeAllSubFeature = $true
        }
        
        WindowsFeature RDS-Connection-Broker
        {
            Ensure = "Present"
            Name   = "RDS-Connection-Broker"
        }

        WindowsFeature RDS-Web-Access
        {
            Ensure = "Present"
            Name   = "RDS-Web-Access"
        }

        WindowsFeature RDS-Licensing
        {
            Ensure = "Present"
            Name   = "RDS-Licensing"
        }

        WindowsFeature RDS-Gateway
        {
            Ensure = "Present"
            Name = "RDS-Gateway"
        }
        
        xRDSessionDeployment Deployment
        {
            SessionHosts         = @( $localHost )
            ConnectionBroker     = $localHost
            WebAccessServer      = $localHost
            DependsOn            = "[WindowsFeature]Remote-Desktop-Services", "[WindowsFeature]RDS-RD-Server", "[WindowsFeature]RDS-Connection-Broker", "[WindowsFeature]RDS-Web-Access"
            PsDscRunAsCredential = $domainCreds
        }
        
        xRDSessionCollection Collection
        {
            CollectionName        = $collectionName
            CollectionDescription = $collectionDescription
            SessionHosts          = @( $localHost )
            ConnectionBroker      = $localHost
            DependsOn             = "[xRDSessionDeployment]Deployment"
            PsDscRunAsCredential  = $domainCreds
        }

        xRDSessionCollectionConfiguration CollectionConfiguration
        {
            CollectionName                = $collectionName
            CollectionDescription         = $collectionDescription
            ConnectionBroker              = $localHost
            TemporaryFoldersDeletedOnExit = $false
            SecurityLayer                 = "SSL"
            DependsOn                     = "[xRDSessionCollection]Collection"
            PsDscRunAsCredential          = $domainCreds
        }

        xRDLicenseConfiguration LicenseConfiguration
        {
            ConnectionBroker     = $localHost
            LicenseServers       = @( $localHost )
            LicenseMode          = 'PerUser'
            DependsOn            = "[xRDSessionDeployment]Deployment"
            PsDscRunAsCredential = $domainCreds
        }

        xRDRemoteApp Calc
        {
            CollectionName       = $collectionName
            DisplayName          = "Calculator"
            FilePath             = "C:\Windows\System32\calc.exe"
            Alias                = "calc"
            DependsOn            = "[xRDSessionCollection]Collection"
            PsDscRunAsCredential = $domainCreds
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
        }
    }
}