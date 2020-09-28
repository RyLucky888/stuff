function RecursiveFn{
    <#
        .Synopsis
        .Description
    #>
    Param(
        $groupName,
        $zid
    )
    #$ouDN = (Get-ADOrganizationalUnit -SearchBase "DC=ad,DC=unsw,DC=edu,DC=au" -SearchScope Subtree -Filter {Name -eq $ou} -Properties * | select *).DistinguishedName
    Write-Host "searching for $($zid)"
    $objs = Get-ADGroupMember -Identity $groupName | select *
    foreach($obj in $objs){
        if ($obj.objectClass -eq "group"){
            RecursiveFn $obj.samAccountName $zid
        }
        else{
            Write-Host "$($obj.samAccountName) ---> $($groupName)"
            if($obj.samAccountName -eq $zid){
                Write-Host -ForegroundColor Yellow -Object "$($obj.samAccountName) is in $($groupName)"
                exit 0
            }#end if
        }#end else
    }#end foreach
}#end function

RecursiveFn -groupName $args[0] -zid $args[1]
