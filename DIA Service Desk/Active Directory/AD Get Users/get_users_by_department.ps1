<#

Title:   get_users_by_department.ps1
Author:  kian.mortimer@datacom.com
Date:    23/01/25
Version: 1.0

Description:
- Script to get the users from a specific department

Workflow:
- Run this script and enter in the name of the department you wish to get the users of
- The list will be exported to a CSV

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Get Users By Attribute - Department"

# Print instructions to output
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host "* Get users of a specific Department in AD                    *"
Write-Host "* Enter the name of the department into the prompt below      *"
Write-Host "* User list will be exported to CSV                           *"
Write-Host "*                                                             *"
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
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
		$user_input_substring = $user_input.Substring(0, [Math]::Min($user_input.Length, 100))
		Write-Host  " Enter Department: $($user_input_substring)"
	} else {
		# If it's not the first loop; get the user input normally
		$user_input = Read-Host " Enter Department" | ForEach-Object -Process { if ($_) { $_.Trim() } }
	}

    Write-Host "`n > Searching AD..."
	
	# Try-catch to make sure that an appropriate department was given
	try {
		# Search for users in AD with the specified Department field
        $members = Get-ADUser -Filter "Department -like ""$($user_input)""" -Properties *
	} catch { # If the above function (Get-ADUser) fails for any reason, it will be caught here
		# Advise the user and go back to start of main loop
		Write-Host " ! Department `"$user_input`" not found.`n"
		continue
	}

     # Check if the member list is empty
	if (!$members) {
		# If list is empty, advise user
		Write-Host " ! AD Department `"$user_input`" has no members.`n"
        continue
	} else {
		Write-Host " > ($($members.length)) members of $($user_input)"
	}

    Write-Host " > Formatting list..."

    # Sort the member list alphabetically
	$members = $members | Sort-Object -Property Name
 
    # Initialize an array to store the results
    $results = @()
 
    # Loop through each user
    foreach ($member in $members) {
       # Initialize an object to store the user's information
       $user_object = [PSCustomObject]@{
            "Name" = $member.Name
            "Username" = $member.SAMAccountName
            "Email Address" = $member.EmailAddress
            "Enabled" = $member.Enabled
            "Department" = $member.Department
            "Company" = $member.Company
            "Business Unit" = $member.Description
            "Manager" = if ($member.Manager) { (Get-ADUser -Identity $member.Manager).Name } else { "" }
            "Direct Reports" = ""
       }
 
       # If the user has direct reports, get their names and add them to the object
       $direct_reports = Get-ADUser -Filter {Manager -eq $member.DistinguishedName} -Properties Manager | Select-Object -ExpandProperty Name
       if ($direct_reports) {
           $user_object."Direct Reports" = $direct_reports -join ","
       }
 
       # Add the object to the results array
       $results += $user_object
    }

    Write-Host " > Exporting list..."

	# Export to CSV
	$results | Export-Csv -Path ".\Exported Member Lists\Department $($user_input) $(Get-Date -Format 'dd-MM-yy').csv" -NoTypeInformation
	Write-Host " >>> Exported Member Lists\Department $($user_input) $(Get-Date -Format 'dd-MM-yy').csv"

}

