:: -- Framework Functions ---

:_sysInit {
	@echo off
	cls
	call :_importCoreLib assembly.library.cmd
	call :_main %1
	exit 0
}

/*
	AI / IMG Processing / Chat Browser App Loader - (C) 2026 Autumn

	Usage:
		Create a shortcut to this script + the argument listed in the ini file to load and launch.

	Features:
		Load desired app in a separate wt tab
		Windows Terminal - because pretty colored text.
		Opens App as a Browser stored application without the Browser Chrome, creating a more native application feel.
		Adds a pretty graphical splash while loading.
		Tries to adhere to single responsibility and never nesting principles.
		Got a curly brace error? you coded badly.
		Could this be done in 5 lines? Yes. Do I care? No.
*/

:_importCoreLib {
	set "LibToImport=%1"

	:: If the library exists somewhere on the environment path, store result in errorlevel
	where %LibToImport% >nul 2>&1

	:: Test if assembly library exists,
	if %errorlevel% EQU 0 (
		call %LibToImport% import 1.1
	) else (
		echo [ Fatal ] library not found: %LibToImport% && echo.
		exit 1
	)

	set "LibToImport="
	%RTS%
}


:: -- Initialization --

:InitNameSpace {
	:: Internal Config
		set "uldr.appver=v2.11a"
		set "uldr.appPath=%~dp0"
		set "uldr.powerShellExe=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
		set "uldr.stdErr=nul 2>&1"

	:: Ini Parser Config
		set "uldr.iniParser=%uldr.appPath%bin\iniparser.exe"
    	set "uldr.iniFile=%uldr.appPath%uniloader.ini"

	:: Minimize / Restore
		set "uldr.minResExe=%uldr.appPath%bin\minres.exe"

	:: Splash Config		
		:: set "uldr.splashExe=%uldr.appPath%bin\splash2.exe"
		set "uldr.splashExe=%uldr.appPath%bin\splash3.exe"
		set "uldr.splashIPCFile=splash.IPC"

	:: -- Browser Launch Config !! do not alter quoting !!
		set uldr.browserPath="C:\Program Files\BraveSoftware\Brave-Browser\Application\chrome_proxy.exe"

	:: -- Initialize Function Return Values
		set CheckHTTPServerUP.Return=False
	%RTS%
}

:InitMessageTable {
	%BRA% :InitMessageTable.Dispatcher

	:: LowLevel error messages must be avilable before the data is ready to populate the messages in the Main section.
	:InitMessageTable.Dispatcher {
		%CMP% %1 LowLevel
			%BEQ% :InitMessageTable.LowLevel

		%CMP% %1 Main
			%BEQ% :InitMessageTable.Main

		%RTS%
	}

	:: Don't embed variables inside LowLevel error strings! Init sequence will prevent them being active.
	:InitMessageTable.LowLevel
		:: Messages
		set "uldr.msg[0000]=Universal ML/AI Application Loader (C) 2026 Autumn"
		set "uldr.msg[0006]=[ INFO ] Starting Background Splash Application"
		set "uldr.msg[0007]=[ INFO ] Display Splash Screen"
		set "uldr.msg[0008]=[ INFO ] Shutdown Splash Application"
		set "uldr.msg[0009]=[ INFO ] Loading User Config..."
		set "uldr.msg[0010]=[ INFO ] Loading External App Config..."

		:: Fatal
		set "uldr.error[0001]=[FATAL ] Invalid arguments passed to ini Parser."
		set "uldr.error[0002]=[FATAL ] Ini file was not found."
		set "uldr.error[0003]=[FATAL ] Ini file Section not found."
		set "uldr.error[0004]=[FATAL ] Ini file Key not found."
		set "uldr.error[0005]=[FATAL ] Ini file Parser not found."

		:: Warnings
		set "uldr.warn[0000]=[ WARN ] invalid Splash State."
		set "uldr.warn[0001]=[ WARN ] invalid Terminal State."
		set "uldr.warn[0002]=[FAILED] Timed out waiting for the Application server to start."
		set "uldr.warn[0003]=[ WARN ] Gum is not installed. Install Gum with: winget install charmbracelet.gum :)..."

		%RTS%

	:InitMessageTable.Main
		:: Messages		
		set "uldr.msg[0001]=[  OK  ] %uldr.appName% server is Up!"
		set "uldr.msg[0002]=[ INFO ] Starting %uldr.appName% HTTP server..."
		set "uldr.msg[0003]=[ INFO ] Launching %uldr.appName% browser app..."
		set "uldr.msg[0004]=[ INFO ] Browser opening disabled. Server available at: http://%uldr.ip%:%uldr.port%"
		set "uldr.msg[0005]=[ INFO ] Waiting for %uldr.appName% server..."

	%RTS%
}


:: -- Utility Functions

:Delay {
	timeout /t %1 /nobreak > nul
	%RTS%
}

:PauseApp {
	pause
	%RTS%
}

:DisplayWelcomeMessage {
	:: Keep _Main tidy (tm)
	%JSR% :DisplayMessage "%uldr.msg[0000]% %uldr.appver%" NL_Post
	%RTS%
}

:Bye {	
	%JSR% :Delay %uldr.exitDelay%

	:: Pauses if debug enabled
	%CMP% %uldr.debug% True
		%JEQ% :PauseApp

	echo.
	:: echo Bye.
	%JSR% :DisplayMessage "Bye."
	%JSR% :Delay 2
	%RTS%
}

:CheckGumInstalled {
	%BRA% :CheckGumInstalled.Dispatcher

	:: Check if gum responds
	:CheckGumInstalled.Dispatcher {
		%JSR% gum -v > %uldr.stdErr%
		%CMP% %errorlevel% 0		
			%BNE% :CheckGumInstalled.False
			%BRA% :CheckGumInstalled.True
	}

	:CheckGumInstalled.True		
		set "uldr.gumInstalled=True"
		%RTS%

	:CheckGumInstalled.False
		set "uldr.gumInstalled=False"
		%JSR% :DisplayMessage "%uldr.warn[0003]%"
		%RTS%
}

:DisplaySpinner {
	%BRA% :DisplaySpinner.Dispatcher

	:DisplaySpinner.Dispatcher {
		%CMP% "%uldr.gumInstalled%" "True"
			%BNE% :DisplaySpinner.text
			%BRA% :DisplaySpinner.gum
	}

	:DisplaySpinner.Gum
		:: dispaly pretty gum spinner for arg2 seconds with arg1 message.
		:: gum spin --spinner points --title "%1 %XR%" timeout /t %2
		gum spin --spinner points --title %1 timeout /t %2
		%RTS%

	:DisplaySpinner.Text
		<nul set /p="."
		%JSR% :delay %2
		%RTS%
}

:DisplayMessage {
	:: Preserve flags
	%PUSHF%

	:: Expand arguments for readability
	set "DisplayMessage.msg=%~1"
	set "DisplayMessage.nl_Position=%~2"
	%BRA% :DisplayMessage.Dispatcher

	:DisplayMessage.Dispatcher {
		:: New Line Branch Table
		%CMP% "%DisplayMessage.nl_Position%" "NL_Pre"
			%BEQ% :DisplayMessage.NL_Pre

		%CMP% "%DisplayMessage.nl_Position%" "NL_Post"
			%BEQ% :DisplayMessage.NL_Post

		%CMP% "%DisplayMessage.nl_Position%" "NL_Both"
			%BEQ% :DisplayMessage.NL_Both

		%BRA% :DisplayMessage.NL_None
	}

	:: New Line Sub Functions
	:DisplayMessage.NL_Pre
		echo.
		echo.%DisplayMessage.msg%
		%BRA% :DisplayMessage.Exit

	:DisplayMessage.NL_Post
		echo.%DisplayMessage.msg%
		echo.
		%BRA% :DisplayMessage.Exit

	:DisplayMessage.NL_Both
		echo.		
		echo.%DisplayMessage.msg%
		echo.
		%BRA% :DisplayMessage.Exit

	:DisplayMessage.NL_None
		echo.%DisplayMessage.msg%
		%BRA% :DisplayMessage.Exit
		
	:DisplayMessage.Exit
		:: Restore flags
		%POPF%

	%RTS%
}


:: -- Ini file loader

:GetIniKB {
	:: Reads section (Arg:1) and Key (Arg:2) from a specified ini file, returns its value.
	:: Test if Ini FIle Exists
	%FEX% "%uldr.iniParser%"
		%BNE% :GetIniKB.NoParser
		%BRA% :GetIniKB.GetVal

	:: Call external Parser with key and value, return error level, and pipe stdout (return value) to file.
	:GetIniKB.GetVal {
		:: Clear result before Query.
    	set "uldr.iniResult="
    	%JSR% "%uldr.iniParser%" "%uldr.iniFile%" "%1" "%2" > "%TEMP%\uldr_ini_output.tmp"
		:: Catch stderr from ini parser.
		set "uldr.iniError=%errorlevel%"

		%CMP% %uldr.iniError% 0
			%BNE% :GetIniKB.HandleError
			%BRA% :GetIniKB.ReturnResult
	}

	:GetIniKB.NoParser
		%JSR% :DisplayMessage "%uldr.error[0005]%"
		%JSR% :PauseApp
		%BRK% 5

	:GetIniKB.HandleError
		::	Display IniParser Error, injecting error into the string wiht double %% expansion, delete IniParser temp file, break with exit code.
		%JSR% :DisplayMessage "%%uldr.error[000%uldr.iniError%]%%"
		del "%TEMP%\uldr_ini_output.tmp" 2>nul
		%BRK% %uldr.iniError%
	
	:GetIniKB.ReturnResult
		: Read temp file output from ini parser, store value in result, delete temp file, exit.
	 	set /p uldr.iniResult=<"%TEMP%\uldr_ini_output.tmp"
		del "%TEMP%\uldr_ini_output.tmp" 2>nul
		%RTS%

	:GetIniKB.Exit
    	%RTS%
}


:LoadUserConfig {
	:: Loading message
	%JSR% :DisplayMessage "%uldr.msg[0009]%"

	%JSR% :GetIniKB user browserDelay
	set "uldr.browserDelay=%uldr.iniResult%"

	%JSR% :GetIniKB user exitDelay
	set "uldr.exitDelay=%uldr.iniResult%"

	%JSR% :GetIniKB user maxTriesHTTP
	set "uldr.maxTriesHTTP=%uldr.iniResult%"

	%JSR% :GetIniKB user debug
	set "uldr.debug=%uldr.iniResult%"

	%JSR% :GetIniKB user controlTerminal.state
	set "uldr.controlTerminal.state=%uldr.iniResult%"
	%RTS%
}

:LoadExternalAppConfig {
	:: Loading message
	%JSR% :DisplayMessage "%uldr.msg[0010]%"

	:: loads: AppName, Port, IP, Path, Loader Script, Splash Image, and Browser Arguments
	%JSR% :GetIniKB %1 AppName
	set "uldr.appName=%uldr.iniResult%"

	%JSR% :GetIniKB %1 port
	set "uldr.port=%uldr.iniResult%"

	%JSR% :GetIniKB %1 ip
	set "uldr.ip=%uldr.iniResult%"

	%JSR% :GetIniKB %1 path
	set "uldr.path=%uldr.iniResult%"

	%JSR% :GetIniKB %1 loaderScript
	set "uldr.loaderScript=%uldr.path%\%uldr.iniResult%"

	%JSR% :GetIniKB %1 splashImage
	set "uldr.splashImage=%uldr.appPath%%uldr.iniResult%"

	%JSR% :GetIniKB %1 splashAnimationSpeed
	set "uldr.splashAnimationSpeed=%uldr.iniResult%"	

	%JSR% :GetIniKB %1 browserArgs
	set "uldr.browserArgs=%uldr.iniResult%"

	%RTS%
}

:: -- Core Application Functions

:ControlSplash {
	%CMP% "%~1" "init"
		%BEQ% :ControlSplash.Init
		%BRA% :ControlSplash.Dispatcher

	:ControlSplash.Dispatcher {
		%CMP% %uldr.splash.State% init.Done
			%BEQ% :ControlSplash.Load

		%CMP% %uldr.splash.State% load.Done
			%BEQ% :ControlSplash.Display

		%CMP% %uldr.splash.State% display.Done
			%BEQ% :ControlSplash.Quit

		:: Exception: Fall-through
		%JSR% :DisplayMessage "%uldr.warn[0000]%"
		%RTS%
	}

	:ControlSplash.Init
		set "uldr.splash.State=init.Done"
		%RTS%

	:ControlSplash.Load
		%JSR% :DisplayMessage "%uldr.msg[0006]%"
		%JFR% /b %uldr.splashExe% %uldr.splashImage% %uldr.splashIPCFile% %uldr.splashAnimationSpeed%
		set "uldr.splash.State=load.Done"
		%RTS%

	:ControlSplash.Display
		%JSR% :DisplayMessage "%uldr.msg[0007]%"
		echo display > %uldr.splashIPCFile%	
		set "uldr.splash.State=display.Done"
		%RTS%

	:ControlSplash.Quit
		%JSR% :DisplayMessage "%uldr.msg[0008]%"
		echo quit > %uldr.splashIPCFile%
		set "uldr.splash.State=null"
		%RTS%
}

:ControlTerminal {
	:: Exit If Disabled is set in config.
	%CMP% "%uldr.controlTerminal.state%" "Disabled"
		%BEQ% :ControlTerminal.Exit

	:: Initialize state variable or jump to toggles.
	%CMP% "%1" "Init"
		%BEQ% :ControlTerminal.Init
		%BRA% :ControlTerminal.Flip

	:ControlTerminal.Flip {
		:: Flip State from Minimized to Restore
		%CMP% "%uldr.controlTerminal.state%" "Minimized"
			%BEQ% :ControlTerminal.Restore

		:: Flip State from Restore to Minimized
		%CMP% "%uldr.controlTerminal.state%" "Restored"
			%BEQ% :ControlTerminal.Minimize

		:: Exception Message: invalid dev state if we got here.
		%JSR% :DisplayMessage "%uldr.warn[0001]%"
		%RTS%
	}

	:ControlTerminal.Init
		set "uldr.controlTerminal.state=Restored"
		%RTS%

	:ControlTerminal.Minimize
		:: Don't vanish in an instant like suspicious software.
		%JSR% :Delay 2
		%JSR% %uldr.minResExe% Minimize
		set "uldr.controlTerminal.state=Minimized"
		%BRA% :ControlTerminal.Exit

	:ControlTerminal.Restore
		%JSR% %uldr.minResExe% Restore
		set "uldr.controlTerminal.state=Restored"
		%BRA% :ControlTerminal.Exit

	:ControlTerminal.Exit
	%RTS%
}

:StartHTTPServer {
	:: start msg
	%JSR% :DisplayMessage "%uldr.msg[0002]%"

	:: Open app in new terminal tab.
	wt --window 0 -d "%uldr.path%" --title "%uldr.appName%" "%uldr.powerShellExe%" "%uldr.LoaderScript%"
	:: Return tab focus back to the first tab.
	wt --window 0 focus-tab --target 0

	%RTS%
}

:CheckHTTPServerUP {
	:: Show server wait message
	%JSR% :DisplayMessage "%uldr.msg[0005]%"

	:: Pre set Return value to False.
	set CheckHTTPServerUP.Return=False

	:: Store CPU flags, set loop counter to 0.
	%PUSHF%
	%LDX% 0
	%BRA% :CheckHTTPServerUP.Loop

	:CheckHTTPServerUP.Loop {
		:: Display Probe with a short timer: Ensures message is visible long enough to read the probe message.
		%JSR% :DisplaySpinner "Probing Host: %uldr.ip%:%uldr.port%..." "2"
		:: Probe HTTP Server and test error output
		curl -s -o nul -I -f --max-time 1 http://%uldr.ip%:%uldr.port%
		%CMP% %errorlevel% 0
			%BNE% :CheckHTTPServerUP.CheckMaxTries
			%BRA% :CheckHTTPServerUP.IsUp

		:CheckHTTPServerUP.CheckMaxTries
			%JSR% :DisplaySpinner "Sleeping..." 4
			%INX%
			%CMP% %XR% %uldr.maxTriesHTTP%
				%BEQ% :CheckHTTPServerUP.MaxTriesExceeded
				%BRA% :CheckHTTPServerUP.Loop
	}

	:CheckHTTPServerUP.MaxTriesExceeded
		:: Output timeout error and exit.
		%JSR% :DisplayMessage "%uldr.warn[0002]%" NL_Pre
		%BRA% :CheckHTTPServerUP.Exit

	:CheckHTTPServerUP.IsUp
		:: Display server Up message, set state and exit.
		%JSR% :DisplayMessage "%uldr.msg[0001]%" NL_Pre
		set CheckHTTPServerUP.Return=True
		%BRA% :CheckHTTPServerUP.Exit

	:CheckHTTPServerUP.Exit
		:: Resstore flags and registers.
		%POPF%
		%RTS%
}

:LaunchBrowser {
	 :: Skip browser if skip debug variable set to true set.
	 %CMP% "%uldr.debug%" "True"
		%BNE% :LaunchBrowser.Try
		%BRA% :LaunchBrowser.Skip

	:: Try to launch if server is Up.
	:LaunchBrowser.Try {
		%CMP% %CheckHTTPServerUP.Return% True
			%BNE% :LaunchBrowser.Exit

		:: Launch Message		
		%JSR% :DisplayMessage "%uldr.msg[0003]%" 
		%JSR% :delay %uldr.browserDelay%

		:: Launch Browser App with app profile
		%JFR% "%uldr.appName%" %uldr.browserPath% %uldr.browserArgs%
		%RTS%
	}

	:LaunchBrowser.Skip
		:: Browser skip msg	
		%JSR% :DisplayMessage "%uldr.msg[0004]%"
		%RTS%

	:: Safety-net
	:LaunchBrowser.Exit
	%RTS%
}

:: -- Main Procedural Function

:_main {
	:: Initialization

	%JSR% :InitNameSpace					:: Initialize this.application variable namespace.
	%JSR% :InitMessageTable LowLevel		:: Initialize Low Level message strings.
	%JSR% :DisplayWelcomeMessage
	%JSR% :CheckGumInstalled
	%JSR% :LoadExternalAppConfig %1			:: Load configuration variables for specific external HTTP Application.
	%JSR% :LoadUserConfig					:: Loads user configuration data from the ini file.
	%JSR% :InitMessageTable Main			:: Initialize Main application message strings.
	%JSR% :ControlSplash Init				:: Splash State Initialization.
	%JSR% :ControlTerminal Init				:: Terminal state Initialization.

	:: Body
	%JSR% :ControlSplash					:: Splash state transition: Loads splash image application in the background, waits for IPC commands.
	%JSR% :StartHTTPServer					:: Start HTTP Server for AI Application.
	%JSR% :ControlSplash					:: Splash state transition: Sends Display IPC Command to the Splash Application.
	%JSR% :ControlTerminal					:: Terminal State transition: Minimize Terminal.
	%JSR% :CheckHTTPServerUP				:: Check if server is up (loop with max).

	:: Exit
	%JSR% :ControlTerminal					:: Terminal State transition: Restore Terminal
	%JSR% :ControlSplash					:: Splash state transition: Sends Quit IPC Command to the Splash Application.
	%JSR% :LaunchBrowser					:: Try to Launch Browser Application, Displays Browser IP/URL if Disabled in config.
	%JSR% :Bye								:: Wave.
	%RTS%
}

:: -- The End

:_end