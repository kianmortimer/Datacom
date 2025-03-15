<#

Title:   get_names_upper.ps1
Author:  kian.mortimer@datacom.com
Date:    08/06/24
Version: 1.4

Description: 
- Script to get all the users with uppercase names

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Find Users With UPPERCASE Names"

Write-Host "`n > Searching Active Directory... "

# Get all users in AD that have names in full caps
# This will also return some non-human users (we will fix this later)
$results = Get-ADUser -Filter "ObjectClass -eq 'user'" | `
	Where-Object Name -cmatch "^[A-Z- ']+$"
# We use a regular expression "^[A-Z- ']+$" to achieve this
# Google regular expressions if you want to know how it works

# Check whether we found any users with caps names
if (!$results) {
	Write-Host " > No results found matching the criteria. `n"
	pause
	break
}

Write-Host " > Search completed -> ($($results.count)) total results found... "
Write-Host " > Filtering results... "	

# Get all of the attributes of the users we found
# (Default search only gives us a couple attributes, we want all of them)
$results = $results | ForEach-Object -Process { Get-ADUser -Identity $_.DistinguishedName -Properties * }
# We could have gotten all the attributes in the first search on line 17, but
# this would have increased the processing time astronomically, as it would be
# getting all attributes of all users, not just the users with full caps names

# Refine the results to only include real humans (the other results are
# mailboxes and other random accounts that are labelled as users)
$results_user = $results | Where-Object { 
	($_.HomeDrive -eq "H:") -and ($_.HomeDirectory -like "*home*") -and # Every human user has an H: drive
	($_.EmailAddress -like "*@*") -and ($_.l -like "?*") # Every human user has an email and location
}
# It's possible we haven't eliminated all the non-humans, 
# or accidentally eliminated a human, but we do our best

# Check whether any of the users we found are humans
if (!$results_user) {
	Write-Host " > No users found matching the criteria. `n"
	pause
	break
}

Write-Host " > Filter completed -> ($($results_user.count)) users found... "

# Create a hash table with the users' managers as the keys
# This is so that we can list the users by their manager (and call out any silly managers)
$managers = [ordered]@{}
$results_user | ForEach-Object -Process {
	if ($_.Manager) {
		# This is a meaty line, but it basically just associates a manager with their users
		[string[]]($managers[(Get-ADUser -Identity $_.Manager).Name]) += $_.Name
	} else {
		# If the user doesn't have a manager listed for some reason, assign them manager "[None]"
		[string[]]($managers["[None]"]) += $_.Name
	}
}

# Loop through the managers of the users and print them to the output
$managers.GetEnumerator() | Sort-Object -Property:Key | ForEach-Object -Process {
	Write-Host "`n Manager: $($_.Key)"
	$_.Value = $_.Value | Sort-Object
	foreach ($user in $_.Value) {
		Write-Host " - $user"
	}
}
Write-Host

pause

# RRRAAAAAAAAAAAAAAAAAAAAGGHHHHHHHHHHHHH
