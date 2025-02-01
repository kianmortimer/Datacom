<#

Title:   loginstats_history.ps1
Author:  kian.mortimer@datacom.com
Date:    06/08/24
Version: 5.1

Description: 
- Script to find the most recent logins of DIA user or device
- Search by username or device name (e.g. "mortimki" or "T111A-LXXXXXXXX")
- The search is not case-sensitive (e.g. "mortimki" == "MORTIMKI")
- The search will return the username, device name, and more

Warning:
- Make any changes to this script at your own risk; PowerShell is OP
- This script does not make any changes or modifications, it only reads
- This script can be safely terminated at any stage by closing the window, 
- or using the KeyboardInterrupt shortcut "Ctrl+C"

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Get login history from loginstats.txt"

# Set the file path of loginstats.txt
$file_path = "\\wlgprdfile02\audit$\capturestatistics\loginstats.txt"

### GET STATISTICS ###

# Print statistics to output
$file_stats = Get-Item -Path $file_path
Write-Host
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host "* File: $($file_stats.name)"
Write-Host "* Size: $((([double]($file_stats.length))/1024/1024).ToString('0,0.00'))MB"
Write-Host "* Date: $($file_stats.lastwritetime)"
Write-Host "*"

# Print instructions to output
Write-Host "* Search by username or device name [case-insensitive]"
Write-Host "* Gets the login history of the specified user or device"
Write-Host "* Note: right-click to paste in this window"
Write-Host "*"
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"

### START SEARCH ###

# The first loop will auto-paste whatever is in the clipboard
$first = $true

# Start of loop
:mainLoop while ($true) {
    Write-Host "*"

    # If it's the first loop, take the user's clipboard as their input
    if ($first) {
        $user_input = Get-Clipboard | ForEach-Object -Process { if ($_) {$_.Trim()} }
		if (!$user_input) {$user_input = "No Content in Clipboard"}
        Write-Host "* Search: $user_input"
        $first = $false
    } else { # Else, let them enter their own input
        $user_input = Read-Host "* Search" | ForEach-Object -Process {$_.Trim()}
    }
    
    # Determine the search term pattern
    # This is based on how loginstats.txt is formatted
    # If we search "mortimki" we don't want to find "mortimki2" also
    $search_term = ",$user_input"
    $search_type = "(Device)"
    if (($search_term -notlike ",T111A-?*") -and ($search_term -notlike ",???PRD*??")) {
        $search_term = "$search_term "
        $search_type = "(User)"
    }

    # Run the search (return an array of lines that match the search term)
    # We do not need to use a regular expression here, so we use -SimpleMatch
    $result = Select-String -Path $file_path -SimpleMatch $search_term

    # Check if any results were found, otherwise go back to start of loop
    if (!$result) {
        Write-Host "* > `"$user_input`" not found in $($file_stats.name)"
        continue # This works like "pass" in Python idk why
    }
	
	$number_of_logins = -5
	
	# Get the last five lines and split into the relevant pieces
	$result_short = $result[$number_of_logins..-1]
	
    # Show the number of logins for the user or device
    Write-Host "* > Logins: $(([int]$result.count).ToString('0,0'), $search_type)"
    Write-Host "*"

	foreach ($r in $result_short) {
		$format_result = $r -split "," | ForEach-Object -Process {$_.Trim()}
		$line_date = $format_result[0] -split ":"
        
        # Only show the relevant log in details and copy it to clipboard
        if ($search_type -eq "(User)") {
		    Write-Host "* > Device: $($format_result[6])"
            Set-Clipboard $format_result[6]
        } else {
		    Write-Host "* > User:   $($format_result[2])"
            Set-Clipboard $format_result[2]
        }
		Write-Host "* > Date:   $($line_date[2], $format_result[1])"
		Write-Host "*"
	}

    
}

# Why are you here?