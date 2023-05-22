for($i = 0; $i -le 10; $i++)
{
    Connect-CIServer -Server "$Env:VCD_SERVER" -Org "$Env:VCD_ORG" -User "$Env:VCD_USER" -Pass "$Env:VCD_PASSWORD"
    if ( $?)
    {
        break
    }
    Start-Sleep -Seconds 60
}
for($i = 0; $i -le 10; $i++)
{
	# Stop-VApp  <VApp[]>[-Force][-RunAsync][-Server  <VIServer[]>][CommonParameters]
    Stop-CIVApp -VApp "$Env:VAPP_NAME" -Confirm:$false
    if ( $?)
    {
        break
    }
    Start-Sleep -Seconds 60
}
for($i = 0; $i -le 10; $i++)
{
	# Remove-VApp  <VApp[]>[-DeletePermanently][-RunAsync][-Server  <VIServer[]>][CommonParameters]
    Remove-CIVApp -VApp "$Env:VAPP_NAME" -Confirm:$false
    if ( $?)
    {
        break
    }
    Start-Sleep -Seconds 60
}