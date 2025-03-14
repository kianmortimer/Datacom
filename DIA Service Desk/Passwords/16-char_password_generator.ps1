<#

Title:   16-char_password_generator.ps1
Author:  kian.mortimer@datacom.com
Date:    14/03/25
Version: 3.1

Description:
- Random password generator
- Randomises a 16 character password made up of either:
		5 and 6 letter words (two 5 and one 6)
  OR	4 and 6 letter words (one 4 and two 6)
  OR    4, 5 and 7 letter words (one 4, one 5, and one 7)
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

# print instruction
Write-Host
Write-Host " Password will be automatically copied"
Write-Host " Press [Enter] to keep generating passwords"
Write-Host

# set up formats / combinations
$word_lengths = 4,5,6,7
# different word length combinations (# of 4, # of 5, # of 6, # of 7)
$formats = @( @(0, 2, 1) , @(1, 0, 2) , @(1, 1, 0, 1) )

# set up file paths
$file_paths = @()
foreach ($word_length in $word_lengths) {
    $file_paths += "C:\SD Datacom Tools\burgerking\Passwords\Word Lists\$($word_length)_letter_words.txt"
}

# read word files into 2d array
$word_lists = @()
foreach ($file_path in $file_paths) {
	$word_lists += ,@(Get-Content $file_path)
}

# keeping looping until user quits
while ($true) {
	
	# get a random format
	$format = $formats[(Get-Random -Maximum $formats.length)]

	# get random sample from the format selected
	$selection = @()
    # go through each value in the format
	for ($i=0;$i-lt$format.length;$i++) {
		if ($format[$i] -gt 0) { # only get words from required lists
            # the format specifies number of words of each length
            $selection += ($word_lists[$i] | Get-Random -Count $format[$i])
        }
	}
	
	# randomise the order of the 3 words
	$selection = $selection | Get-Random -Count $selection.length
	
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
