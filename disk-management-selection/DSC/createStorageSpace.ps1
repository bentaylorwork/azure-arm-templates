Configuration CreateStorageSpace
{
   param             
    (             
        [Parameter(Mandatory = $false)]             
        [string]
        $driveLetter = 'F',
        [Parameter(Mandatory = $false)]             
        [string]
        $diskPrefix = 'Data'        
    )

    Node localhost
    {
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
                New-StoragePool -FriendlyName ($USING:diskPrefix + '-Pool') -PhysicalDisks $PhysicalDisks –StorageSubsystemFriendlyName "*Storage*" |
                New-VirtualDisk -FriendlyName ($USING:diskPrefix + '-Disk') -UseMaximumSize -NumberOfColumns $PhysicalDisks.Count -ResiliencySettingName 'Simple' -ProvisioningType Fixed -Interleave 65536 |
                Initialize-Disk -Confirm:$False -PassThru |
                New-Partition -UseMaximumSize -DriveLetter $USING:driveLetter |
                Format-Volume -FileSystem NTFS -NewFileSystemLabel ($USING:diskPrefix + '-Volume') -AllocationUnitSize 64KB -Confirm:$False
            }
        }   
    }
}