<#

Title:   get_group_members_multi.ps1
Author:  kian.mortimer@datacom.com
Date:    02/07/24
Version: 3.0

Description: 
- Script to get the members of multiple AD groups and write them to an Excel Spreadsheet
- Spreadsheet is a CSV file - plain text file that Jumphost can write to and Excel can read
- It is Tab delimited and not Comma delimited as commas won't automatically populate to
- new columns in Excel without you telling it to (I don't know why, it makes no sense)

How-to:
- Ever been asked for a list of users that have access to a mailbox?
- This script aims to make the process easier by eliminating the need 
- to copy the members individually from Active Directory.

Workflow:
- Talk to me, as the script will need to be copied and edited to get the groups you want
- A CSV containing all the groups will be created, alongside individual CSVs for the groups

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Get Members of Multiple AD Groups"

# Print instructions to output
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host "* Get Members of Multiple Active Directory Security Groups    *"
Write-Host "* Member lists will be written to CSV for use with Excel      *"
Write-Host "*                                                             *"
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host

# These are the AD groups needing to be searched
$ad_groups = "lic-dia-ent-vop-o365"
$title = "Visio Licenses at Digital Public Service (DPS)"

# Format CSV fields
$fields = "ID`tName`tEmail`tUsername`tType`tActive`tLast Activity`tGroup`tCost Centre`n"

$global_count = 1
$global_string = $fields

# The main loop, will repeat until all groups accounted for
foreach ($ad_group in $ad_groups) {
	
	Write-Host "`n > Searching AD group members... [$ad_group]"
	
	# Try-catch to make sure that an appropriate AD group was given
	# This will also catch stupid searches such as "Domain Users" which have way too many members
	try {
		# Get the members and all their attributes from the specified AD group
		$members = Get-ADGroupMember -Identity "$ad_group" | ForEach-Object -Process { 
			Get-ADObject -Identity $_.DistinguishedName -Properties * }
	} catch { # If the above function (Get-ADGroupMember) fails for any reason, it will be caught here
		# Advise the user and go back to start of main loop
		# Nothing from this group will be added to the CSVs
		Write-Host " ! AD group $ad_group not found.`n"
		continue
	}
	
	Write-Host " > Sorting list..."
	
	# Sort the member list alphabetically
	$members = $members | Sort-Object -Property Name

    # Filter the users by a specific criteria
    $members = $members | Where-Object { $_.Company -eq "Digital Public Service" }
	
	# Split the member list into users and any other members
	$members_user = $members | Where-Object { $_.ObjectClass -eq "user" }
	$members_other = $members | Where-Object { $_.ObjectClass -ne "user" }
	
	# Format the list to output
	$members_string = $fields
	
	# Counter for listing the members
	$count = 1
	
	Write-Host " > Formatting list... [Users]"

    # DateTime format
    $datetime_format = "dd/MM/yyyy  HH:mm:ss"
	
	# Put users into the list
	foreach ($user in $members_user) {
		$user = Get-ADUser -Identity $user.DistinguishedName -Properties *
		# Get the last logon date
		# If there is an attribute containing a FileTime, use that and convert it,
		# otherwise take a date from one of the other attributes
		$last_logon = if ($user.LastLogon) { 
				[datetime]::FromFileTime($user.LastLogon).ToString($datetime_format) }
			elseif ($user.LastLogonTimestamp) { 
				[datetime]::FromFileTime($user.LastLogonTimestamp).ToString($datetime_format) }
			elseif ($user.LastLogonDate) { $user.LastLogonDate } 
			elseif ($user.Modified) { $user.Modified }
			elseif ($other.WhenChanged) { $other.WhenChanged }
			else { "" }
		# Format object properties into CSV record
		$results = "`t$($user.Name)`t$($user.EmailAddress)`t$($user.SAMAccountName)`t$($user.ObjectClass)`t$($user.Enabled)`t$($last_logon)`t$($ad_group)`t$($user.extensionAttribute2)`n"
		# Add to the CSV for this group
		$members_string = $members_string + $count + $results 
		$count ++
		# Add to the master CSV
		$global_string = $global_string + $global_count + $results 
		$global_count++
	}
	
	Write-Host " > Formatting list... [Objects]"
	
	# Put other member types into list if applicable
	if ($members_other.count -gt 0) {
		foreach ($other in $members_other) {
			# Get the last logon date
			# If there is an attribute containing a FileTime, use that and convert it,
			# otherwise take a date from one of the other attributes
			$last_logon = if ($user.LastLogon) { 
					[datetime]::FromFileTime($user.LastLogon).ToString($datetime_format) }
				elseif ($user.LastLogonTimestamp) { 
					[datetime]::FromFileTime($user.LastLogonTimestamp).ToString($datetime_format) }
				elseif ($user.LastLogonDate) { $user.LastLogonDate } 
				elseif ($user.Modified) { $user.Modified }
				elseif ($other.WhenChanged) { $other.WhenChanged }
				else { "" }
			# Format object properties into CSV record
			$results = "`t$($other.Name)`t`t`t$($other.ObjectClass)`t`t$($last_logon)`t$($ad_group)`t$($other.extensionAttribute2)`n"
			# Add to the CSV for this group
			$members_string = $members_string + $count + $results
			$count ++
			# Add to the master CSV
			$global_string = $global_string + $global_count + $results
			$global_count++
		}
	}
	
	Write-Host " > Exporting list..."
	
	# Check if the member list is empty
	if (!$members_string) {
		# If list is empty, advise user
		Write-Host " ! AD group $ad_group has no members.`n"
	} else {
		# If list is not empty, export to CSV
		$members_string > "Exported Member Lists\$($ad_group) $(Get-Date -Format 'dd-MM-yy').csv"
		Write-Host " >>> Exported Member Lists\$($ad_group) $(Get-Date -Format 'dd-MM-yy').csv"
	}
}

Write-Host "`n > Exporting global list..."
$global_string > "Exported Member Lists\$($title) $(Get-Date -Format 'dd-MM-yy').csv"
Write-Host " >>> Exported Member Lists\$($title) $(Get-Date -Format 'dd-MM-yy').csv"
Write-Host
pause

# Insert Eminem and Dr Dre headbanging in the lambo gif