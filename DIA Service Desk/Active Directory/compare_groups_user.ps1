<#

Title:   compare_groups_user.ps1
Author:  kian.mortimer@datacom.com
Date:    01/02/25
Version: 1.0

Description:
- Script to compare groups of two users to see which are exclusive and which are shared

Workflow:
- Run this script and enter in the username of the first user and then the second user
- The comparison will then be displayed on screen

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Compare Groups (Users)"

# Print instructions to output
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host "* Compare the AD Groups of two users            *"
Write-Host "* Enter the username of both users below        *"
Write-Host "* The comparison will then be displayed         *"
Write-Host "*                                               *"
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host

# The main loop, will keep repeating until script is terminated
:mainLoop while ($true) {
	Write-Host

    $member_dict = @{}
	
    # Loop through getting the usernames
    for ($i=1; $i -le 2; $i++) {
        
        # Get username from user
	    $user_input = Read-Host " ($i/2) Enter username" | ForEach-Object -Process { if ($_) { $_.Trim() } }
	
	    # Try-catch to make sure that an appropriate username was given
	    try {
		    # Get the groups from the specified user
            $user = Get-ADUser -Identity "$user_input"
		    $members = $user | ForEach-Object -Process { 
			    (Get-ADPrincipalGroupMembership -Identity $_.DistinguishedName | Select-Object Name).Name }
	    } catch { # If the above function (Get-ADUser) fails for any reason, it will be caught here
		    # Advise the user and go back to start of main loop
		    Write-Host " > User `"$user_input`" not found."
		    continue mainLoop
	    }

        # Add the result to the dictionary
        $member_dict[$i] = @{}
        $member_dict[$i]["name"] = $user.Name
        $member_dict[$i]["username"] = $user.SamAccountName
        $member_dict[$i]["members"] = ($members |  Sort-Object -Property Name)


    }

    # Get the shared members by doing a comparison
    $member_dict["shared"] = Compare-Object @($member_dict[1]["members"]) @($member_dict[2]["members"]) -IncludeEqual -ExcludeDifferent -Passthru | Sort-Object

    # Get the unique members by doing a comparison
    # SideIndicator format: left object "<=" | "=>" right object
    $member_dict[1]["unique"] = Compare-Object @($member_dict[1]["members"]) @($member_dict[2]["members"]) | 
        Where-Object SideIndicator -eq "<=" | Select-Object -ExpandProperty InputObject | Sort-Object
    $member_dict[2]["unique"] = Compare-Object @($member_dict[1]["members"]) @($member_dict[2]["members"]) | 
        Where-Object SideIndicator -eq "=>" | Select-Object -ExpandProperty InputObject | Sort-Object
	
    # Print out the shared members
    Write-Host
    Write-Host " -- ($($member_dict['shared'].length)) : SHARED -- "
    Write-Host (" " + $($member_dict['shared'] -join "`n "))
    Write-Host

    # Print out the unique members
    for ($i=1; $i -le 2; $i++) {
        Write-Host " -- ($($member_dict[$i]['unique'].length)) : $($member_dict[$i]['username']) : $($member_dict[$i]['name']) -- "
        Write-Host (" " + $($member_dict[$i]['unique'] -join "`n "))
        Write-Host
    }

    Write-Host
    Read-Host -Prompt " Press [Enter] to restart..."
    
}



