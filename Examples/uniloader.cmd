:: -- Bootstrap Function ---

:_sysInit {
	@echo off
	cls
	call :_ImportCoreLib assembly.library.cmd import 1.1	
::	call :_ImportCoreLib gum.lib-1.0.cmd import

	:: Jump to  main application entry point
	call :_main %1

	:: Clean Exit
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

	To Do: Mable 2.0
		Think about the pro/con of converting mable into an interpreter so that mable encoded libraries can also use mable syntax without importing the framework a second time.
		Instead of calling mable as a library, it would be the first command (mable.cmd) followed by the script.

			execution:
				mable uniloader2 sillytavern

	*/

:_ImportCoreLib {
	set "uldr.LibToImport=%1"
	set "uldr.LibInit=%2"
	set "uldr.LibVer=%3"

	:: If the library exists somewhere on the environment path, store result in errorlevel
	where %uldr.LibToImport% >nul 2>&1

	:: Test if assembly library exists,
	if %errorlevel% EQU 0 (
		call %uldr.LibToImport% %uldr.LibInit% %uldr.LibVer%
	) else (
		echo [ Fatal ] library not found: %uldr.LibToImport% && echo.		
		exit 3735928559
	)

	set "uldr.LibToImport="
	set "uldr.LibInit="
	set "uldr.LibVer="
	exit /b
}


:: -- Initialization --

:ManageNameSpace {

	%BRA% :ManageNameSpace.Dispatcher

	:ManageNameSpace.Dispatcher {
		%CMP% "%1" "Construct"
			%BEQ% :ManageNameSpace.Construct
			%BRA% :ManageNameSpace.Destruct
	}

	:ManageNameSpace.Construct {
		:: Internal Config
			set "uldr.appver=v2.2.0a"
			set "uldr.appPath=%~dp0"
			set "uldr.powerShellExe=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
			set "uldr.stdErr=nul 2>&1"

		:: State Safe Initialization
			set "uldr.IniParserState="
			set "uldr.ManageMessageTable="

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

		%BRA% :ManageNameSpace.Exit
	}

	:ManageNameSpace.Destruct {
		set "uldr.appver="
		set "uldr.appPath="
		set "uldr.powerShellExe="
		set "uldr.stdErr="		
		set "uldr.IniParserState="
		set "uldr.ManageMessageTable="	
		set "uldr.iniParser="
		set "uldr.iniFile="
		set "uldr.minResExe="
		set "uldr.splashExe="
		set "uldr.splashIPCFile="
		set "uldr.browserPath="
		set "CheckHTTPServerUP.Return="
		%BRA% :ManageNameSpace.Exit
	}

	:ManageNameSpace.Exit
		%RTS%
}

:ManageMessageTable {
	:: ** NOTE ** LowLevel error messages must be avilable before the deterministic data is ready to populate the messages in the Main section.
	%BRA% :ManageMessageTable.Dispatcher
	
	:ManageMessageTable.Dispatcher {
		%CMP% "%uldr.ManageMessageTable%" "init.Done"
			%BNE% :ManageMessageTable.LowLevel		
			%BRA% :ManageMessageTable.Main
	}

	:: Don't embed variables inside LowLevel error strings! Init sequence will prevent them being active.
	:ManageMessageTable.LowLevel
		:: Set inernal state for second run to catch.
		set "uldr.ManageMessageTable=init.Done"
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
		:: set "uldr.warn[0000]=[ WARN ] invalid Splash State."
		set "uldr.warn[0000]=[FAILED] Timed out waiting for the Application server to start."
		set "uldr.warn[0001]=[ WARN ] Gum is not installed. Install Gum with: winget install charmbracelet.gum :)..."				
		%BRA% :ManageMessageTable.Exit

	:ManageMessageTable.Main
		:: Messages		
		set "uldr.msg[0001]=[  OK  ] %uldr.appName% server is Up!"
		set "uldr.msg[0002]=[ INFO ] Starting %uldr.appName% HTTP server..."
		set "uldr.msg[0003]=[ INFO ] Launching %uldr.appName% browser app..."
		set "uldr.msg[0004]=[ INFO ] Browser opening disabled. Server available at: http://%uldr.ip%:%uldr.port%"
		set "uldr.msg[0005]=[ INFO ] Waiting for %uldr.appName% server..."
		%BRA% :ManageMessageTable.Exit

	:ManageMessageTable.Exit
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

:DisplayWelcomeMessage {
	:: Keep _Main tidy (tm)
	%JSR% :DisplayMessage "%uldr.msg[0000]% %uldr.appver%" NL_Post
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
		%BRA% :CheckGumInstalled.Exit

	:CheckGumInstalled.False
		set "uldr.gumInstalled=False"
		%JSR% :DisplayMessage "%uldr.warn[0001]%"
		%BRA% :CheckGumInstalled.Exit

	:CheckGumInstalled.Exit
		%RTS%
}

:DisplaySpinner {
	%BRA% :DisplaySpinner.Dispatcher

	:DisplaySpinner.Dispatcher {
		%CMP% "%uldr.gumInstalled%" "True"
			%BNE% :DisplaySpinner.text
			%BRA% :DisplaySpinner.gum
	}

	:DisplaySpinner.Text
		<nul set /p="."
		%JSR% :delay %2
		%BRA% :DisplaySpinner.Exit

	:DisplaySpinner.Gum
		:: dispaly pretty gum spinner for arg2 seconds with arg1 message.		
		%JSR% gum spin --spinner points --title %1 timeout /t %2
		%BRA% :DisplaySpinner.Exit

	:DisplaySpinner.Exit
		%RTS%
}

:DisplayMessage {
	:: Displays a formatted message (arg1) with optional new line properies (arg2 NL_Pre NL_Post & NL_Both)
	%BRA% :DisplayMessage.Procedure

	:DisplayMessage.Procedure {		
		%JSR% :DisplayMessage.ClassConstructor %1 %2
		%JSR% :DisplayMessage.Dispatcher
		%BRA% :DisplayMessage.ClassDestructor
	}

	:DisplayMessage.Dispatcher {		
		:: New Line Branch Table
		%CMP% "%DisplayMessage.nl_Position%" "NL_Pre"
			%BEQ% :DisplayMessage.NL_Pre

		%CMP% "%DisplayMessage.nl_Position%" "NL_Post"
			%BEQ% :DisplayMessage.NL_Post

		%CMP% "%DisplayMessage.nl_Position%" "NL_Both"
			%BEQ% :DisplayMessage.NL_Both

		:: When wo argument is passed, don't add new lines.
		%BRA% :DisplayMessage.NL_None
	}

	:DisplayMessage.ClassConstructor
		:: Preserve flags
		%PUSHF%
		:: Expand arguments for readability.
		set "DisplayMessage.msg=%~1"
		set "DisplayMessage.nl_Position=%~2"
		%RTS%

	:: New Line Sub Functions
	:DisplayMessage.NL_Pre
		echo.
		echo.%DisplayMessage.msg%
		%RTS%

	:DisplayMessage.NL_Post
		echo.%DisplayMessage.msg%
		echo.
		%RTS%

	:DisplayMessage.NL_Both
		echo.		
		echo.%DisplayMessage.msg%
		echo.
		%RTS%

	:DisplayMessage.NL_None	
		echo.%DisplayMessage.msg%
		%RTS%
		
	:DisplayMessage.ClassDestructor
		:: Clean up
		set "DisplayMessage.msg="
		set "DisplayMessage.nl_Position="
		:: Restore flags
		%POPF%
		%RTS%
}


:: -- Ini file loader functions

:GetIniKV {
	:: Reads section (Arg:1) and Key (Arg:2) from a specified ini file, returns its value.
	%BRA% :GetIniKV.Dispatcher

	:GetIniKV.Dispatcher {
		:: check detected state of ini parser existence, branch if already set.
		%CMP% "%uldr.IniParserState%" "Parser_Exists"
			%BEQ% :GetIniKV.GetVal

		:: Check If Parser exists, set state then Get Key and Value, else show no parser fatal errer message and exit.
		%FEX% "%uldr.iniParser%"
			%JEQ% :GetIniKV.SetState
			%BNE% :GetIniKV.NoParser
			%BRA% :GetIniKV.GetVal
	}

	:GetIniKV.GetVal {
		:: Call external Parser with key and value, return error level, and pipe stdout (return value) to file.
		:: Clear result before Query.
    	set "uldr.iniResult="
    	%JSR% "%uldr.iniParser%" "%uldr.iniFile%" "%1" "%2" > "%TEMP%\uldr_ini_output.tmp"
		:: Catch stderr from ini parser.
		set "uldr.iniError=%errorlevel%"

		%CMP% %uldr.iniError% 0
			%BNE% :GetIniKV.HandleError
			%BRA% :GetIniKV.GetReturnResult
	}

	:GetIniKV.SetState	
		:: sets parser existence state, reduces filesystem load.
		set "uldr.IniParserState=Parser_Exists"
		%RTS%

	:GetIniKV.NoParser
		%JSR% :DisplayMessage "%uldr.error[0005]%"		
		%BRK% 5

	:GetIniKV.HandleError
		::	Display IniParser Error, injecting error into the string wiht double %% expansion, delete IniParser temp file, break with exit code.
		%JSR% :DisplayMessage "%%uldr.error[000%uldr.iniError%]%%"
		del "%TEMP%\uldr_ini_output.tmp" 2>nul
		%BRK% %uldr.iniError%
	
	:GetIniKV.GetReturnResult
		: Read temp file output from ini parser, store value in result, delete temp file, exit.
	 	set /p uldr.iniResult=<"%TEMP%\uldr_ini_output.tmp"
		del "%TEMP%\uldr_ini_output.tmp" 2>nul
		%BRA% :GetIniKV.Exit

	:GetIniKV.Exit
    	%RTS%
}

:LoadUserConfig {
	:: Loading message
	%JSR% :DisplayMessage "%uldr.msg[0009]%"
	%BRA% :LoadUserConfig.Load

	:LoadUserConfig.Load {
		%JSR% :GetIniKV user browserDelay
		set "uldr.browserDelay=%uldr.iniResult%"

		%JSR% :GetIniKV user exitDelay
		set "uldr.exitDelay=%uldr.iniResult%"

		%JSR% :GetIniKV user maxTriesHTTP
		set "uldr.maxTriesHTTP=%uldr.iniResult%"

		%JSR% :GetIniKV user debug
		set "uldr.debug=%uldr.iniResult%"

		%JSR% :GetIniKV user controlTerminal.state
		set "uldr.controlTerminal.state=%uldr.iniResult%"
		%BRA% :LoadUserConfig.Exit
	}

	:LoadUserConfig.Exit
		%RTS%
}

:LoadExternalAppConfig {
	:: Loading message
	%JSR% :DisplayMessage "%uldr.msg[0010]%"
	%BRA% :LoadExternalAppConfig.Load

	:LoadExternalAppConfig.Load {
		:: loads: AppName, Port, IP, Path, Loader Script, Splash Image, and Browser Arguments
		%JSR% :GetIniKV %1 AppName
		set "uldr.appName=%uldr.iniResult%"

		%JSR% :GetIniKV %1 port
		set "uldr.port=%uldr.iniResult%"

		%JSR% :GetIniKV %1 ip
		set "uldr.ip=%uldr.iniResult%"

		%JSR% :GetIniKV %1 path
		set "uldr.path=%uldr.iniResult%"

		%JSR% :GetIniKV %1 loaderScript
		set "uldr.loaderScript=%uldr.path%\%uldr.iniResult%"

		%JSR% :GetIniKV %1 splashImage
		set "uldr.splashImage=%uldr.appPath%%uldr.iniResult%"

		%JSR% :GetIniKV %1 splashAnimationSpeed
		set "uldr.splashAnimationSpeed=%uldr.iniResult%"	

		%JSR% :GetIniKV %1 browserArgs
		set "uldr.browserArgs=%uldr.iniResult%"
		%BRA% :LoadExternalAppConfig.Exit
	}

	:LoadExternalAppConfig.Exit
		%RTS%
}

:: -- Main Application Functions

:ControlSplash {
	:: Controls the Splash loader display and quit routines through its IPC file.
	%BRA% :ControlSplash.Dispatcher

	:ControlSplash.Dispatcher {
		%CMP% %uldr.splash.State% load.Done
			%BEQ% :ControlSplash.Display

		%CMP% %uldr.splash.State% display.Done
			%BEQ% :ControlSplash.Quit
		
		:: Catch "no state" for default worker.
		%BRA% :ControlSplash.Load
	}

	:ControlSplash.Load
		%JSR% :DisplayMessage "%uldr.msg[0006]%"
		%JFR% /b %uldr.splashExe% %uldr.splashImage% %uldr.splashIPCFile% %uldr.splashAnimationSpeed%
		set "uldr.splash.State=load.Done"
		%BRA% :ControlSplash.Exit

	:ControlSplash.Display
		%JSR% :DisplayMessage "%uldr.msg[0007]%"
		echo display > %uldr.splashIPCFile%	
		set "uldr.splash.State=display.Done"
		%BRA% :ControlSplash.Exit

	:ControlSplash.Quit
		%JSR% :DisplayMessage "%uldr.msg[0008]%"
		echo quit > %uldr.splashIPCFile%
		set "uldr.splash.State="
		%BRA% :ControlSplash.Exit

	:ControlSplash.Exit
		%RTS%
}

:ControlTerminal {
	%BRA% :ControlTerminal.FlipDispatcher

	:ControlTerminal.FlipDispatcher {
		:: Exit If Disabled is set in config.
		%CMP% "%uldr.controlTerminal.state%" "Disabled"
			%BEQ% :ControlTerminal.Exit
	
		:: Flip State from Minimized to Restore
		%CMP% "%uldr.controlTerminal.state%" "Minimized"
			%BEQ% :ControlTerminal.Restore

		:: Flip State from Restore to Minimized
		%CMP% "%uldr.controlTerminal.state%" "Restored"
			%BEQ% :ControlTerminal.Minimize

		:: Catch Enabled or any initialized first other state = branch to default first 
		%BRA% :ControlTerminal.Minimize
	}

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
	%BRA% :StartHTTPServer.Start

	:StartHTTPServer.Start {
		:: start msg, Open app in new terminal tab and return focus to our control flow tab.
		%JSR% :DisplayMessage "%uldr.msg[0002]%"
		%JSR% wt --window 0 -d "%uldr.path%" --title "%uldr.appName%" "%uldr.powerShellExe%" "%uldr.LoaderScript%"
		%JSR% wt --window 0 focus-tab --target 0
		%BRA% :StartHTTPServer.Exit
	}

	:StartHTTPServer.Exit
		%RTS%
}

:CheckHTTPServerUP {	
	:: Show server wait message, assign default function return state to false, store flags and set loop counter to 0
	%JSR% :DisplayMessage "%uldr.msg[0005]%"	
	set CheckHTTPServerUP.Return=False	
	%PUSHF%
	%LDX% 0
	%BRA% :CheckHTTPServerUP.ServerCheckLoop
	
	:CheckHTTPServerUP.ServerCheckLoop {
		:: Display Probe with a short timer: Ensures message is visible long enough to read the probe message.
		%JSR% :DisplaySpinner "Probing Host: %uldr.ip%:%uldr.port%..." "2"
		:: Probe HTTP Server and test error output
		%JSR% curl -s -o nul -I -f --max-time 1 http://%uldr.ip%:%uldr.port%
		%CMP% %errorlevel% 0
			%BNE% :CheckHTTPServerUP.CheckMaxTries
			%BRA% :CheckHTTPServerUP.IsUp

		:CheckHTTPServerUP.CheckMaxTries
			%JSR% :DisplaySpinner "Sleeping..." 4
			%INX%
			%CMP% %XR% %uldr.maxTriesHTTP%
				%BEQ% :CheckHTTPServerUP.MaxTriesExceeded
				%BRA% :CheckHTTPServerUP.ServerCheckLoop
	}

	:CheckHTTPServerUP.DisplaServerWaitMsg
		%JSR% :DisplayMessage "%uldr.msg[0005]%"
		%BRA% :CheckHTTPServerUP.Exit

	:CheckHTTPServerUP.MaxTriesExceeded
		:: Output timeout error and exit.
		%JSR% :DisplayMessage "%uldr.warn[0000]%" NL_Pre
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
	 %BRA% :LaunchBrowser.BailDispatcher

	 :LaunchBrowser.BailDispatcher {
		:: Skip browser if skip debug variable set to true.
	 	%CMP% "%uldr.debug%" "True"
			%BEQ% :LaunchBrowser.Skip

		:: Exit if Server is not running,
		%CMP% %CheckHTTPServerUP.Return% True
			%BEQ% :LaunchBrowser.Launch
			%BRA% :LaunchBrowser.Exit
	 }

	:LaunchBrowser.Skip
		:: Browser skip msg.
		%JSR% :DisplayMessage "%uldr.msg[0004]%"
		%BRA% :LaunchBrowser.Exit

	:LaunchBrowser.Launch {
		:: Launch Message.	
		%JSR% :DisplayMessage "%uldr.msg[0003]%" 
		%JSR% :delay %uldr.browserDelay%

		:: Launch Browser App with app profile.
		%JFR% "%uldr.appName%" %uldr.browserPath% %uldr.browserArgs%
		%BRA% :LaunchBrowser.Exit
	}
	
	:LaunchBrowser.Exit
		%RTS%
}

:: -- Main Procedural Function

:_main {
	:: Initialization

	%JSR% :ManageNameSpace Construct		:: Construct this.application namespace variables.
	%JSR% :ManageMessageTable				:: First call Initializes Low Level message strings.
	%JSR% :DisplayWelcomeMessage			:: ...
	%JSR% :CheckGumInstalled				:: Used to determine if we can use a gum spinner, or simple dots to display waiting status.
	%JSR% :LoadExternalAppConfig %1			:: Load configuration variables for specific external HTTP Application.
	%JSR% :LoadUserConfig					:: Loads user configuration data from the ini file.
	%JSR% :ManageMessageTable				:: Second call configures message strings that are dependent on base application initialization.

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
	%JSR% :ManageNameSpace Destruct			:: Destruct this.application namespace variables.
	%RTS%
}

:: -- The End

:_end