# vSphere command index: https://developer.vmware.com/docs/powercli/latest/products/vmwarevsphereandvsan/commands-index/
for($i = 0; $i -le 10; $i++)
{
 Connect-VIServer -Server $Env:VSP_SERVER -Protocol https -User "$Env:VSP_USER" -Password "$Env:VSP_PASSWORD"
 if ( $?)
 {
  break
 }
 Start-Sleep -Seconds 60
}
for($i = 0; $i -le 10; $i++)
{
 $Error.Clear()
 New-ResourcePool -Name "$Env:RP_NAME" -Location "$Env:VSP_LOCATION"
 if ( $?)
 {
  break
 }
 $erMsg = Write-Output $Error
 if ($erMsg -contains "already exists")
 {
  break
 }
 Start-Sleep -Seconds 60
}
for($i = 0; $i -le 10; $i++)
{
 $Error.Clear()
 New-VM -Name "$Env:RP_NAME" -Template "$Env:VSP_TEMPLATE" -ResourcePool "$Env:RP_NAME" -Datastore "$Env:VSP_DATASTORE"
 if ( $?)
 {
  break
 }
 $erMsg = Write-Output $Error
 if ($erMsg -contains "already exists")
 {
  break
 }
 Start-Sleep -Seconds 60
}
for($i = 0; $i -le 10; $i++)
{
 $Error.Clear()
 $memresize = [int]$Env:MEM_MB
 $cpuresize = [int]$Env:CPU
 Set-VM -VM "$ENV:RP_NAME" -MemoryGB $memresize -NumCPU $cpuresize -Confirm:$false
 if ( $?)
 {
  break
 }
 Start-Sleep -Seconds 60
}
for($i = 0; $i -le 10; $i++)
{
 New-HardDisk -VM "$Env:RP_NAME" -CapacityGB "$ENV:DISK_2_SIZE"
 if ( $?)
 {
  break
 }
 Start-Sleep -Seconds 60
}

$diskSizeItr = "$ENV:DISK_3_SIZE"
if (-Not (("$diskSizeItr" -eq $null) -or ("$diskSizeItr" -eq ""))){
 for($i = 0; $i -le 10; $i++)
 {
  New-HardDisk -VM "$Env:RP_NAME" -CapacityGB "$ENV:DISK_3_SIZE"
  if ( $?)
  {
   break
  }
  Start-Sleep -Seconds 60
 }
}

$diskSizeItr = "$ENV:DISK_4_SIZE"
if (-Not (("$diskSizeItr" -eq $null) -or ("$diskSizeItr" -eq ""))){
 for($i = 0; $i -le 10; $i++)
 {
  New-HardDisk -VM "$Env:RP_NAME" -CapacityGB "$ENV:DISK_4_SIZE"
  if ( $?)
  {
   break
  }
  Start-Sleep -Seconds 60
 }
}

$diskSizeItr = "$ENV:DISK_5_SIZE"
if (-Not (("$diskSizeItr" -eq $null) -or ("$diskSizeItr" -eq ""))){
 for($i = 0; $i -le 10; $i++)
 {
  New-HardDisk -VM "$Env:RP_NAME" -CapacityGB "$ENV:DISK_5_SIZE"
  if ( $?)
  {
   break
  }
  Start-Sleep -Seconds 60
 }
}

for($i = 0; $i -le 10; $i++)
{
 $Error.Clear()
 Start-VM -VM "$ENV:RP_NAME" -Confirm
 if ( $?)
 {
  break
 }
 Start-Sleep -Seconds 60
}

# TODO need to see format here and find a way to make the an environment variable back into our terminal
Write-Output (Get-VM -Name "$ENV:RP_NAME").Guest.IPAddress >> "$Env:VM_IP_ADDRESS_FILE"
