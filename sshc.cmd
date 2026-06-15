:preInit (
	@echo off

	:: Import Libraries
	set "assemblyLibrary=assembly.library.cmd"
	call %assemblyLibrary% import 1.1

	:: ... grin ...	
 	rem setlocal EnableDelayedExpansion

	:: jump to entry point
	%BRA% _main	

	:: exit failsafe if import fails.
	cls
	echo. & echo [Fatal] Import Failure.
	goto _end
)

/*
	Known bugs
		Possibly many, we are in exploratory territory ;0
*/

:: --- functions ---

:_init (
	:: Initialize Local Variables

	set sshlVer=2.2
	set welcome=SSH Connection Manager version %sshlVer%

	set arg1=%1
	set arg2=%2

	set confPath=%~dp0
	set confFile=sshc.conf

	set sshCommand=
	set HostSelection=%arg1%
	set arrayCounter=
	set "sshUser="
	set "sshIP="
	set "sshPort="
	set "sshDelay=5"

	set "sshRetries=5"

	set "inputValid=true"
	set "hostUp=false"

	set "gumState=false"
	set "stdErr=nul 2>&1"

	%RET%
)

:: --- utility fucntions ---

:displayMsg (
	:: displays two passed argument strings, strips quotes from arg1
	echo %~1 %2
	%RET%
)

:appDelay (
	:: arg 1 = dalay in seconds	
	timeout /t %1 /nobreak >nul
	%RET%
)

:setHostUP (
	:: responds to a request to set the hostUP variable when the host has been detected in the "Up" state.
	set "hostUp=true"
	%RET%
)

:setInputValid (
	set "inputValid=%1"
	%RET%
)

:ValidateInput (
	:: check less than 1
	%CMP% %hostSelection% 1
		%JLT% :setInputValid false
		%BLT% :ValidateInput_End

	:: final check less than or equal to max	
	%CMP% %hostSelection% %maxEntries%
		%JGT% :setInputValid false

	:ValidateInput_End
	%RET%
)

:setGumState (
	:: sub to set the install state of Gum.
    set "gumState=%1"
    %RTS%
)

:isGumInstalled (
	:: check if gum is installed by calling it's version output function, and checking it's error level
    %JSR% gum -v > %stdErr%
    %CMP% %errorlevel% 0
        %JEQ% :setGumState true
    %RTS%
)

:: --- File I/O functions ---

:checkHost (
	:: compare X Register counter with user host selection, skips if host selection is not matched, else sets variable values
	%INX%
	%CMP% %XR% %HostSelection%
		%BNE% :checkHost_end
	
	set sshCommand=-p %3 %1@%2
	set "sshUser=%1"
	set "sshIP=%2"
	set "sshPort=%3"

	:checkHost_End
	%RET%
)

:getHost (
	:: reads lines from config, then passes them to a subroutine
	%LDX% 0
	for /f "tokens=1-4 delims=," %%a in (%confPath%%confFile%) do (		
		%JSR% :checkHost %%a %%b %%c
	)
	%RET%
)

:getMaxEntries (
	:: reads the maximum number of hosts in the config file
	set "maxEntries=0"
	for /f "tokens=1-4 delims=," %%a in (%confPath%%confFile%) do (
		set /a "maxEntries+=1"
	)
	%RET%
)
:: --- menu functions ---

:showHost (
	%INX%
	echo %XR% - %~1
	%RET%
)

:showHostList (
	:: shows a list of host names from a configuration file
	echo %welcome%
	echo.	
	%LDX% 0

	for /f "tokens=1-4 delims=," %%a in (%confPath%%confFile%) do (		
		%JSR% :showHost "%%d"	
	)
	echo.
	%RET%
)

:: --- SSH functions ---

:testSSH_Host (
	:: tests the desired ssh server is up, uses gum to make the wait pretty
	set "_sshProbeCommand=ssh -q -o BatchMode=yes -o ConnectTimeout=1 -o StrictHostKeyChecking=accept-new -p %sshPort% %sshUser%@%sshIP% exit"
	gum spin --spinner dot --title "Probing Host..." -- %_sshProbeCommand%
	%CMP% %errorlevel% 0
		%JEQ% :setHostUP	
	%RET%
)

:runSSH_Sub (
	:: arg 1 = run message, arg 2 = run command
	echo.%~1
	%~2
	%RET%
)

:runSSH (
	:: runs ssh command in quiet mode or displaying host mode
	%CMP% "%arg2%" "-q"
		%JEQ% :runSSH_Sub "" "ssh %sshCommand% -o LogLevel=QUIET"
		%JNE% :runSSH_Sub "running SSH with: %sshCommand%" "ssh %sshCommand%"
	echo.
	%RET%
)

:: --- error logic ---

:displayError_Sub (
	:: strips quotes from a passed error string and displays it.
	echo %~1
	echo.
	%RET%
)

:displayError (	
	:: keep reeading...
	%PUSHF%
		%CMP% "%1" "0x0001"
			%JEQ% :displayError_Sub "User input out of range."

		%CMP% "%1" "0x0002"
			%JEQ% :displayError_Sub "Host unreachable."

		%CMP% "%1" "0x0003"
			%JEQ% :displayError_Sub "Gum not installed - winget install charmbracelet.gum"

	%POPF%
	%RET%
)

:: --- display functions ---

:displayProgressDot (
	:: obsolete! prints sequential dots, now replaced with the gum spinner
	<nul set /p "=."
	%RET%
)

:gumSleep (
	:: dispaly pretty gum spinner for arg1 seconds
	gum spin --spinner dot --title "sleeping" timeout /t %1
	%RET%
)

:: -- app logic --

:waitForHost (
	:: test for quet flag, output host ip only if quit flag set
	%CMP% "%arg2%" "-q"
		%JEQ% :displayMsg "Waiting for" Host
		%JNE% :displayMsg "Waiting for %sshIP% / %sshUser%"

	:: check host loop, display progress dots while each iteration, then status messages.
	%LDX% 0
	:waitForHost_Loop
		:: check if host is up with ssh
		%JSR% :testSSH_Host

		:: check hostUP return variable, display appropriate message, exit loop if up
		%CMP% "%hostUP%" "true"
			%JEQ% :displayMsg "OK!"
			%BEQ% :waitForHost_Loop_end

		:: increment X Register - loop counter
		%INX%

		:: test X Register against max retries, display message if max reached, else loop
		%CMP% %XR% %sshRetries%
			%JLT% :gumSleep %sshDelay%
			%JEQ% :displayMsg "Failed"
			%BNE% :waitForHost_Loop

	:waitForHost_Loop_End

	echo.
	%RET%
)

:: --- main function ---

:_main (
	:: initialize global variables
	%JSR% :_init %1 %2

	:: check if gum is installed, display error if not and exit
	%JSR% :isGumInstalled
	%CMP% %gumState% false
		%JEQ% :displayError 0x0003
		%BEQ% _main.end

	:: check if user supplied a host command from the list, if not: show list and exit
	%CMP% "%arg1%" ""
		%JEQ% :showHostList
		%BEQ% _main.end

	:: get max hosts from config
	%JSR% :getMaxEntries

	:: check if user input is in the config
	%JSR% :validateInput
	:: check if user input is in range, error end exit if not
	%CMP% "%inputValid%" "false"
		%JEQ% :displayError 0x0001
		%BEQ% _main.end

	:: retrieve host details from config
	%JSR% :getHost

	:: wait for host to be up for n attempts
	%JSR% :waitForHost

	:: check if host was up or not, error and exit if not
	%CMP% "%hostUP%" "false"
		:: unreachable
		%JEQ% :displayError 0x0002
		%BEQ% _main.end

	:: We Made it, safely run our SSH Command
	%JSR% :runSSH
	
	:_main.end
	%BRA% _end
)

:: --- The End ---

:_end