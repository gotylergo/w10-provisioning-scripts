# Config variables
$DCserver = Read-Host "What Active Directory Domain Controller should we be working on?"

# Get Input to Define Variables

$NameLast = Read-Host 'User Last Name'
$NameFirst = Read-Host 'User First Name'
$NameLookup = "*$NameLast* *$NameFirst*"

# Search for user in AD
$ADUser = Get-ADuser -Filter { name -like $NameLookup } -Server ($DCserver) | Select-Object name, samaccountname | Sort-Object samaccountname
if ($?) {
    Write-Host "Found user: $ADUser"
    Pause
}
else {
    EXIT
}
$Username = $ADuser.samaccountname
Write-Host "Found user: $Username"

# Declare Create-Password function
# Credit iRon: https://stackoverflow.com/questions/37256154/powershell-password-generator-how-to-always-include-number-in-string
Function MakeUp-String([Int]$Size = 16, [Char[]]$CharSets = "ULNS", [Char[]]$Exclude) {
    $Chars = @(); $TokenSet = @()
    If (!$TokenSets) {
        $Global:TokenSets = @{
            U = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'                                #Upper case
            L = [Char[]]'abcdefghijklmnopqrstuvwxyz'                                #Lower case
            N = [Char[]]'0123456789'                                                #Numerals
            S = [Char[]]'!"#$%&''()*+,-./:;<=>?@[\]^_`{|}~'                         #Symbols
        }
    }
    $CharSets | ForEach {
        $Tokens = $TokenSets."$_" | ForEach { If ($Exclude -cNotContains $_) { $_ } }
        If ($Tokens) {
            $TokensSet += $Tokens
            If ($_ -cle [Char]"Z") { $Chars += $Tokens | Get-Random }             #Character sets defined in upper case are mandatory
        }
    }
    While ($Chars.Count -lt $Size) { $Chars += $TokensSet | Get-Random }
    ($Chars | Sort-Object { Get-Random }) -Join ""                                #Mix the (mandatory) characters and output string
}; Set-Alias Create-Password MakeUp-String -Description "Generate a random string (password)"

# Reset password
$termPwd = Create-Password
Set-ADAccountPassword -Server $DCserver -Identity $Username -NewPassword (ConvertTo-SecureString -AsPlainText $termPwd -Force)
if ($?) {
    Write-Host "Password reset to: $termPwd"
}
else {
    Write-Host "User password could not be changed to: $termPwd"
    Read-Host -Prompt "Change the term's password to this manually. Then press Enter to continue"
}

# Remove AD Groups

Write-Host "Backing up AD groups..."

Get-ADPrincipalGroupMembership -Server $DCserver ABarcelo | select name | export-csv "ABarcelo-groups.csv"
Write-Output "Backed up to $Username-groups.csv"

if ($?) {
    # $Groups = Import-csv "$Username-groups.csv"
    foreach ($Group in $Groups) {
        # Remove-ADGroupMember -Server $DCserver -Identity $Group -Members $Username
        Write-Output "Group $Group removed."
    }
} else {
    Write-Output "Couldn't backup/remove groups. Try manually."
}
