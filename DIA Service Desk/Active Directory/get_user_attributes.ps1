<#

Title:   get_user_attributes.ps1
Author:  kian.mortimer@datacom.com
Date:    23/01/25
Version: 1.0

Description:
- Script to get all the attributes of a user and copy them to the clipboard

Workflow:
- Run this script and enter in the username of the user you wish to get the attributes for
- The list will automatically be copied to the clipboard (Wow!)

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Get User Attributes"

# Print instructions to output
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host "* Get Active Directory attributes of a user                     *"
Write-Host "* Enter the username of the user into the prompt below          *"
Write-Host "* Attribute list will be AUTOMATICALLY copied to the clipboard  *"
Write-Host "*                                                               *"
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host

# First loop will auto-paste the user's clipboard
$first = $true

# The main loop, will keep repeating until script is terminated
:mainLoop while ($true) {
	Write-Host
	
	# Check whether this is the first loop
	if ($first) {
		$first = $false
		# If it's the first loop; auto-paste the content in the user's clipboard
		$user_input = Get-Clipboard | ForEach-Object -Process { if ($_) { $_.Trim() } }
		$user_input_substring = $user_input.Substring(0, [Math]::Min($user_input.Length, 50))
		Write-Host  " Enter username: $($user_input_substring)"
	} else {
		# If it's not the first loop; get the user input normally
		$user_input = Read-Host " Enter username" | ForEach-Object -Process { if ($_) { $_.Trim() } }
	}
	
	# Try-catch to make sure that an appropriate username was given
	try {
		# Get the specified user
		$user = Get-ADUser -Identity "$user_input" -Properties *
	} catch { # If the above function (Get-ADUser) fails for any reason, it will be caught here
		# Advise the user, copy placeholder "None" to clipboard, and go back to start of main loop
		Write-Host " > User `"$user_input`" not found.`n"
		"None" | Set-Clipboard
		continue
	}

	Write-Host

    # Create custom object to store relevant information
    $user_object = [PSCustomObject]@{
        "Name" = $user.Name
        "Email" = $user.EmailAddress
        "Username" = $user.SamAccountName
        "Enabled" = $user.Enabled
        "OU" = $user.CanonicalName
        "Locked" = $user.LockedOut
        "Password Expired" = $user.PasswordExpired
        "Account Expires" = if ($user.AccountExpirationDate) { $user.AccountExpirationDate } else { "Never" }
        "Last Logon" = $user.lastLogonDate
        "Bad Password Count" = $user.badPwdCount
        "Bad Password Time" = $user.LastBadPasswordAttempt
        "Password Last Set" = $user.PasswordLastSet
        "Created" = $user.Created
        "Manager" = if ($user.Manager) { (Get-ADUser -Identity $user.Manager).Name } else { "" }
        "Office" = $user.Office
        "Title" = $user.Title
        "Department" = $user.Department
        "Company" = $user.Company
        "Cost Code" = $user.extensionAttribute2
        "Employment" = $user.extensionAttribute5
        
    }
	
	# Output the object as a list
    Write-Host ($user_object | Format-List -Force | Out-String)

}
