:: -- system intialization --

:_sysInit (
	@echo off
	cls
	:: import core library
	set "assemblyLibrary=assembly.library.cmd"
	call :_importCoreLib %assemblyLibrary%
	:: The one and only literal goto!
	call :_main
	goto _end
)

:_importCoreLib (	
	set "LibToImport=%1"
	set "libExists=false"

	:: if the library exists somewhere on the environment path, store result
	:: nb: can't use standard "if exist" with a file that is not in the present directory
	where %LibToImport% >nul 2>&1

	if %errorlevel% EQU 0 (
		set "libExists=true"
	)

	:: if library not found, fail gracefully
	if "%libExists%" EQU "false" (
		echo [fatal] library not found: %LibToImport% && echo.
		exit 1
	)

	:: if library found, import
	call %LibToImport% import 1.1
	set "LibToImport="
	exit /b
)

:_importAppLib (
	:: make this a generic imprt lib later with yupe of import
	set "LibToImport=%1"
	set "libExists=false"

	:: if the library exists somewhere on the environment path, store result
	:: nb: can't use standard "if exist" with a file that is not in the present directory

	if %errorlevel% EQU 0 (
		set "libExists=true"
	)

	:: if library not found, fail gracefully
	if "%libExists%" EQU "false" (
		echo [fatal] library not found: %LibToImport% && echo.
		exit 1
	)

	:: if library found, import
	call %LibToImport% %2 %3 %4 %5
	set "LibToImport="

	%RTS%
)

:: -- application utility functions --

:appInit (
	set "appVer=0.10"
	set "hostError=0"
	set "keyReturn=0"
	set "formattedDate="
	set "pingSuccesses=0"
	set "pingFailures=0"
	set "pingTotal=0"
	set "pingFailPercentage=0"
	set "pingBeepOnFail=True"
	set "pingState=[init]"
	set "pingFailLog=ping-failures.log"
	set "pingTimeout=1408"

	set "safePings=10"
	set "safeHost=127.0.0.1"
	set "hostToPing=%safeHost%"

	set "domains[0]=google"
	set "domains[1]=cloudflare"
	set "domains[2]=quad9"
	set "domains[3]=openDNS"

	set "hosts[0]=8.8.8.8"			- google
	set "hosts[1]=1.1.1.1"			- cloudflare
	set "hosts[2]=9.9.9.9"			- quad9
	set "hosts[3]=208.67.222.123"	- openDNS
	set "maxHosts=3"
	
	:: -1 : host rotation will increment host index to 0
	set "hostIndex=-1"

	set "keyDelay=1"

	set "consoleLibrary=console.lib.cmd"
	%RET%
)

:: -- utility functions --

:delayTimer (
	:: basic universal silent delay
	timeout -t %1 > nul
	%RET%
)

:getDateTime (
	:: store date in variable: formattedDate
	:: for /f "delims=" %%a in ('powershell -Command "Get-Date -Format 'MM-dd-yyyy.HH:mm:ss'"') do (
	for /f "delims=" %%a in ('powershell -Command "Get-Date -Format 'MM-dd-yyyy HH:mm:ss'"') do (
		set "dateTime=%%a"
	)
	%RET%
)

:logAppend (
	%JSR% :getDateTime
	echo %dateTime% %hostToPing% >> %pingFailLog%
	%RET%
)

:pingHost (	
	:: arg 1: host, arg 2: timeout in ms
	:: echo Pinging %1 with a timeout of: %2
	:: ping -w %2 -n 1 %1 >nul 2>&1
	ping -w %2 -n 1 %1 > pinglog.txt
	set "hostError=%errorlevel%"
	%RET%
)

:getEscapeCharacter (
	:: sets the escape character for subsequent calls to show/hide cursor
	:: placed inside a variable and expanded to preserve VSCode formatting
	set "gEC=for /F "delims=#" %%a in ('prompt #$E# ^& for %%a in ^(1^) do rem') do set escChar=%%a"
	%gEC%
	set "gEC="
	%RET%	
)

:hideCursor (
	echo.%escChar%[?25l
	%RET%
)

:showCursor (
	echo.%escChar%[?25h
	%RET%
)

:openLog (
	%JFR% "" "%pingFailLog%%"
	%RET%
)

:calcFailPercentage (
	:: compare with 0 to eliminate a divide by zero calculation, or skip the calculation when unnecessary
	%CMP% %pingFailures% 0
		%BEQ% calcFailPercentage.exit

	:: use powershell to calculate the percentage of ping failures and store in: %pingFailPercentage%
	for /f "delims=" %%i in ('powershell -command "[math]::Round((%pingFailures% / %pingTotal%) * 100, 2)"') do set pingFailPercentage=%%i
	
	:calcFailPercentage.exit
	%RTS%
)

:: -- safe ping handlers --

:decSafePings (
	:: decrement remaining safe pings, once we reach zero
	set /a "safePings-=1"

	:: @0 rotate the host from the intial local host to an external DNS host
	%CMP% %safePings% 0
		%JEQ% :rotateHost

	%RET%
)

:checkSafePings (
	:: check if host is safe localhost, on true, checks remaining safe pings
	:: - by testing safeHost, we naturally skip if user manually selects the next host
	%CMP% %hostToPing% %safeHost%
		%JEQ% :decSafePings

	%RET%
)		

:: -- beep code and beep toggle --

:systemBeep (
	set "beepCommand=cmdext.dll,MessageBeepStub"
		rundll32.exe %beepCommand%
	set "beepCommand="
	%RET%
)

:toggleBeep_Sub (
	:: delayed expansion hack, so we don't have to use that kludge
	:: sets true/false form arg 1
	set "pingBeepOnFail=%1"
	%RET%
)

:toggleBeep (
	:: toggles beep on / off
	:: compare current value, jump woth opposite value	
	%CMP% "%pingBeepOnFail%" "True"
		%JEQ% :toggleBeep_Sub False
		%JNE% :toggleBeep_Sub True

	%RET%
)

:: -- ping result  handlers --

:updatePingTotal (
	:: increment total ping counter
	set /a "pingTotal+=1"
	%RET%
)

:handlePingSuccess (
	:: update state and increment failure counter
	set "pingState=[ok]"
	set /a "pingSuccesses+=1"
	%JSR% :updatePingTotal
	%RET%
)

:handlePingFailure (
	:: update state and increment failure counter
	:: preserves flag state for caller
	:: beep if beep toggle is true, then call the logging function
	set "pingState=[fail] (logged)"
	set /a "pingFailures+=1"

	:: increase key delay on error, resets after delay
	set "keyDelay=5"

	%PUSHF%
		%CMP% "%pingBeepOnFail%" "True"
			%JEQ% :systemBeep
	%POPF%

	%JSR% :logAppend
	%JSR% :updatePingTotal
	%JSR% :rotateHost
	%RET%
)

:handlePingState (
	:: test hostError, jump to specific fail/success handler
	:: on fail: log time stamp, beep, update stats
	:: on success: update stats
	%CMP% %hostError% 0
		%JNE% :handlePingFailure
		%JEQ% :handlePingSuccess
	%RET%
)

:: -- host name handler

:resetHostIndex (
	set /a "hostIndex=0"
	%RET%
)

:setHost (
	call set "hostToPing=%%hosts[%hostIndex%]%%"
	%RET%
)

:rotateHost (
	set /a "hostIndex+=1"
	%CMP% "%%hosts[%hostIndex%]%%" ""
		%JEQ% :resetHostIndex 
 	
	%JSR% :setHost
	%RET%
)

:: -- display routines --

:displayLoopOutput_Sub (
	echo.----------------------------------------------
	type pinglog.txt
	echo.
	%RET%
)

:displayOutput_Head (
	cls	
	echo.----------------------------------------------
	echo.   Ping Log: Network Health Analysis - v%appVer%
	echo.----------------------------------------------
	echo.
	echo.----------------------------------------------
	echo. Host:				%hostToPing% 
	echo. Timeout: 			%pingTimeout%
	echo.----------------------------------------------
	%RET%
)

:displayOutput_Foot (
	echo. Last Result:			%pingState%
	echo. Total:				%pingTotal%
	echo. Successes:			%pingSuccesses%
	echo. Failures:			%pingFailures%
	echo. Percent:			%pingFailPercentage%
	echo.----------------------------------------------
	echo. Beep State:			%pingBeepOnFail%

	%CMP% %hostError% 0
		%JNE% :displayLoopOutput_Sub

	echo.----------------------------------------------
	echo.
	echo. N: Next Host
	echo. B: Toggle Beep
	echo. L: Open Logfile
	echo. Q: Quit
	echo.
	echo.----------------------------------------------

	%RET%
)

:: -- user intent handlers --

:setUserIntent (
	set "userIntent=%1"
	%RET%
)

:getUserIntent (
	:: wait for user input by a defined delay time, then set intent state
	set "intentOptions=QBNLP"
	set "intentPassThrough=P"
	
	choice /c %intentOptions% /t %keyDelay% /d %intentPassThrough% >nul 2>&1
	set "keyReturn=%errorlevel%"
	set "keyDelay=1"

	%CMP% %keyReturn% 1
		%JEQ% :setUserIntent Quit

	%CMP% %keyReturn% 2
		%JEQ% :setUserIntent ToggleBeep

	%CMP% %keyReturn% 3
		%JEQ% :setUserIntent NextHost

	%CMP% %keyReturn% 4
		%JEQ% :setUserIntent OpenLog

	%CMP% %keyReturn% 5
		%JEQ% :setUserIntent PassTrhough
	
	%RET%
)

:intentDispatcher (
	:: dispatch to user selected options
	%CMP% %userIntent% ToggleBeep
		%JEQ% :toggleBeep
	
	%CMP% %userIntent% NextHost
		%JEQ% :rotateHost

	%CMP% %userIntent% OpenLog
		%JEQ% :openLog
	
	%RET%
)

:: -- ping object testing --

:initClasses (

	:: *****************************************************************************
	::	Scrap all this noesense, and have the ping object contain it's own array!
	::
	::	- genName.Ping.AddHost domain n.n.n.n
	::  - genName.Ping.Execute
	::	- retain instancing for non-wan IP's	
	::	- determine vpn with object, try different service that can return csv data, or maybe use powershell
	::
	:: *****************************************************************************
	
	::instantiate object class: ping
	set "appPath=%~dp0"
	set "classPath=%appPath%class"
	set "ping=%classPath%\ping.cmd"

	set "test=%domains[0]%.ping.SetHostIP%"
	
	:: instantiate objects	
	%LDX% 0
	:instantiateObjects_Loop
		:: uses object constructor to iterates through objects and pass object references
		:: - e.g. calls the ping class with the arguments construct google
		%IOC% "%ping%" Construct %%domains[%XR%]%%

		%CMP% %maxHosts% %XR%
			%BEQ% :instantiateObjects_LoopEnd

		%INX%
		%BRA% :instantiateObjects_Loop
	:instantiateObjects_LoopEnd

	:: set host IP's
	%LDX% 0
	:setHostIP_Loop
		:: iterates through objects: to produce object references
		:: - eg google.ping.SetHostIP 8.8.8.8
		:: multi-staged to dereference without delayed expansion
		call set "_sHIP=%%domains[%XR%]%%.ping.SetHostIP"
		call set "_sHIP=%%%_sHIP%%% %%hosts[%XR%]%%"
		call %_sHIP%
	
		%INX%
		:: compare & branch out of loop if host string is empty
		%CMP% "%%hosts[%XR%]%%" ""
			%BNE% :setHostIP_Loop

		set "_sHIP="
	:setHostIP_LoopEnd

	:: -- output hosts IP's
	%LDX% 0
	:getHostIP_Loop
		for /f "delims=" %%c in ('echo %%%%domains[%XR%]%%.ping.getHostIP%%') do (
			call echo %%domains[%XR%]%% %%%c
		)

		%CMP% %maxHosts% %XR%
			%BEQ% :getHostIP_LoopEnd

		%INX%		
		%BRA% :getHostIP_Loop
	:getHostIP_LoopEnd
		
	%google.ping.Execute%
	%cloudflare.ping.Execute%
	%quad9.ping.Execute%
	%openDNS.ping.Execute%

	%google.ping.Destruct%
	%cloudflare.ping.Destruct%
	%quad9.ping.Destruct%
	%openDNS.ping.Destruct%

	pause
	%RTS%	
)

:: IP Tools & testign pre functions for next major version

:setVaidIP (
	set "_IPValid=true"	
	%RTS%
)

:validateIP (
	set "_IPValid=false"
	powershell -NoProfile -Command "exit !([System.Net.IPAddress]::TryParse('%1', [ref]$null))"	

	%CMP% "%errorlevel%" "0"
		%JEQ% :setVaidIP
	%RTS%
)

:getTrace (
	tracert -d -w 1000 %1 > tracehops.log
	%RTS%
)

:getPublicHop (
	set "_pHopIP=1.1.1.1"
	rem %JSR% :validateIP %_pHopIP%
	echo tracing hop...

	%JSR% :getTrace %_pHopIP% 
	
	pause
	%RTS%
)

:: -- main function --

:_main (
	:: Initialize constants, global varaibles
	%JSR% :appInit

	REM call :_importAppLib %consoleLibrary% DF 60 30 65001

	REM %JSR% :initClasses

	REM %JSR% :getPublicHop

	%JSR% :getEscapeCharacter
	
	%JSR% :hideCursor

	:_main.loop

		%JSR% :displayOutput_Head

		:: check if predefined on-boarding localhost ping number is non zero, and decrements
		:: transitions to from local host to first external host once decremented to zero
		%JSR% :checkSafePings

		:: ping the defined host, returns hostError		
		%JSR% :pingHost %hostToPing% %pingTimeout%

		:: updates counters and dispatches fail beep and log
		%JSR% :handlePingState

		:: Calculate Ping failure percentage
		%JSR% :calcFailPercentage

		:: display updated result stats and menu
		%JSR% :displayOutput_Foot

		:: read keyboard, set intent sate
		%JSR% :getUserIntent

		:: dispatch to user subroutines based on intent state
		%JSR% :intentDispatcher

		:: branch to loop end if user intent is Quit, else repeat
		%CMP% %userIntent% Quit
			%BEQ% :_main.loopEnd
			%BNE% :_main.loop

	:_main.loopEnd

	%JSR% :showCursor	
	%RET%
)

:: -- the end --

:_end
	echo.
