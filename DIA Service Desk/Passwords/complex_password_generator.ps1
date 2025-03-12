<#

Title:   complex_password_generator.ps1
Author:  kian.mortimer@datacom.com
Date:    12/03/25
Version: 1.0

Description:
- Random password generator
- Randomises a 12 character password made up of 5 letter words, a number, and a symbol
- Password is in TitleCase

Workflow:
- Run this script a password will be generated and copied to clipboard
- Press enter to keep generating, or close the window to stop generating

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Complex Password Generator"

# set up variables
$file_path = "C:\SD Datacom Tools\burgerking\Passwords\5_letter_words.txt"
$numbers = @(1,2,3,4,5,6,7,8,9)
$symbols = @("!", "@", "#", "$", "%", "&", "*")

# print instruction
Write-Host
Write-Host " Password will be automatically copied"
Write-Host " Press [Enter] to keep generating passwords"
Write-Host

# read word file into array
$array = @(Get-Content $file_path)

# keeping looping until user quits
while ($true) {

	# get random sample of 4 words
	$selection = $array | Get-Random -Count 2
	$password = $selection -join ""
    $number = $numbers | Get-Random
    $symbol = $symbols | Get-Random
    $password = "$($password)$($number)$($symbol)"
	
	# copy generated password to clipboard
    $password | Set-Clipboard

    # print generated password
    # this uses a special technique to avoid the
    # default powershell.exe prompt including a colon
    Write-Host " $password" -NoNewline
	$empty = $host.UI.ReadLine()
	
}

# borgir