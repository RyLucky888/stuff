Import-Module MicrosoftTeams
Import-Module SkypeOnlineConnector
Import-Module -Name AzureADPreview
Import-Module -Name Microsoft.Online.SharePoint.PowerShell
Import-Module ExchangeOnlineManagement

function InitOff365{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [string] $SA,
        [string] $ConnectionURI
    )
    $sessionOptions = New-PSSessionOption -IdleTimeout 10000000
    $mycred = Get-Credential -Message "Off 365 admin account" -UserName "$($SA)@ad.unsw.edu.au"
    $msoService = Connect-MsolService -Credential $mycred
    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ConnectionURI -Credential $mycred `
                             -Authentication Basic -AllowRedirection -SessionOption $sessionOptions
    $sfbSession = New-CsOnlineSession -Credential $mycred -SessionOption $sessionOptions
    Import-PSSession $session -AllowClobber
    Import-PSSession -Session $sfbSession -AllowClobber
    Connect-AzureAD -Credential $mycred
    Connect-MicrosoftTeams -Credential $mycred
    Connect-MsolService -Credential $mycred
    Connect-ExchangeOnline -Credential $mycred
}

#InitOff365 -SA "z3226656_sa" -ConnectionURI "https://ps.outlook.com/powershell/"
InitOff365 -SA "z3226656_sa" -ConnectionURI "https://outlook.office365.com/powershell-liveid/"
