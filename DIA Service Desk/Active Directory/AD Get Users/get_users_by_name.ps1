<#

Title:   get_users_by_name.ps1
Author:  kian.mortimer@datacom.com
Date:    14/03/25
Version: 2.1

Description:
- Script to get the users by their names
- This is for when we need their emails or something but only have names

Workflow:
- The list will be exported to a CSV

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Get Users By Name"

# Print instructions to output
Write-Host "* * * * * * * * * * * * * * * * * * * * *"
Write-Host "* Get users via their names             *"
Write-Host "* User list will be exported to CSV     *"
Write-Host "*                                       *"
Write-Host "* * * * * * * * * * * * * * * * * * * * *"
Write-Host

# Configure search
$only_enabled = $true

$first = $true
# The main loop, will keep repeating until script is terminated
:mainLoop while ($true) {
	Write-Host
	
	# Check whether this is the first loop
	if ($first) {
		$first = $false
		# If it's the first loop; auto-paste the content in the user's clipboard
		$user_input = Get-Clipboard | ForEach-Object -Process { if ($_) { $_.Trim() } }
		Write-Host  " Enter names: $($user_input)"
	} else {
		# If it's not the first loop; get the user input normally
		$user_input = Read-Host " Enter names" | ForEach-Object -Process { if ($_) { $_.Trim() } }
	}
    
    # convert input into a list of names
    $names = $user_input -split "`n"

    Write-Host
    Write-Host " > Searching AD..."
    Write-Host

    # Loop through the names, finding the relevant accounts
    $results = @{}
    $members = @{}
    $email_list = ""
    foreach ($name in $names) {
        
        # Get distinguished names of the accounts
        if ($only_enabled) { $results["$name"] = (Get-ADUser -Filter "Name -eq '$name' -and Enabled -eq 'True'" -Properties *) }
        else { $results["$name"] = (Get-ADUser -Filter "Name -eq '$name'" -Properties *) }
        
        # If the search found more than 1 account
        if ($results["$name"].length -gt 1) {
            $results["$name"] = $null # Just disregard the accounts
        }

        # Get account objects from the found distinguished names
        try {
            $members["$name"] = Get-ADUser -Identity $results["$name"] -Properties *
            # Collect the emails separately also to print to user
            $email_list += $($members["$name"].EmailAddress + "`n") 
        } catch {
            $members["$name"] = $null
            $email_list += "`n"
        }

    }

    # Copy the collected emails to the clipboard and print them out
    if ($email_list) { $email_list | Set-Clipboard } else { "None" | Set-Clipboard }
    Write-Host $email_list

    Write-Host " > Formatting list..."
    Write-Host

    # Initialise generic list (mutable)
    # This is much faster than an array when given a large number of items
    $rows = [System.Collections.Generic.List[PSCustomObject]]::new()

    # Loop through each name
    foreach ($name in $names) {
        $member = $members["$name"]
        # Initialize an object to store the user's information
        $user_object = [PSCustomObject]@{
	        "Name" = $name
	        "Username" = if ($member) { $member.SAMAccountName } else { $null }
	        "Email Address" = if ($member) { $member.EmailAddress } else { $null }
	        "Department" = if ($member) { $member.Department } else { $null }
	        "Company" = if ($member) { $member.Company } else { $null }
	        "Business Unit" = if ($member) { $member.Description } else { $null }
	        "Manager" = if ($member -and $member.Manager) { (Get-ADUser -Identity $member.Manager).Name } else { $null }
	        "Direct Reports" = ""
        }

        # If the user has direct reports, get their names and add them to the object
        $direct_reports = $null
        $direct_reports = if ($member) { Get-ADUser -Filter {Manager -eq $member.DistinguishedName} -Properties Manager | Select-Object -ExpandProperty Name } else { $null }
        if ($direct_reports) {
	        $user_object."Direct Reports" = $direct_reports -join ","
        }

        # Add the object to the results array
        $rows.Add($user_object)
    }

    # Export to CSV
    Write-Host " > Exporting list..."
    $rows | Export-Csv -Path "C:\Users\sa-mortimki\Documents\Scripts\Active Directory\AD Get Users\Custom\Exported Member Lists\Users By Name $(Get-Date -Format 'dd-MM-yy').csv" -NoTypeInformation
    Write-Host " >>> Exported Member Lists\Users By Name $(Get-Date -Format 'dd-MM-yy').csv"

}

# wait a minute... who ARE you?