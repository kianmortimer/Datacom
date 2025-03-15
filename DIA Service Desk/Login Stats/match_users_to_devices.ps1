<#

Title:   match_users_to_devices.ps1
Author:  kian.mortimer@datacom.com
Date:    15/03/25
Version: 1.0

Description: 
- Script to find the most recent login of DIA user or device
- Search by username or device name (e.g. "mortimki" or "T111A-LXXXXXXXX")
- The search is not case-sensitive (e.g. "mortimki" == "MORTIMKI")
- The search will return the username, device name, and more
- The device name will automatically get copied to your clipboard
- To copy anything else, use the shortcut "Ctrl+Shift+C" or right-click

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
$host.ui.RawUI.WindowTitle = "Match Users To Devices"

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
Write-Host "* Search by usernames or device names [case-insensitive]"
Write-Host "* Results with be automatically copied to the clipboard!"
Write-Host "* CSV file will be generated with the matching pairs"
Write-Host "* Note: right-click to paste in this window"
Write-Host "*"
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"

### START SEARCH ###

# The first loop will auto-paste whatever is in the clipboard
$first = $true

# Start of loop
:mainLoop while ($true) {
    Write-Host

    # Check whether this is the first loop
	if ($first) {
		$first = $false
		# If it's the first loop; auto-paste the content in the user's clipboard
		$user_input = Get-Clipboard | ForEach-Object -Process { if ($_) { $_.Trim() } }
		Write-Host  " Enter usernames/devices: $($user_input)"
	} else {
		# If it's not the first loop; get the user input normally
		$user_input = Read-Host " Enter username/devices" | ForEach-Object -Process { if ($_) { $_.Trim() } }
	}
    Write-Host

    # convert input into a list of names
    $search_list = $user_input -split "`n"
    
    # setup result table
    $rows = [System.Collections.Generic.List[PSCustomObject]]::new()
    $result_string = ""

    # loop through the searches
    foreach ($search in $search_list) {
        
        # double check that it's a reasonable search
        if ($search.length -lt 6) {
            continue
        }

        # Determine the search term pattern
        # This is based on how loginstats.txt is formatted
        # If we search "mortimki" we don't want to find "mortimki2" also
        $search_term = ",$($search.Trim())"
        $search_type = "Device"
        if (($search_term -notlike ",T111A-?*") -and ($search_term -notlike ",???PRD*??")) {
            $search_term = "$search_term "
            $search_type = "User"
        }

        # Run the search (return an array of lines that match the search term)
        # We do not need to use a regular expression here, so we use -SimpleMatch
        $result = Select-String -Path $file_path -SimpleMatch $search_term

        # Check if any results were found, otherwise go back to start of loop
        if (!$result) {
            Write-Host " ! `"$search`" not found in $($file_stats.name)"
            continue
        }

        # Split the latest line into the relevant pieces
        $format_result = $result[-1] -split "," | ForEach-Object -Process {$_.Trim()}
        $line_date = $format_result[0] -split ":"

        $object = [PSCustomObject]@{
            "Search" = $search
            "Device" = $format_result[6]
            "User" = $format_result[2]
            "Date" = "$($line_date[2]), $($format_result[1])"
            "Count" = "$(([int]$result.count).ToString('0,0'))"
            "Line" = $(([int]$line_date[1]).ToString('0,0'))
            "IP" = $format_result[4]
            "MAC" = $format_result[5]
            "Server" = $format_result[7]
        }
        $rows.add($object)
        $result_string = $result_string + "$($format_result[2]):$($format_result[6])`n"

    }

    # Copy the list to the clipboard - YUP!
    if ($result_string) {
        $result_string | Set-Clipboard
        Write-Host $result_string
        Write-Host

        # Export to CSV
        Write-Host " > Exporting list..."
        $rows | Export-Csv -Path "C:\Users\sa-mortimki\Documents\Scripts\Login Stats\Exported Lists\Match Users To Devices $(Get-Date -Format 'dd-MM-yy').csv" -NoTypeInformation
        Write-Host " >>> Exported Lists\Match Users To Devices $(Get-Date -Format 'dd-MM-yy').csv"

    } else {
        Write-Host " ! No results found in $($file_stats.name)"
    }

    
}

# Why are you here?