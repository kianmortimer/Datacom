<#

Title:   reverse_cessation_parse_html.ps1
Author:  kian.mortimer@datacom.com
Date:    06/06/24
Version: 1.1

Description: 
- Script to parse HTML content into AD groups during the reverse cessation process

How-to:
- During the reverse cessation process, we manually add each group back to the account
- by going to the MSP job and painstakingly going through each AD group and either 
- writing them out again, or copying individually from the HTML Inspect Element view.
- This script simplifies the process by allowing you to copy one HTML element from 
- the Inspect Element view and paste it into this script, instantly copying the 
- relevant AD group names to the clipboard.

Workflow:
- Go to MSP disable user job > Logs
- Find the "Current user AD groups" log and click "View Details"
- Right-click on the grey box with all the text > Inspect Element
- Right-click on the highlighted HTML element > Copy Element
- Run this script (The parsed data will be copied to the clipboard automatically)
- Go to user in AD and add groups > Paste content and check names
- Profit

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Reverse Cessation - Get AD Groups from MSP HTML Content"

# Print instructions to output
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host "* Reverse Cessation - Get AD Groups from MSP HTML Content         *"
Write-Host "* Copy HTML element from MSP job and paste it into this script    *"
Write-Host "* Formatted groups will be AUTOMATICALLY copied to the clipboard  *"
Write-Host "*                                                                 *"
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"

# The first loop will auto-paste whatever is in the clipboard
$first = $true

# The main loop, will keep repeating until script is terminated
:mainLoop while ($true) {
    Write-Host

    # Check whether this is the first loop
    if ($first) {
        $first = $false
        # If it's the first loop; auto-paste the content in the user's clipboard
        $user_input = Get-Clipboard | ForEach-Object -Process { if ($_) { $_.Trim() } }
        $user_input_substring = $user_input.Substring(0, [Math]::Min($user_input.Length, 500))
		Write-Host " Paste the HTML here: $user_input_substring ..."
    } else {
        # If it's not the first loop; get the user input normally
        $user_input = Read-Host " Paste the HTML here" | ForEach-Object -Process { if ($_) { $_.Trim() } }
    }

    # Check if there was any input; if not, go back to start of loop
    if (!$user_input) {
        Write-Host "`n >>> No groups found in pasted content`n"
        continue
    }

    # Separate the block of HTML into a list
    $parsed_groups = ($user_input.Trim() -split "(<br>)|(`">)").Trim()
	
    # Separate the list into the Distinguished Names of the groups
    # Distinguished Name example: CN=mem-dia-prd-winos-app-adobe-ccdesktop-deploy,OU=Devices,OU=Azure Services,OU=Groups,OU=Production,OU=Managed Objects,DC=dia,DC=govt,DC=nz;
    $groups_dn = $parsed_groups | Where-Object { ($_.Contains("CN=")) }
	
	# Format any outstanding HTML shenanigans
	$groups_dn = $groups_dn | ForEach-Object -Process { 
		$_.Replace("&amp;", "&").Replace("&lt;", "<").Replace("&gt;", ">").Replace("&nbsp;", " ").Replace('&quot;', '"').Replace("&apos;", "'")
	}
	
    # Simplify each group in the list into their Canonical Names
    # Canonical Name example: mem-dia-prd-winos-app-adobe-ccdesktop-deploy
    $groups_cn = $groups_dn | ForEach-Object -Process { ($_ -split ",")[0].Replace("CN=", "") }
	
    # Merge CN list into a single string to copy to the clipboard
    $groups_list = $groups_cn -join "`n"

    # Check whether any groups were found, otherwise copy placeholder "None" to the clipboard
    if (!$groups_list) {
        Write-Host "`n >>> No groups found in pasted content"
        Set-Clipboard "None"
    } else {
        # Copy the list to the clipboard and tell the user how many groups have been copied
        Set-Clipboard $groups_list
        Write-Host "`n >>> Copied $($groups_cn.count) groups to clipboard"
    }

}

# Insert grandma sunglasses gif here