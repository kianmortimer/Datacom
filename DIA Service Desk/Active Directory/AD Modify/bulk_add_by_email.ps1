$users = Import-Csv "C:\Temp\Saniya\IMCU Final.csv" -Header "Email"

$errors = @()

foreach ($email in $users.Email) {
    $email = $email.Trim()
    #Write-Host $email
    try {
	    $user = Get-ADUser -Filter "EmailAddress -eq ""$email"""
        #Write-Host $user.SAMAccountName
        Add-ADGroupMember -Identity "mem-dia-prd-winos-app-avepoint-office-connect-addin-deploy" -Members $user -WhatIf
    }
    catch {
        #Write-Host "Error on user: $($email)"
        $errors += $email
    }
}

Write-Host
Write-Host "Errors: ($($errors.length))"
foreach ($email in $errors) {
    Write-Host $email
}
