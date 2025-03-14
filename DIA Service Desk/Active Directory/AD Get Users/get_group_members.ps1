<#

Title:   get_group_members.ps1
Author:  kian.mortimer@datacom.com
Date:    15/03/25
Version: 2.1

Description: 
- Script to get the members of an AD group
- Copies the list to the clipboard and generates a CSV

Workflow:
- Run this script and enter in the AD group you wish to get the members of
- For example: "MBX_tearatahi" would give you the list of users that have 
  access to that mailbox
- The list will automatically be copied to the clipboard (Wow!)
- A CSV file will also be generated

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Get Members of an AD Group"

# Print instructions to output
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host "* Get Members of an Active Directory Security Group           *"
Write-Host "* Enter the name of the AD group into the prompt below        *"
Write-Host "* Member list will be AUTOMATICALLY copied to the clipboard   *"
Write-Host "* A CSV file will also be generated with the results          *"
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
		$user_input_substring = $user_input.Substring(0, [Math]::Min($user_input.Length, 50))
		Write-Host  " Enter group name: $($user_input_substring)"
	} else {
		# If it's not the first loop; get the user input normally
		$user_input = Read-Host " Enter group name" | ForEach-Object -Process { if ($_) { $_.Trim() } }
	}
	
	# Try-catch to make sure that an appropriate AD group was given
	# This will also catch stupid searches such as "Domain Users" which have way too many members
	try {
		# Get the members and all their attributes from the specified AD group
		$members = Get-ADGroupMember -Identity "$user_input" | ForEach-Object -Process { 
			Get-ADObject -Identity $_.DistinguishedName -Properties * }
	} catch { # If the above function (Get-ADGroupMember) fails for any reason, it will be caught here
		# Advise the user, copy placeholder "None" to clipboard and go back to start of main loop
		Write-Host " > AD group `"$user_input`" not found.`n"
		"None" | Set-Clipboard
		continue
	}

    # If list is empty, advise user and copy placeholder "None" to clipboard
    if (!$members -or $members.count -lt 1) {
        Write-Host " > `"$user_input`" has no members.`n"
		"None" | Set-Clipboard
        continue
    }
	
	# Sort the member list alphabetically
	$members = $members | Sort-Object @{Expression = "ObjectClass"; Descending = $true},
                          @{Expression = "Name"; Descending = $false}
	
    # Initialise output variables
	$rows = [System.Collections.Generic.list[PSCustomObject]]::new()
    $members_string = ""

    # Format object properties
    foreach ($member in $members) {
        $object = [PSCustomObject]@{
            "Class" = $member.ObjectClass
            "Name" = $member.Name
            "Username" = $member.SAMAccountName
            "Email" = $member.mail
            "DistinguishedName" = $member.DistinguishedName
        }
        $rows.add($object)
        $members_string = $members_string + "$($member.Name)`n"
    }
    
    # Print output and copy list to clipboard
    Write-Host
    Write-Host " > ($($rows.count)) members`n"
	Write-Host $members_string
	$members_string | Set-Clipboard

    # Export to CSV
    Write-Host " > Exporting list..."
    $rows | Export-Csv -Path "C:\Users\sa-mortimki\Documents\Scripts\Active Directory\AD Get Users\Exported Member Lists\$($user_input) $(Get-Date -Format 'dd-MM-yy').csv" -NoTypeInformation
    Write-Host " >>> Exported Member Lists\$($user_input) $(Get-Date -Format 'dd-MM-yy').csv"

}

# Insert Eminem and Dr Dre headbanging in the lambo gif
