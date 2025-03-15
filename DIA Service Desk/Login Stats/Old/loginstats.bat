@echo off

rem Title:   loginstats.bat
rem Author:  kian.mortimer@datacom.com
rem Date:    31/05/24
rem Version: 3.8

rem Description: 
rem - Script to find the most recent login of DIA user or device
rem - Search by username or device name (e.g. "mortimki" or "T111A-LXXXXXXXX")
rem - The search is not case-sensitive (e.g. "mortimki" == "MORTIMKI")
rem - The search will return the username, device name, line number (in file), date of login
rem - The device name will automatically get copied to your clipboard
rem - To copy anything else, use the shortcut "Ctrl+Shift+C" or right-click

rem Warning:
rem - Make any changes to this script at your own risk; batch files are OP
rem - This script does not make any changes or modifications, it only reads
rem - This script can be safely terminated at any stage

rem Help:
rem - If you want to know anything about these functions,
rem - you can open Command Prompt and type "help function"
rem - (e.g. "help set" or "help findstr")

rem Edit the window - If the colour is bad, open cmd and type "help color"
title Search loginstats.txt
rem color 0A

rem Set file path
set file="\\wlgprdfile02\audit$\capturestatistics\loginstats.txt"

rem Enable delayed expansion so that we can do sequential calculations inside for loops
rem Basically without it, variables are substituted at read time not execution time
rem The variables affected are the ones called by !var! instead of %var%
rem It's quirky but trust me, "It just works" - Todd Howard
setlocal EnableDelayedExpansion

rem *** GET STATISTICS ***

rem Get a bunch of interesting statistics about the file
rem Calculate number of lines in file
for /f %%n in ('find "" /v /c ^< %file%') do set /a lines=%%n
rem Get file path, file size, date modified
for /f "usebackq" %%I in ('%file%') do (
    rem The funky looking variables (i.e. %%~xI) are default attributes of the file object
    echo File: %%~fI
    set /a "size=%%~zI"
    rem Bytes / 1024 = Kilobytes, Kilobytes / 1024 = Megabytes
    set /a size/=1024*1024
    echo Size: !size!MB ^| Lines: %lines%
    echo Date: %%~tI
)
echo:

rem *** START SEARCH ***

rem Print instructions to output
echo Search by username or device name [case-insensitive]
echo Device name will be AUTOMATICALLY copied to clipboard!
echo Note: right-click anywhere to paste in this window

rem Start of loop
:LoopInput
echo:

rem Get search term from user
set /p input=Search: 

rem Strip input of whitespace
for /f "tokens=1 delims= " %%a in ("%input%") do set input=%%a

rem Make sure we don't find similar usernames by accident
rem e.g. if we search "mortimki" we would also be locating "mortimki2" etc
rem We need to force the input to be the whole username / device name
rem We are not using regular expressions because they increase the complexity
rem (Search time goes from barely a second to a few seconds)
set search_term=,%input%
if /i "%input:~0,5%" neq "T111A" (
    rem Add trailing whitespace character if searching by username
    set search_term=%search_term% 
)

rem Find every match, and store the last one found in %line%
set line=
for /f "tokens=* delims=" %%l in ('findstr /l /i /n /c:"%search_term%" %file%') do set line=%%l

rem If login not found, go back to start
if "%line%" equ "" (
    echo "%input%" not found in loginstats.txt
    goto :LoopInput
)

rem Get the date, time, username, device name from the line
rem %%a - line:date | %%b - time | %%c - username | %%f - device
for /f "tokens=1-3,5-8 delims=," %%a in ("%line%") do (

    rem Strip output of whitespace
    for /f "tokens=1 delims= " %%x in ("%%a") do set line_date=%%x
    for /f "tokens=1,2 delims= " %%x in ("%%b") do set time=%%x %%y
    for /f "tokens=1 delims= " %%x in ("%%c") do set username=%%x
    for /f "tokens=1 delims= " %%x in ("%%f") do set device=%%x

    rem Print the output
    echo ^> Device: !device!
    echo ^> User:   !username!
    rem %%i - line | %%j - date
    for /f "tokens=1,2 delims=:" %%i in ("!line_date!") do (
        echo ^> Date:   %%j !time!
        rem Uncomment/comment the below to add/remove the line number from the output
        echo ^> Line:   %%i
    )
	rem Uncomment/comment the below to add/remove them from the output
	echo ^> IP:     %%d
	echo ^> MAC:    %%e
	echo ^> Server: %%g
	
    rem Copy the device name to the clipboard - YUP!
    echo !device!| clip
)

rem Loop back to beginning
rem (You don't have to rerun the script everytime)
goto :LoopInput

endlocal

rem Why are you here?
