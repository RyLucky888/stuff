<#
    .Synopsis
        Given list of servers in csv file, check if each server exist in all the Vsphere hosts, if exist, extract 
        full DNS Hostname
    .Description
        This script read servers from csv file, check if each server exist in any of the VSphere hosts.
        If exist, extract Full DNSname of the server. It then extract just the domain name, write server name, Domain Name,
        IP address and App_Group to output.
    .Parameter
        $Datafile
        $saAccount
        $Outputfolder
    .Example
        Powershell .\getserverinfo_from_vspheres_1.ps1 "D:\stuff\servers.csv" "my_sa_account" ""D:\Working"
#>

#connecting to VCentrer
Import-Module VMWARE.PowerCLI
import-module -name VMware.VimAutomation.Core
Set-PowerCLIConfiguration -Scope User -ParticipateInCeip $true -DefaultVIServerMode Single -InvalidCertificateAction Ignore

#main function to do the work
function ReadData {
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [string] $Datafile,
        [string] $saAccount,
        [string] $OutputFolder
    )
    Begin{
        #Get-Credential to login to VSphere hosts
        $cred = Get-Credential -Message 'password' -UserName "$($saAccount)@domainname"
        #These are properties we need for output
        $properties = @("ServerName","DomainName","IP","App_Group")
        #this hashable object is used for PS Custom Object
        $hashobjproperties=@{}
        #get all servers
        $servers = Import-Csv -Path $Datafile
        #list of VCentre hosts
        $vmhosts = @("vmhost1","vmhost2","vmhost3")
    }#end Begin
    Process{
        foreach($srv in $servers){
            #this counter is used to check if the server doesn't exist in any of the vcentre hosts
            $count=0
            foreach($vmhost in $vmhosts){
                try{
                    #connect to vcentre host. wrap it in a try catch clock for error handle
                    $conn = Connect-VIServer -Credential $cred -Server $vmhost
                }#end try
                catch{
                    continue
                }#end catch
                try{
                    #Get VM object
                    $vm = Get-VM -Name $srv.ServerName -ErrorAction SilentlyContinue | select *
                    #get vm's guest
                    $vmguest = Get-VMGuest -VM $vm.Name | select *
                    $domainname= ([string]$vmguest.HostName).Substring(([string]$srv.ServerName).Length+1)
                    $hashobjproperties.ServerName = $srv.ServerName
                    $hashobjproperties.DomainName = $domainname
                    $hashobjproperties.IP=$srv.IP
                    $hashobjproperties.App_Group = $srv.App_Group
                    write-host $srv.ServerName " | " $domainname " | " $srv.IP
                    New-Object -TypeName PsCustomObject -Property $hashobjproperties | select $properties | Export-Csv "($OutputFolder)\output.csv" -NoTypeInformation -Append
                    $hashobjproperties.Clear()
                    break
                }
                catch {
                    Write-Host "Unable to find $($srv.ServerName) in $($vmhost)"
                    $count +=1
                    #if we exhaust all vcentre hosts the log it to error.txt
                    if ($count -ge $vmhosts.Length){
                        Add-Content -Path "$($OutputFolder)\error.txt" -Value $srv.ServerName
                    }
                    continue
                }
            }#end foreach $vmhost
        }#end foreach srv
    }#end Process
}#end ReadData

ReadData -Datafile "D:\Working\data_from_master_list.csv" -saAccount "SA_Account" -OutputFolder "D:\Working"