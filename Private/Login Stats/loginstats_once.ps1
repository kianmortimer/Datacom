<#

Title:   loginstats_once.ps1
Author:  kian.mortimer@datacom.com
Date:    04/06/24
Version: 5.1

- This version is designed to be fast and take whatever is copied as the input
- It will load, paste, run, copy, close
- It will not loop, tell you the result, or anything
- If you have don't have the right thing copied, this will not work
- The workflow would be: Go into AD, copy username, run script, profit.

Description: 
- Script to find the most recent login of DIA user
- Search by username only for this version (e.g. "mortimki")
- The search is not case-sensitive (e.g. "mortimki" == "MORTIMKI")
- The search will return the device name only, and copy it to clipboard

Warning:
- Make any changes to this script at your own risk; PowerShell is OP
- This script does not make any changes or modifications, it only reads
- This script will automatically terminate after running

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Set the file path of loginstats.txt
$file_path = "\\wlgprdfile02\audit$\capturestatistics\loginstats.txt"

### START SEARCH ###

$user_input = Get-Clipboard | ForEach-Object -Process { if ($_) {$_.Trim()} }
if (!$user_input) {$user_input = "No Content in Clipboard"}

# Determine the search term pattern
# This is based on how loginstats.txt is formatted
# If we search "mortimki" we don't want to find "mortimki2" also
$search_term = ",$user_input "

# Run the search (return an array of lines that match the search term)
# We do not need to use a regular expression here, so we use -SimpleMatch
$result = Select-String -Path $file_path -SimpleMatch $search_term

# Check if any results were found and copy device name to the clipboard
if (!$result) {
	Set-Clipboard -Value "None"
} else {
	# Split the latest line into the relevant pieces
	$format_result = $result[-1] -split ","
	# Copy the device name to the clipboard - YUP!
	Set-Clipboard -Value $format_result[6].Trim()
}

# Why are you here?