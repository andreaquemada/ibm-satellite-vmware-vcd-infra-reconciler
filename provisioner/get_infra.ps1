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
$a = Get-VM -Name "$Env:RP_NAME"
if (-not $?)
{
    exit
}
Write-Output success >> "$Env:INSTANCE_DATA"