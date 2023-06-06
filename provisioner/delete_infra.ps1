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
	Remove-VM -VM "$ENV:RP_NAME" -Confirm:$false
    if ( $?)
    {
        break
    }
    Start-Sleep -Seconds 60
}
for($i = 0; $i -le 10; $i++)
{
	Remove-ResourcePool -ResourcePool "$ENV:RP_NAME" -Confirm:$false
    if ( $?)
    {
        break
    }
    Start-Sleep -Seconds 60
}