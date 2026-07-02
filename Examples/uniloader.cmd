:: -- Bootstrap Function ---

:_sysInit {
	@echo off
	cls
	:: enable extended international character sets.
	chcp 65001 > nul

	:: Import external Mable Assembly Library.
	call :_ImportCoreLib assembly.library.cmd import 1.1

	:: Jump to  main  entry point.
	call :_main %1
	
	:: Clean Exit, non clean exits have their own handlers, and do not reach here.
	exit 0
}


/*
	Title: Universal Application Orchestrator
	Author (C) 2026 Autumn

	Usage:
		Create a shortcut to this script + the argument listed in the ini file to load and launch.

	Features:
		Load desired app in a separate wt tab
		Windows Terminal - because pretty colored text.
		Opens App as a Browser stored application without the Browser Chrome, creating a more native application feel.
		Adds a pretty graphical splash while loading.
		Tries to adhere to single responsibility and never nesting principles.

	Notes:
		Is this over-emgineered? Yes. Could it be done in 5 lines? Yes. Do I care? No.
		Got a curly brace error? you forgot a retrun.

	To do:
		Dependency check
			function with 0, 1 return and filename input.

		Document Context Awareness around PUSH POP MOV CX [functionname]
		
*/

:_ImportCoreLib {
	set "uldr.LibToImport=%1"
	set "uldr.LibInit=%2"
	set "uldr.LibVer=%3"

	:: If the library exists somewhere in the environment path, store result in errorlevel
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
		%CMP% "%uldr.state.ManageNameSpace.Initialized%" "init.done"
			%BEQ% :ManageNameSpace.Destruct
			%BRA% :ManageNameSpace.Construct
	}

	:ManageNameSpace.Construct {
		:: Internal Config
			%MOV% uldr.conf.appver "v2.2.2a"
			%MOV% uldr.conf.appPath "%~dp0"
			%MOV% uldr.conf.stdErr "nul 2>&1"			
			%MOV% contextAwareness False

		:: Binary Extensions			
			%MOV% uldr.conf.iniParser "%uldr.conf.appPath%bin\iniparser.exe"		
			%MOV% uldr.conf.minResExe "%uldr.conf.appPath%bin\minres.exe"
			%MOV% uldr.conf.splashExe "%uldr.conf.appPath%bin\splash3.exe"
			%MOV% uldr.conf.powerShellExe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

		:: Configuration / IPC Files
			%MOV% uldr.conf.iniFile "%uldr.conf.appPath%uniloader.ini"
			%MOV% uldr.conf.splashIPCFile "splash.IPC"

		:: State and Initialize Function Return Values
			%MOV% uldr.return.CheckHTTPServerUP "False"
			%MOV% uldr.state.ManageNameSpace.Initialized "init.done"
			%MOV% uldr.return.GetIniKV ""
			%MOV% uldr.state.IniParser ""
			%MOV% uldr.state.ManageMessageTable ""			

		%BRA% :ManageNameSpace.Exit
	}

	:ManageNameSpace.Destruct {
		%_MMU.Free% uldr.conf
		%_MMU.Free% uldr.return
		%_MMU.Free% uldr.state
		%BRA% :ManageNameSpace.Exit
	}

	:ManageNameSpace.Exit
		%RTS%
}

:ManageMessageTable {
	:: ** NOTE ** LowLevel error messages must be avilable before the deterministic data is ready to populate the messages in the Main section.
	%BRA% :ManageMessageTable.Dispatcher

	:ManageMessageTable.Dispatcher {
		%CMP% "%uldr.state.ManageMessageTable%" "low.Done"
			%BEQ% :ManageMessageTable.Main

		%CMP% "%uldr.state.ManageMessageTable%" "main.Done"
			%BEQ% :ManageMessageTable.Destruct

		:: Catch no state / initial state and populate low level variables.
		%BRA% :ManageMessageTable.LowLevel
	}

	:: Don't embed variables inside LowLevel error strings! Init sequence will prevent them being active.
	:ManageMessageTable.LowLevel
		:: Messages
		%MOV% uldr.msg[0000] "Universal Application Orchestrator / Loader"
		%MOV% uldr.msg[0006] "[ INFO ] Starting Background Splash Application"
		%MOV% uldr.msg[0007] "[ INFO ] Display Splash Screen"
		%MOV% uldr.msg[0008] "[ INFO ] Shutdown Splash Application"
		%MOV% uldr.msg[0009] "[ INFO ] Loading User Config..."
		%MOV% uldr.msg[0010] "[ INFO ] Loading External App Config..."

		:: Fatal - Maps to exit codes, never use zero!
		%MOV% uldr.error[0001] "[FATAL ] Invalid arguments passed to ini Parser."
		%MOV% uldr.error[0002] "[FATAL ] Ini file was not found."
		%MOV% uldr.error[0003] "[FATAL ] Ini file Section not found. Check shortcut argument, or Ini file section heading."
		%MOV% uldr.error[0004] "[FATAL ] Ini file Key not found."
		%MOV% uldr.error[0005] "[FATAL ] Ini file Parser not found."

		:: Warnings		
		%MOV% uldr.warn[0000] "[FAILED] Timed out waiting for the Application server to start."
		%MOV% uldr.warn[0001] "[ WARN ] Gum is not installed. Install Gum with: winget install charmbracelet.gum :)..."				

		:: Set inernal state for second run to catch.
		%MOV% uldr.state.ManageMessageTable "low.Done"
		%BRA% :ManageMessageTable.Exit

	:ManageMessageTable.Main
		:: Messages		
		%MOV% uldr.msg[0001] "[  OK  ] %uldr.extapp.appName% server is Up!"
		%MOV% uldr.msg[0002] "[ INFO ] Starting %uldr.extapp.appName% HTTP server..."
		%MOV% uldr.msg[0003] "[ INFO ] Launching %uldr.extapp.appName% browser app..."
		%MOV% uldr.msg[0004] "[ INFO ] Browser opening disabled. Server available at: http://%uldr.extapp.ip%:%uldr.extapp.port%"
		%MOV% uldr.msg[0005] "[ INFO ] Waiting for %uldr.extapp.appName% server..."

		:: Set inernal state for second run to catch.
		%MOV% uldr.state.ManageMessageTable "main.Done"
		%BRA% :ManageMessageTable.Exit

	:ManageMessageTable.Destruct
		%_MMU.Free% uldr.msg
		%_MMU.Free% uldr.warn
		%_MMU.Free% uldr.error
		%BRA% :ManageMessageTable.Exit

	:ManageMessageTable.Exit
		%RTS%
}


:: -- Memory Management

:_MMU {	
	:: Usage: arg_1 command, arg_2 memory space.
	:: Note: free command matches partial value in arg_2, be careful.

	%BRA% :_MMU.Dispatcher

	:_MMU.Dispatcher {		
		%CMP% "%1" ""
			%BEQ% :_MMU.RegisterMethods
		%CMP% "%1" "Free"
			%BEQ% :_MMU.Free

		%CMP% "%1" "Destruct"
			%BEQ% :_MMU.Destruct

		%BRA% :_MMU.Exit
	}

	:_MMU.RegisterMethods {
		%MOV% _MMU.Free "%JSR% :_MMU Free %2"
		%MOV% _MMU.Destruct "%JSR% :_MMU Destruct"
		%BRA% :_MMU.Exit
	}

	:_MMU.Free
		for /f "delims==" %%i in ('set %2') do (
			set "%%i="
		)
		%BRA% :_MMU.Exit

	:_MMU.Destruct
		%MOV% _MMU.Free ""
		%MOV% _MMU.Destruct ""
		%BRA% :_MMU.Exit

	:_MMU.Exit
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
	echo.
	%JSR% :DisplaySpinner "À bientôt." "%uldr.userconf.exitDelay%"
	%CMP% %uldr.userconf.debug% True
		%JEQ% :PauseApp

	%RTS%
}

:DisplayWelcomeMessage {
	:: Keep _Main tidy (tm)
	%JSR% :DisplayMessage "%uldr.msg[0000]% %uldr.conf.appver%" NL_Post
	%RTS%
}

:MoveCursorUpNLines {
	:: output escape sequence for cursor up with number of lines from Arg_1
	echo [%1F
	%RTS%
}

:CheckGumInstalled {
	%BRA% :CheckGumInstalled.Dispatcher

	:: Check if gum responds
	:CheckGumInstalled.Dispatcher {
		%CMP% "%1" "Destruct"
			%BEQ% :CheckGumInstalled.Destruct

		%JSR% gum -v > %uldr.conf.stdErr%
		%CMP% %errorlevel% 0
			%BNE% :CheckGumInstalled.False
			%BRA% :CheckGumInstalled.True
	}

	:CheckGumInstalled.True
		%MOV% uldr.gumInstalled "True"
		%BRA% :CheckGumInstalled.Exit

	:CheckGumInstalled.False
		%MOV% uldr.gumInstalled "False"
		%JSR% :DisplayMessage "%uldr.warn[0001]%"
		%BRA% :CheckGumInstalled.Exit

	:CheckGumInstalled.Destruct
		%MOV% uldr.gumInstalled ""
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
	:: Displays a formatted message (arg1) with optional new line properies (arg2)
	%BRA% :DisplayMessage.Procedure

	:DisplayMessage.Procedure
		%JSR% :DisplayMessage.Constructor %1 %2
		%JSR% :DisplayMessage.Dispatcher
		%JSR% :DisplayMessage.Destructor
		%RTS%

	:DisplayMessage.Constructor	
		%PUSHF%				
		%MOV% DisplayMessage.msg "%~1"
		%MOV% DisplayMessage.nl_Position "%~2"
		%RTS%

	:DisplayMessage.Destructor
		%MOV% DisplayMessage.msg ""
		%MOV% DisplayMessage.nl_Position ""
		%POPF%
		%RTS%

	:DisplayMessage.Dispatcher {
		:: New Line Branch Table
		%CMP% "%DisplayMessage.nl_Position%" "NL_Pre"
			%BEQ% :DisplayMessage.NL_Pre

		%CMP% "%DisplayMessage.nl_Position%" "NL_Post"
			%BEQ% :DisplayMessage.NL_Post

		%CMP% "%DisplayMessage.nl_Position%" "NL_Both"
			%BEQ% :DisplayMessage.NL_Both

		:: When argument is passed, don't add new lines.
		%BRA% :DisplayMessage.NL_None
	}

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
}


:: -- Ini file loader functions

:GetIniKV {
	:: Reads section (Arg:1) and Key (Arg:2) from a specified ini file, returns its value.
	%BRA% :GetIniKV.Dispatcher

	:GetIniKV.Dispatcher {
		%CMP% "%1" "Destruct"
			%BEQ% :GetIniKV.Destruct

		:: check detected state of ini parser existence, branch if already set.
		%CMP% "%uldr.state.IniParser%" "Parser_Exists"
			%BEQ% :GetIniKV.GetVal

		:: Check If Parser exists, set state then Get Key and Value, else show no parser fatal error message and exit.
		%FEX% "%uldr.conf.iniParser%"
			%JEQ% :GetIniKV.SetState
			%BNE% :GetIniKV.NoParser
			%BRA% :GetIniKV.GetVal
	}

	:GetIniKV.SetState
		:: sets parser existence state, reduces filesystem load.
		%MOV% uldr.state.IniParser "Parser_Exists"
		%RTS%

	:GetIniKV.NoParser
		%JSR% :DisplayMessage "%uldr.error[0005]%"
		%JSR% :Delay 5
		%BRK% 5

	:GetIniKV.GetVal {
		:: Clear result before Query.
		%MOV% uldr.return.GetIniKV ""
		:: Call external Parser with key and value, return error level, and pipe stdout (return value) to file.
    	%JSR% "%uldr.conf.iniParser%" "%uldr.conf.iniFile%" "%1" "%2" > "%TEMP%\uldr_ini_output.tmp"
		:: Catch stderr from ini parser.
		%MOV% uldr.GetIniKV.iniError "%errorlevel%"
		:: Route to error handler on missing file, missing data etc, or process and return result.
		%CMP% %uldr.GetIniKV.iniError% 0
			%BNE% :GetIniKV.HandleError
			%BRA% :GetIniKV.GetReturnResult
	}

	:GetIniKV.HandleError
		::	Display IniParser Error, injecting error into the string wiht double %% expansion, delete IniParser temp file, break with exit code.
		%JSR% :DisplayMessage "%%uldr.error[000%uldr.GetIniKV.iniError%]%%"
		del "%TEMP%\uldr_ini_output.tmp" 2>nul
		%JSR% :Delay 5
		%BRK% %uldr.GetIniKV.iniError%
	
	:GetIniKV.GetReturnResult
		: Read temp file output from ini parser, store value in result, delete temp file, exit.	 	
		set /p uldr.return.GetIniKV=<"%TEMP%\uldr_ini_output.tmp"
		del "%TEMP%\uldr_ini_output.tmp" 2>nul		
		%BRA% :GetIniKV.Exit

	:GetIniKV.Destruct		
		%MOV% uldr.GetIniKV.iniError ""
		%BRA% :GetIniKV.Exit

	:GetIniKV.Exit
    	%RTS%
}

:LoadUserConfig {
	%BRA% :LoadUserConfig.Dispatcher

	:LoadUserConfig.Dispatcher {
		%CMP% "%1" "Load"
			%BEQ% :LoadUserConfig.Construct
			%BRA% :LoadUserConfig.Destruct
	}

	:LoadUserConfig.Construct {
		:: Loading message
		%JSR% :DisplayMessage "%uldr.msg[0009]%"

		%JSR% :GetIniKV user exitDelay
		%MOV% uldr.userconf.exitDelay "%uldr.return.GetIniKV%"

		%JSR% :GetIniKV user maxTriesHTTP
		%MOV% uldr.userconf.maxTriesHTTP "%uldr.return.GetIniKV%"

		%JSR% :GetIniKV user debug
		%MOV% uldr.userconf.debug "%uldr.return.GetIniKV%"

		%JSR% :GetIniKV user controlTerminal.state
		%MOV% uldr.userconf.controlTerminal.state "%uldr.return.GetIniKV%"

		%JSR% :GetIniKV user browserPath
		%MOV% uldr.conf.browserPath "%uldr.return.GetIniKV%"

		%BRA% :LoadUserConfig.Exit
	}

	:LoadUserConfig.Destruct {
		%_MMU.Free% uldr.userconf
		%BRA% :LoadUserConfig.Exit
	}

	:LoadUserConfig.Exit
		%RTS%
}

:LoadExternalAppConfig {	
	%BRA% :LoadExternalAppConfig.Dispatcher

	:LoadExternalAppConfig.Dispatcher {
		%CMP% "%1" "Load"
			%BEQ% :LoadExternalAppConfig.Construct
			%BRA% :LoadExternalAppConfig.Destruct
	}

	:LoadExternalAppConfig.Construct {
		:: Loading message
		%JSR% :DisplayMessage "%uldr.msg[0010]%"

		:: loads: AppName, Port, IP, Path, Loader Script, Splash Image, and Browser Arguments
		%JSR% :GetIniKV %2 AppName
		%MOV% uldr.extapp.appName "%uldr.return.GetIniKV%"

		%JSR% :GetIniKV %2 port
		%MOV% uldr.extapp.port "%uldr.return.GetIniKV%"

		%JSR% :GetIniKV %2 ip
		%MOV% uldr.extapp.ip "%uldr.return.GetIniKV%"

		%JSR% :GetIniKV %2 path
		%MOV% uldr.extapp.path "%uldr.return.GetIniKV%"

		%JSR% :GetIniKV %2 loaderScript
		%MOV% uldr.extapp.loaderScript "%uldr.extapp.path%\%uldr.return.GetIniKV%"

		%JSR% :GetIniKV %2 splashImage
		%MOV% uldr.extapp.splashImage "%uldr.conf.appPath%%uldr.return.GetIniKV%"

		%JSR% :GetIniKV %2 splashAnimationSpeed
		%MOV% uldr.extapp.splashAnimationSpeed "%uldr.return.GetIniKV%"

		%JSR% :GetIniKV %2 browserArgs
		%MOV% uldr.extapp.browserArgs "%uldr.return.GetIniKV%"

		%BRA% :LoadExternalAppConfig.Exit
	}

	:LoadExternalAppConfig.Destruct {
		%_MMU.Free% uldr.extapp
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
		
		:: Catch "no state" for default Load worker.
		%BRA% :ControlSplash.Load
	}

	:ControlSplash.Load
		%JSR% :DisplayMessage "%uldr.msg[0006]%"
		%JFR% /b %uldr.conf.splashExe% %uldr.extapp.splashImage% %uldr.conf.splashIPCFile% %uldr.extapp.splashAnimationSpeed%
		%MOV% uldr.splash.State "load.Done"
		%BRA% :ControlSplash.Exit

	:ControlSplash.Display
		%JSR% :DisplayMessage "%uldr.msg[0007]%"
		echo display > %uldr.conf.splashIPCFile%
		%MOV% uldr.splash.State "display.Done"
		%BRA% :ControlSplash.Exit

	:ControlSplash.Quit
		%JSR% :DisplayMessage "%uldr.msg[0008]%"
		echo quit > %uldr.conf.splashIPCFile%
		%MOV% uldr.splash.State ""
		%BRA% :ControlSplash.Exit

	:ControlSplash.Exit
		%RTS%
}

:ControlTerminal {
	%BRA% :ControlTerminal.FlipDispatcher

	:ControlTerminal.FlipDispatcher {
		:: Exit If Disabled is set in config.
		%CMP% "%uldr.userconf.controlTerminal.state%" "Disabled"
			%BEQ% :ControlTerminal.Exit
	
		:: Flip State from Minimized to Restore
		%CMP% "%uldr.userconf.controlTerminal.state%" "Minimized"
			%BEQ% :ControlTerminal.Restore

		:: Flip State from Restore to Minimized
		%CMP% "%uldr.userconf.controlTerminal.state%" "Restored"
			%BEQ% :ControlTerminal.Minimize
		
		:: Catch Enabled or any initialized first other state = branch to default first 
		%BRA% :ControlTerminal.Minimize
	}

	:ControlTerminal.Minimize
		:: Don't vanish in an instant like suspicious software.
		%JSR% :Delay 2
		%JSR% %uldr.conf.minResExe% Minimize
		:: set "uldr.userconf.controlTerminal.state=Minimized"
		%MOV% uldr.userconf.controlTerminal.state "Minimized"
		%BRA% :ControlTerminal.Exit

	:ControlTerminal.Restore
		%JSR% %uldr.conf.minResExe% Restore
		:: set "uldr.userconf.controlTerminal.state=Restored"
		%MOV% uldr.userconf.controlTerminal.state "Restored"
		%BRA% :ControlTerminal.Exit

	:ControlTerminal.Exit
		%RTS%
}

:StartHTTPServer {
	%BRA% :StartHTTPServer.Start

	:StartHTTPServer.Start {
		:: start msg, Open app in new terminal tab and return focus to our control flow tab.
		%JSR% :DisplayMessage "%uldr.msg[0002]%"
		%JSR% wt --window 0 -d "%uldr.extapp.path%" --title "%uldr.extapp.appName%" "%uldr.conf.powerShellExe%" "%uldr.extapp.loaderScript%"
		%JSR% wt --window 0 focus-tab --target 0
		%BRA% :StartHTTPServer.Exit
	}

	:StartHTTPServer.Exit
		%RTS%
}

:CheckHTTPServerUP {
	%BRA% :CheckHTTPServerUP.Procedure

	:CheckHTTPServerUP.Procedure
		%JSR% :DisplayMessage "%uldr.msg[0005]%"			:: Show server wait message.
		%JSR% :CheckHTTPServerUP.Construct					:: Assign default fail retrun, store flags and set loop counter to 0
		%JSR% :CheckHTTPServerUP.Loop						:: Main HTTP server probe loop
		%JSR% :CheckHTTPServerUP.Destruct					:: Resstore CPU flags and registers.
		%RTS%						 						:: Return to Caller. Class Dismissed 🎓

	:CheckHTTPServerUP.Construct
		%MOV% uldr.return.CheckHTTPServerUP "False"
		%PUSHF%
		%LDX% %uldr.userconf.maxTriesHTTP%
		%RTS%

	:CheckHTTPServerUP.Destruct
		%POPF%
		%RTS%

	:CheckHTTPServerUP.Loop {
		%JSR% :DisplaySpinner "Probing Host: %uldr.extapp.ip%:%uldr.extapp.port%..." "2"
		:: Silently probe HTTP server and test stderr
		%JSR% curl -s -o nul -I -f --max-time 1 http://%uldr.extapp.ip%:%uldr.extapp.port%
		%CMP% %errorlevel% 0
			%BNE% :CheckHTTPServerUP.CheckMaxTries
			%BRA% :CheckHTTPServerUP.IsUp

		:CheckHTTPServerUP.MaxTriesExceeded
			%CMP% %uldr.gumInstalled% "False"
				%JEQ% :MoveCursorUpNLines 1

			%JSR% :DisplayMessage "%uldr.warn[0000]%"
			%RTS%

		:CheckHTTPServerUP.IsUp
			%MOV% uldr.return.CheckHTTPServerUP "True"
			%CMP% %uldr.gumInstalled% "False"
				%JEQ% :MoveCursorUpNLines 1

			%JSR% :DisplayMessage "%uldr.msg[0001]%"
			%RTS%

		:CheckHTTPServerUP.CheckMaxTries
			%DEX%
			%JSR% :DisplaySpinner "Retries Remaining: %XR%..." "4"
			%CMP% %XR% 0
				%BEQ% :CheckHTTPServerUP.MaxTriesExceeded
				%BRA% :CheckHTTPServerUP.Loop
	}
}

:LaunchBrowser {
	%BRA% :LaunchBrowser.BailDispatcher

	 :LaunchBrowser.BailDispatcher {
		:: Skip browser if skip debug variable set to true.
	 	%CMP% "%uldr.userconf.debug%" "True"
			%BEQ% :LaunchBrowser.Skip

		:: Exit if Server is not running,
		%CMP% %uldr.return.CheckHTTPServerUP% True
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

		:: Launch Browser App with app profile.
		%JFR% "%uldr.extapp.appName%" "%uldr.conf.browserPath%" %uldr.extapp.browserArgs%
		%BRA% :LaunchBrowser.Exit
	}
	
	:LaunchBrowser.Exit
		%RTS%
}

:: -- Main Procedural Function

:_main {
	%JSR% :_MMU
	%JSR% :ManageNameSpace					:: Construct namespace variables.
	%JSR% :ManageMessageTable				:: First call Initializes Low Level message strings.
	%JSR% :DisplayWelcomeMessage			:: ...

	:: Main Initialization
	%JSR% :CheckGumInstalled				:: Sets Gum spinner installation state - we fall back to dots if not.
	%JSR% :LoadUserConfig Load				:: Loads user configuration data from the ini file.
	%JSR% :LoadExternalAppConfig Load %1	:: Load configuration variables for specific external HTTP Application.	
	%JSR% :ManageMessageTable				:: Second call configures message strings that are dependent on base application initialization.

	:: Staging
	%JSR% :ControlSplash					:: Splash state transition: Loads splash image application in the background, waits for IPC commands.
	%JSR% :StartHTTPServer					:: Start HTTP Server for AI Application.
	%JSR% :ControlSplash					:: Splash state transition: Sends Display IPC Command to the Splash Application.
	%JSR% :ControlTerminal					:: Terminal State transition: Minimize Terminal.
	%JSR% :CheckHTTPServerUP				:: Check if server is up (loop with max).

	:: Exit Prep
	%JSR% :ControlTerminal					:: Terminal State transition: Restore Terminal
	%JSR% :ControlSplash					:: Splash state transition: Sends Quit IPC Command to the Splash Application.

	:: Finale
	%JSR% :LaunchBrowser					:: Launch Browser Application, Displays Browser IP/URL if Disabled in config.
	%JSR% :Bye								:: Wave.

	:: Deallocate Memory
	%JSR% :LoadUserConfig Destruct			:: Destroy UserConfig variables.
	%JSR% :LoadExternalAppConfig Destruct 	:: Destroy External App config variables.
	%JSR% :GetIniKV Destruct				:: Destroy 'scoped' variables for KV eval.
	%JSR% :ManageMessageTable				:: Destroy Message Table variables.
	%JSR% :ManageNameSpace Destruct			:: Destroy Namespace variables.
	%JSR% :CheckGumInstalled Destruct		:: Destroy Gum Namespace variables.

	%_MMU.Destruct%

	%RTS%
}

:: -- The End

:_end