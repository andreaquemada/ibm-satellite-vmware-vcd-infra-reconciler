# ibm-satellite-wmware-vcp-infra-reconciler
Reconciles desired state of a Satellite Location plus downstream clusters for vmware on vSphere 7.0+

It requires:
- powershell to be installed: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.3
- VMWARE PowerCLI:  https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.esxi.install.doc/GUID-F02D0C2D-B226-4908-9E5C-2E783D41FE2D.html
- VMWARE vSphere Command index: https://developer.vmware.com/docs/powercli/latest/products/vmwarevsphereandvsan/commands-index/

### Connecting to the vSphere environment using PowerShell

#### Install Dependencies
1. `Install-Module -Name VMware.PowerCLI -AllowClobber -Force`
2. `Set-ExecutionPolicy RemoteSigned -Force`
3. `Import-Module VMware.VimAutomation.Core -Force`
4. `Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Force`

#### Connect using user/password
1. Populate the `config.env` and source it `source config.env`
2. `Connect-VIServer -Server $Env:VSP_SERVER -Protocol https -User "$Env:VSP_USER" -Password "$Env:VSP_PASSWORD"`

### Assumptions

#### VM Template

- ssh key and/or user/password is already setup on the template to allow remote execution of attach script
- template is using the same network that is intended to be used in the automation
- DHCP server is already setup and configure within the template
- Template has 1 disk that is 25GB

#### General

- DHCP server is set up for dynamic IP allocation
- Single Datastore for all disk usage
- Single Location where all resource pools will be kept

### TODO

- Need to run full End to End execution of the scripts to ensure proper syntax.
- Should look into cloud-init instead of using ssh/scp to copy attach script