<#

Title:   get_users_by_searchbase.ps1
Author:  kian.mortimer@datacom.com
Date:    13/03/25
Version: 1.1

Description:
- Script to get the users via a specific searchbase

Workflow:
- The list will be exported to a CSV

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Get Users By SearchBase"

# Print instructions to output
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host "* Get users via a specific SearchBase                   *"
Write-Host "* User list will be exported to CSV                     *"
Write-Host "*                                                       *"
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host

# Configure search
$searchbases = @("OU=Internal Employees,OU=Users,OU=Production,OU=Managed Objects,DC=dia,DC=govt,DC=nz",
				"OU=External Users,OU=Users,OU=Production,OU=Managed Objects,DC=dia,DC=govt,DC=nz",
				"OU=Synched,OU=External Users,OU=Users,OU=Production,OU=Managed Objects,DC=dia,DC=govt,DC=nz")
$searchbase = $searchbases[0]
$filters = @("*",
			"Name -like 'John*'",
            "Name -like 'John*' -and Enabled -eq 'True' -and Name -like '*n'")
$filter = $filters[2]

Write-Host " Search criteria:"
Write-Host $searchbase
Write-Host $filter

Write-Host
Write-Host "`n > Searching AD..."

# Try-catch to make sure that an appropriate search was given
try {
	# Search for users in AD with the specified search criteria field
	$members = Get-ADUser -Filter $filter -SearchBase $searchbase -Properties *
} catch { # If the above function (Get-ADUser) fails for any reason, it will be caught here
	# Advise the user and go back to start of main loop
	Write-Host " ! Error in search term`n"
	continue
}

 # Check if the member list is empty
if (!$members) {
	# If list is empty, advise user
	Write-Host " ! No users found`n"
	continue
} else {
	Write-Host " > ($($members.length)) users found"
}

Write-Host " > Formatting list..."

# Sort the member list alphabetically
$members = $members | Sort-Object -Property Name

# Initialize an array to store the results
$results = @()

# Only get user accounts
$members = $members | Where-Object { $_.ObjectClass -eq "user" }

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
$results | Export-Csv -Path ".\Exported Member Lists\Searchbase $(Get-Date -Format 'dd-MM-yy').csv" -NoTypeInformation
Write-Host " >>> Exported Member Lists\Searchbase $(Get-Date -Format 'dd-MM-yy').csv"


