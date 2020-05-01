<#
    .Synopsis
        map network drive to servers servers.csv file, then copy all required log files to device 42 shared location 
        that can be accessed by Dell support engineers.
    .Description
        First of all, it create Z: drive that map it to \\149.171.4.29\c$ (Device 42 servers)
        This script will enumerate though servers in servers.csv file, create network drive and map it to the 
        server's c$ admin share. It then go to \temp\D42Agent folder on teh server C: drive, copy all required log files and
        csv file to Z:\Temp\Logs\D42AgentV2 folder.
        Replace domain1 and domain2 with teh appropriate domain name of your environment and the username with your system acces account that
        has admin right to the servers
    .Paramater
        CSV file contains server names and domain and UNC path of teh device 42 server
    .Example
        Powershell .\d42script.ps1 .\servers.csv "\\192.168.1.100\c$"
    .Syntax
        Powershell .\d42script.ps1 <path to csv file> <unc of the device 42 server>
#>
# ------- Get Gredentials for addve01, adtest and unswadmin account -------------------
$dv42_cred = Get-Credential -Message "Password" -UserName "admin account"
$cred1 = Get-Credential -Message "Password" -UserName "domain1\username"
$cred2 = Get-Credential -Message "Password" -UserName "domain2\username"
#$adunsw_cred = Get-Credential -Message "Password" -UserName "domain3\username"

function mapD42{
    <#
        .Description
            This function map network drive "Z" to device 42 c$ admin share
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [string] $Root_Path,
        [string] $Drive
    )
    try{
        Write-Host "Mapping: " $Drive "to: " $Root_Path
        mapit -driveletter $Drive -rootpath $Root_Path -mycred $dv42_cred
    }
    catch{
        Write-Host $Error
    }
}#end mapD42

function mapit{
    <#
        .Description
            This function create network drive and map it to each server c$ admin share
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [string] $driveletter,
        [string] $rootpath,
        [PsCredential] $mycred
    )
    try{
        Write-Host "Mapping: " $driveletter "to: " $rootpath "with: " $mycred.UserName
        New-PSDrive -Name $driveletter -PSProvider FileSystem -Root $rootpath -Scope "Global" -Persist -Credential $mycred
    }#end try
    catch{
        Write-Host $Error
    }#end catch
}#end mapit function

function CopyLogs{
    <#
        .Description
            copy required log files from the server to device 42 server
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [string] $SourceFolder,
        [string] $TargetFolder
    )
    Get-ChildItem -Path $SourceFolder -Include ("*.csv","*.log") -Exclude "agent_local*" | Copy-Item -Destination $TargetFolder -Container -Force
    Start-Sleep -Seconds 5
}
function DoWork{
    <#
        .Description
            This is the entry point of teh script. It begin by checking if there exist a Z" drive, if there is, disconnect it
            It then remap Z: to the device 42 c$ admin share so we can copy log file to it
            after map it, delay the script execution for 15 seconds to give time for teh Z: drive to appear.
            the $driveletters array only consist of 15 driver letters for now as part of testing since we have 15 servers to be 
            connected to c$ admin share. go through csv file row by row, get server name and domain name, map drive accordingly,
            if the domain name is addev01 the use addev credential, if adtest then use adtest credential
            after map it, the call CopyLogs function to copy required log files
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [string]$CsvFile,
        [string]$D42Share
    )
    if (Get-PSDrive -LiteralName Z -Scope "Global" -PSProvider FileSystem){
        Remove-PSDrive -Name Z -PSProvider FileSystem -Scope "Global" -Force
    }
    mapD42 -Drive "Z" -Root_Path $D42Share
    Start-Sleep -Seconds 15
    #get PSDrive of Z:
    $tgdrive = Get-PSDrive -PSProvider FileSystem -Name Z
    #create target folder to store log files
    $targetfolder = $tgdrive.Root + "temp\Logs\D42AgentV2\"
    $driveletters = @("E","G","H","I","J","K","L","M","N","O","P","Q","R","S","T")
    $counter=0
    #get all servers from csv file
    $servers = Import-Csv -Path $CsvFile
    #This is the main works
    foreach($srv in $servers){
        $server = $srv.ServerName
        #This is the UNC path to server's c$ admin share
        $_path = "\\" + $server + "." + $srv.Domain + "\c$"
        #check domain name and use appropriate credential
        if ($srv."Domain" -eq "addev01.unsw.edu.au"){
            mapit -driveletter $driveletters[$counter] -mycred $addev_cred -rootpath $_path -Confirm:$false
        }#end if
        else{
            Write-Host $adtest_cred.UserName " ..." $adtest_cred.Password
            mapit -driveletter $driveletters[$counter] -mycred $adtest_cred -rootpath $_path -Confirm:$false
        }
        #after map network drive delay script's execution for 15 seconds for teh drive to stabalise and appear in Explorer
        Start-Sleep -Seconds 15
        #get PsDrive of the network drive we just mapped
        $srcdrive = Get-PSDrive -Name $driveletters[$counter] -PSProvider FileSystem -Scope "Global"
        # point to \Temp\D42Agent folder to get all log files
        $srcfolder = $srcdrive.Root + "temp\D42Agent\*"
        Write-Host "Copy log files from: " $srcfolder "to: " $targetfolder
        CopyLogs -SourceFolder $srcfolder -TargetFolder $targetfolder
        #get next drive letter from array
        $counter =$counter + 1
    }#end foreach
    #finally remove all network drive
    foreach($letter in $driveletters){
        Remove-PSDrive -Name $letter -PSProvider FileSystem -Scope "Global" -Force
    }
}#end DoWork()

#start here
DoWork -CsvFile ".\srcfolder\servers.csv" -D42Share "\\server_address\c$"

