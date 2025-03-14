<#

Title:   16-char_password_generator.ps1
Author:  kian.mortimer@datacom.com
Date:    14/03/25
Version: 2.0

Description:
- Random password generator
- Randomises a 16 character password made up of 5 and 6 letter words (two 5 and one 6)
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
$host.ui.RawUI.WindowTitle = "16-Character Password Generator"

# set up variables
$5_letter_words_path = "C:\Users\sa-mortimki\Documents\Scripts\Passwords\Word Lists\5_letter_words.txt"
$6_letter_words_path = "C:\Users\sa-mortimki\Documents\Scripts\Passwords\Word Lists\6_letter_words.txt"

# print instruction
Write-Host
Write-Host " Password will be automatically copied"
Write-Host " Press [Enter] to keep generating passwords"
Write-Host

# read word file into array
$5_letter_words = @(Get-Content $5_letter_words_path)
$6_letter_words = @(Get-Content $6_letter_words_path)

# keeping looping until user quits
while ($true) {

	# get random sample of 3 words (two 5 letter and one 6 letter) (5+5+6=16)
	$5_selection = $5_letter_words | Get-Random -Count 2
	$6_selection = $6_letter_words | Get-Random -Count 1
	
	# randomise the order of the 3 words
	$selection = @($5_selection + $6_selection) | Get-Random -Count 3
	
	# join the words together to form the password
	$password = $selection -join ""
	
	# copy generated password to clipboard
    $password | Set-Clipboard

    # print generated password
    # this uses a special technique to avoid the
    # default powershell.exe prompt including a colon
    Write-Host " $password" -NoNewline
	$empty = $host.UI.ReadLine()
	
}

# borgir
