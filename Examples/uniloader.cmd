:: -- Bootstrap Function ---

:_BootStrap {
	@echo off
	cls
	:: enable extended international character sets.
	chcp 65001 > nul

	:: Import Mable Libraries
	call :_CoreLib assembly.library.cmd import 1.1	
	call :_CoreLib mmu.mable.lib.cmd Singleton pULDR	

	:: Jump to  main  entry point.
	call :_main %1

	:: unload Libraries	- reverse order!
	call :_CoreLib mmu.mable.lib.cmd Destruct pULDR
	call :_CoreLib assembly.library.cmd destruct

	:: debug for checking enviromnet.
	:: set
	
	:: Clean Exit, non clean exits have their own handlers, and do not reach here.
	exit 0
}

/*
	Title: Universal Application Loader
	Author: (C) 2026 Autumn
	License: GPL 3
	Kennel: https://github.com/DreamsInAutumn/Mable

	Purpose:
		Orchestrates the loading of Web apps inside stored browser applications.

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

:: -- Core Library function

:_CoreLib {
	set "uldr.Lib=%1"
	set "uldr.LibInit=%2"
	set "uldr.LibVer=%3"

	:: If the library exists somewhere in the environment path, store result in errorlevel
	where %uldr.Lib% >nul 2>&1

	:: Test if assembly library exists,
	if %errorlevel% EQU 0 (
		call %uldr.Lib% %uldr.LibInit% %uldr.LibVer%
	) else (
		echo [ Fatal ] library not found: %uldr.Lib% && echo.
		exit 3735928559
	)

	set "uldr.Lib="
	set "uldr.LibInit="
	set "uldr.LibVer="
	exit /b
}

:: -- Initialization --

:ULDR.ManageNameSpace {
	%BRA% :ULDR.ManageNameSpace.Dispatcher

	:ULDR.ManageNameSpace.Dispatcher {
		%CMP% "%1" "Init"
			%JEQ% :ULDR.ManageNameSpace.RegisterMethods
			%BEQ% :ULDR.ManageNameSpace.Construct

		%CMP% "%1" "Destruct"
			%BEQ% :ULDR.ManageNameSpace.Destruct

		%JSR% :ULDR.DisplayMessage "%uldr.error[0008]%"
		exit 999
	}

	:ULDR.ManageNameSpace.RegisterMethods	
		%MOV% ULDR.ManageNameSpace.Done ":ULDR.ManageNameSpace Destruct"
		%RTS%

	:ULDR.ManageNameSpace.Construct {
		:: Internal Config
		%MOV% uldr.config.appver "v2.2.2a"
		%MOV% uldr.config.appPath "%~dp0"
		%MOV% uldr.config.stdErr "nul 2>&1"
		%MOV% al.contextAwareness False

		:: Binary Extensions			
		%MOV% uldr.config.iniParser "%uldr.config.appPath%bin\iniparser.exe"
		%MOV% uldr.config.minResExe "%uldr.config.appPath%bin\minres.exe"
		%MOV% uldr.config.splashExe "%uldr.config.appPath%bin\splash3.exe"
		%MOV% uldr.config.powerShellExe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

		:: Configuration / IPC Files
		%MOV% uldr.config.iniFile "%uldr.config.appPath%uniloader.ini"
		%MOV% uldr.config.splashIPCFile "splash.IPC"

		:: State and Initialize Function Return Values
		%MOV% uldr.return.CheckHTTPServerUP "False"			
		%MOV% uldr.return.GetIniKV ""
		%MOV% uldr.state.IniParser ""
		%MOV% uldr.state.ManageMessageTable ""

		%BRA% :ULDR.ManageNameSpace.Exit
	}

	:ULDR.ManageNameSpace.Destruct {
		%JSR% %pULDR.MMU.Free% uldr.return
		%JSR% %pULDR.MMU.Free% uldr.state		
		%JSR% %pULDR.MMU.Free% ULDR.ManageNameSpace
		%BRA% :ULDR.ManageNameSpace.Exit
	}

	:ULDR.ManageNameSpace.Exit
		%RTS%
}

:ULDR.ManageMessageTable {
	:: ** NOTE ** LowLevel error messages must be avilable before the deterministic data is ready to populate the messages in the Main section.
	%BRA% :ULDR.ManageMessageTable.Dispatcher

	:ULDR.ManageMessageTable.Dispatcher {
		%CMP% "%uldr.state.ManageMessageTable%" "low.Done"
			%BEQ% :ULDR.ManageMessageTable.Main

		%CMP% "%uldr.state.ManageMessageTable%" "main.Done"
			%BEQ% :ULDR.ManageMessageTable.Destruct

		:: Catch no state / initial state and populate low level variables.
		%BRA% :ULDR.ManageMessageTable.LowLevel
	}

	:: Don't embed variables inside LowLevel error strings! Init sequence will prevent them being active.
	:ULDR.ManageMessageTable.LowLevel
		:: Messages
		%MOV% uldr.msg[0000] "Universal Application Loader"
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
		%MOV% uldr.error[0006] "[FATAL ] Undefined Splash State or command."
		%MOV% uldr.error[0007] "[FATAL ] Undefined HTTP Server Control Method."
		%MOV% uldr.error[0008] "[FATAL ] Undefined ManageNameSpace Method."

		:: Warnings		
		%MOV% uldr.warn[0000] "[FAILED] Timed out waiting for the Application server to start."
		%MOV% uldr.warn[0001] "[ WARN ] Gum is not installed. Install Gum with: winget install charmbracelet.gum :)..."

		:: Set inernal state for second run to catch.
		%MOV% uldr.state.ManageMessageTable "low.Done"
		%BRA% :ULDR.ManageMessageTable.Exit

	:ULDR.ManageMessageTable.Main
		:: Messages		
		%MOV% uldr.msg[0001] "[  OK  ] %uldr.config.appName% server is Up!"
		%MOV% uldr.msg[0002] "[ INFO ] Starting %uldr.config.appName% HTTP server..."
		%MOV% uldr.msg[0003] "[ INFO ] Launching %uldr.config.appName% browser app..."
		%MOV% uldr.msg[0004] "[ INFO ] Browser opening disabled. Server available at: http://%uldr.config.ip%:%uldr.config.port%"
		%MOV% uldr.msg[0005] "[ INFO ] Waiting for %uldr.config.appName% server..."

		:: Set inernal state for second run to catch.
		%MOV% uldr.state.ManageMessageTable "main.Done"
		%BRA% :ULDR.ManageMessageTable.Exit

	:ULDR.ManageMessageTable.Destruct	
		%JSR% %pULDR.MMU.Free% uldr.msg
		%JSR% %pULDR.MMU.Free% uldr.warn
		%JSR% %pULDR.MMU.Free% uldr.error
		%BRA% :ULDR.ManageMessageTable.Exit

	:ULDR.ManageMessageTable.Exit
		%RTS%
}

:: -- Utility Functions

:ULDR.Delay {
	timeout /t %1 /nobreak > nul
	%RTS%
}

:ULDR.PauseApp {
	pause
	%RTS%
}

:ULDR.Bye {
	echo.
	%JSR% :ULDR.DisplaySpinner "À bientôt." "%uldr.config.exitDelay%"
	%CMP% %uldr.config.debug% True
		%JEQ% :ULDR.PauseApp

	%RTS%
}

:ULDR.DisplayWelcomeMessage {
	:: Keep _Main tidy (tm)
	%JSR% :ULDR.DisplayMessage "%uldr.msg[0000]% %uldr.config.appver%" NL_Post
	%RTS%
}

:ULDR.MoveCursorUpNLines {
	:: output escape sequence for cursor up with number of lines from Arg_1
	echo [%1F
	%RTS%
}

:ULDR.CheckGumInstalled {
	%BRA% :ULDR.CheckGumInstalled.Dispatcher

	:ULDR.CheckGumInstalled.Dispatcher {
		%CMP% "%1" "Destruct"
			%BEQ% :ULDR.CheckGumInstalled.Destruct

		%JSR% :ULDR.CheckGumInstalled.CheckVer

		%CMP% "%uldr.CheckGumInstalled.gumReturn%" "0"
			%BNE% :ULDR.CheckGumInstalled.False
			%BRA% :ULDR.CheckGumInstalled.True
	}

	:ULDR.CheckGumInstalled.CheckVer
		%MOV% uldr.CheckGumInstalled.gumReturn ""
		:: Check if gum responds
		%JSR% gum -v > %uldr.config.stdErr%
		%MOV% uldr.CheckGumInstalled.gumReturn %errorlevel%
		%RTS%

	:ULDR.CheckGumInstalled.True
		%MOV% uldr.gumInstalled "True"
		%BRA% :ULDR.CheckGumInstalled.Exit

	:ULDR.CheckGumInstalled.False
		%MOV% uldr.gumInstalled "False"
		%JSR% :ULDR.DisplayMessage "%uldr.warn[0001]%"
		%BRA% :ULDR.CheckGumInstalled.Exit

	:ULDR.CheckGumInstalled.Destruct
		%MOV% uldr.CheckGumInstalled.gumReturn ""
		%MOV% uldr.gumInstalled ""
		%BRA% :ULDR.CheckGumInstalled.Exit

	:ULDR.CheckGumInstalled.Exit
		%RTS%
}

:ULDR.DisplaySpinner {
	%BRA% :ULDR.DisplaySpinner.Dispatcher

	:ULDR.DisplaySpinner.Dispatcher {
		%CMP% "%uldr.gumInstalled%" "True"
			%BNE% :ULDR.DisplaySpinner.text
			%BRA% :ULDR.DisplaySpinner.gum
	}

	:ULDR.DisplaySpinner.Text
		<nul set /p="."
		%JSR% :ULDR.Delay %2
		%BRA% :ULDR.DisplaySpinner.Exit

	:ULDR.DisplaySpinner.Gum
		:: dispaly pretty gum spinner for arg2 seconds with arg1 message.
		%JSR% gum spin --spinner points --title %1 timeout /t %2
		%BRA% :ULDR.DisplaySpinner.Exit

	:ULDR.DisplaySpinner.Exit
		%RTS%
}

:ULDR.DisplayMessage {
	:: Displays a formatted message (arg1) with optional new line properies (arg2)
	%BRA% :ULDR.DisplayMessage.Procedure

	:ULDR.DisplayMessage.Procedure
		%JSR% :ULDR.DisplayMessage.Constructor %1 %2
		%JSR% :ULDR.DisplayMessage.Dispatcher
		%JSR% :ULDR.DisplayMessage.Destructor
		%RTS%

	:ULDR.DisplayMessage.Constructor	
		%PUSHF%				
		%MOV% DisplayMessage.msg "%~1"
		%MOV% DisplayMessage.nl_Position "%~2"
		%RTS%

	:ULDR.DisplayMessage.Destructor
		%MOV% DisplayMessage.msg ""
		%MOV% DisplayMessage.nl_Position ""
		%POPF%
		%RTS%

	:ULDR.DisplayMessage.Dispatcher {
		:: New Line Branch Table
		%CMP% "%DisplayMessage.nl_Position%" "NL_Pre"
			%BEQ% :ULDR.DisplayMessage.NL_Pre

		%CMP% "%DisplayMessage.nl_Position%" "NL_Post"
			%BEQ% :ULDR.DisplayMessage.NL_Post

		%CMP% "%DisplayMessage.nl_Position%" "NL_Both"
			%BEQ% :ULDR.DisplayMessage.NL_Both

		:: When argument is passed, don't add new lines.
		%BRA% :ULDR.DisplayMessage.NL_None
	}

	:: New Line Sub Functions
	:ULDR.DisplayMessage.NL_Pre
		echo.
		echo.%DisplayMessage.msg%
		%RTS%

	:ULDR.DisplayMessage.NL_Post
		echo.%DisplayMessage.msg%
		echo.
		%RTS%

	:ULDR.DisplayMessage.NL_Both
		echo.
		echo.%DisplayMessage.msg%
		echo.
		%RTS%

	:ULDR.DisplayMessage.NL_None
		echo.%DisplayMessage.msg%
		%RTS%
}

:: -- Ini file loader functions

:ULDR.GetIniKV {
	:: Reads section (Arg:1) and Key (Arg:2) from a specified ini file, returns its value.
	%BRA% :ULDR.GetIniKV.Dispatcher

	:ULDR.GetIniKV.Dispatcher {
		%CMP% "%1" "Destruct"
			%BEQ% :ULDR.GetIniKV.Destruct

		:: check detected state of ini parser existence, branch if already set.
		%CMP% "%uldr.state.IniParser%" "Parser_Exists"
			%BEQ% :ULDR.GetIniKV.GetVal

		:: Check If Parser exists, set state then Get Key and Value, else show no parser fatal error message and exit.
		%FEX% "%uldr.config.iniParser%"
			%JEQ% :ULDR.GetIniKV.SetState
			%BNE% :ULDR.GetIniKV.NoParser
			%BRA% :ULDR.GetIniKV.GetVal
	}

	:ULDR.GetIniKV.SetState
		:: sets parser existence state, reduces filesystem load.
		%MOV% uldr.state.IniParser "Parser_Exists"
		%RTS%

	:ULDR.GetIniKV.NoParser
		%JSR% :ULDR.DisplayMessage "%uldr.error[0005]%"
		%JSR% :ULDR.Delay 5
		%BRK% 5

	:ULDR.GetIniKV.GetVal {
		:: Clear result before Query.
		%MOV% uldr.return.GetIniKV ""
		:: Call external Parser with key and value, return error level, and pipe stdout (return value) to file.
    	%JSR% "%uldr.config.iniParser%" "%uldr.config.iniFile%" "%1" "%2" > "%TEMP%\uldr_ini_output.tmp"
		:: Catch stderr from ini parser.
		%MOV% uldr.GetIniKV.iniError "%errorlevel%"
		:: Route to error handler on missing file, missing data etc, or process and return result.
		%CMP% %uldr.GetIniKV.iniError% 0
			%BNE% :ULDR.GetIniKV.HandleError
			%BRA% :ULDR.GetIniKV.GetReturnResult
	}

	:ULDR.GetIniKV.HandleError
		::	Display IniParser Error, injecting error into the string wiht double %% expansion, delete IniParser temp file, break with exit code.
		%JSR% :ULDR.DisplayMessage "%%uldr.error[000%uldr.GetIniKV.iniError%]%%"
		del "%TEMP%\uldr_ini_output.tmp" 2>nul
		%JSR% :ULDR.Delay 5
		%BRK% %uldr.GetIniKV.iniError%
	
	:ULDR.GetIniKV.GetReturnResult
		: Read temp file output from ini parser, store value in result, delete temp file, exit.
		set /p uldr.return.GetIniKV=<"%TEMP%\uldr_ini_output.tmp"
		del "%TEMP%\uldr_ini_output.tmp" 2>nul
		%BRA% :ULDR.GetIniKV.Exit

	:ULDR.GetIniKV.Destruct
		%MOV% uldr.GetIniKV.iniError ""
		%BRA% :ULDR.GetIniKV.Exit

	:ULDR.GetIniKV.Exit
    	%RTS%
}

:ULDR.LoadConfig {
	%BRA% :ULDR.LoadConfig.Dispatcher

	:ULDR.LoadConfig.Dispatcher {
		%CMP% "%1" "Destruct"
			%BEQ% :ULDR.LoadConfig.Destruct
		
		%JSR% :ULDR.LoadConfig.Init %1
		%JSR% :ULDR.LoadConfig.Loop %uldr.config.KeyArray%
		%BRA% :ULDR.LoadConfig.Exit
	}

	:ULDR.LoadConfig.Loop {
		%JSR% :ULDR.GetIniKV %uldr.config.LoadType% %1
		%MOV% uldr.config.%1 "%uldr.return.GetIniKV%"
		%SAL%

		%CMP% "%1" ""
			%BEQ% :ULDR.LoadConfig.LoopExit
			%BRA% :ULDR.LoadConfig.Loop

		:ULDR.LoadConfig.LoopExit
			%RTS%
	}

	:ULDR.LoadConfig.Init {
		%CMP% %1 user
			%BEQ% :ULDR.LoadConfig.Init.User
			%BRA% :ULDR.LoadConfig.Init.App

		:ULDR.LoadConfig.Init.User
			%JSR% :ULDR.DisplayMessage "%uldr.msg[0009]%"
			%MOV% uldr.config.KeyArray "exitDelay debug hideTerminal browserPath"
			%MOV% uldr.config.LoadType user 
			%RTS%

		:ULDR.LoadConfig.Init.App
			%JSR% :ULDR.DisplayMessage  "%uldr.msg[0010]% %1"
			%MOV% uldr.Config.KeyArray "appName port ip path loaderScript splashImage splashAnimationSpeed browserArgs maxTriesHTTP"
			%MOV% uldr.config.LoadType "%1"
			%RTS%
	}

	:ULDR.LoadConfig.Destruct {
		%JSR% %pULDR.MMU.Free% uldr.config
		%BRA% :ULDR.LoadConfig.Exit
	}

	:ULDR.LoadConfig.Exit
		%RTS%
}

:: -- Main Application Functions

:ULDR.ControlSplash {
	:: Controls the Splash loader display and quit routines through its IPC file.
	%BRA% :ULDR.ControlSplash.Dispatcher %1

	:ULDR.ControlSplash.Dispatcher {
		%CMP% "%1" "init"
			%BEQ% :ULDR.ControlSplash.RegisterMethods

		%CMP% "%1" "Destruct"
			%BEQ% :ULDR.ControlSplash.Destruct

		%CMP% %uldr.State.Splash% init.Done
			%BEQ% :ULDR.ControlSplash.Load

		%CMP% %uldr.State.Splash% load.Done
			%BEQ% :ULDR.ControlSplash.Display

		%CMP% %uldr.State.Splash% display.Done
			%BEQ% :ULDR.ControlSplash.Quit

		%JSR% :ULDR.DisplayMessage "%uldr.error[0006]%"
		exit 6
	}

	:ULDR.ControlSplash.RegisterMethods {
		%MOV% ULDR.ControlSplash.Update ":ULDR.ControlSplash"
		%MOV% ULDR.ControlSplash.Done ":ULDR.ControlSplash Destruct"
		%MOV% uldr.State.Splash "init.Done"
		%BRA% :ULDR.ControlSplash.Exit
	}

	:ULDR.ControlSplash.Load
		%JSR% :ULDR.DisplayMessage "%uldr.msg[0006]%"
		%JFR% /b %uldr.config.splashExe% %uldr.config.appPath%\%uldr.config.splashImage% %uldr.config.appPath%\%uldr.config.splashIPCFile% %uldr.config.splashAnimationSpeed%
		%MOV% uldr.State.Splash "load.Done"
		%BRA% :ULDR.ControlSplash.Exit

	:ULDR.ControlSplash.Display
		%JSR% :ULDR.DisplayMessage "%uldr.msg[0007]%"
		echo display > %uldr.config.appPath%\%uldr.config.splashIPCFile%
		%MOV% uldr.State.Splash "display.Done"
		%BRA% :ULDR.ControlSplash.Exit

	:ULDR.ControlSplash.Quit
		%JSR% :ULDR.DisplayMessage "%uldr.msg[0008]%"
		echo quit > %uldr.config.appPath%\%uldr.config.splashIPCFile%
		%MOV% uldr.State.Splash "null"
		%BRA% :ULDR.ControlSplash.Exit

	:ULDR.ControlSplash.Destruct {
		%JSR% %pULDR.MMU.Free% ULDR.ControlSplash
		%BRA% :ULDR.ControlSplash.Exit
	}

	:ULDR.ControlSplash.Exit
		%RTS%
}

:ULDR.ControlTerminal {
	%BRA% :ULDR.ControlTerminal.Dispatcher

	:ULDR.ControlTerminal.Dispatcher {
		%CMP% "%1" "Init"
			%BEQ% :ULDR.ControlTerminal.RegisterMethods

		%CMP% "%1" "Destruct"
			%BEQ% :ULDR.ControlTerminal.Destruct

		:: Exit If Disabled is set in config.
		%CMP% "%uldr.config.hideTerminal%" "Disabled"
			%BEQ% :ULDR.ControlTerminal.Exit
	
		:: Flip State from Minimized to Restore
		%CMP% "%uldr.state.terminalWindow%" "Minimized"
			%BEQ% :ULDR.ControlTerminal.Restore

		:: Flip State from Restore to Minimized
		%CMP% "%uldr.state.terminalWindow%" "Restored"
			%BEQ% :ULDR.ControlTerminal.Minimize
		
		:: Catch Enabled or any initialized first other state = branch to default first 
		%BRA% :ULDR.ControlTerminal.Minimize
	}

	:ULDR.ControlTerminal.RegisterMethods
		%MOV% ULDR.ControlTerminal.Flip ":ULDR.ControlTerminal Flip"
		%MOV% ULDR.ControlTerminal.Done ":ULDR.ControlTerminal Destruct"
		%BRA% :ULDR.ControlTerminal.Exit

	:ULDR.ControlTerminal.Minimize
		:: Don't vanish in an instant like suspicious software.
		%JSR% :ULDR.Delay 2
		%JSR% %uldr.config.minResExe% Minimize
		%MOV% uldr.state.terminalWindow "Minimized"
		%BRA% :ULDR.ControlTerminal.Exit

	:ULDR.ControlTerminal.Restore
		%JSR% %uldr.config.minResExe% Restore
		%MOV% uldr.state.terminalWindow "Restored"
		%BRA% :ULDR.ControlTerminal.Exit

	:ULDR.ControlTerminal.Destruct
		%JSR% %pULDR.MMU.Free% ULDR.ControlTerminal
		%BRA% :ULDR.ControlTerminal.Exit

	:ULDR.ControlTerminal.Exit
		%RTS%
}

:ULDR.ControlHTTPServer {	
	%BRA% :ULDR.ControlHTTPServer.Dispatcher

	:ULDR.ControlHTTPServer.Dispatcher {
		%CMP% "%1" "Init"
			%BEQ% :ULDR.ControlHTTPServer.RegisterMethods

		%CMP% "%1" "Start"
			%BEQ% :ULDR.ControlHTTPServer.Start

		%CMP% "%1" "Check"
			%BEQ% :ULDR.ControlHTTPServer.CheckProcedure

		%CMP% "%1" "Destruct"
			%BEQ% :ULDR.ControlHTTPServer.Destruct
		
		%JSR% :ULDR.DisplayMessage "%uldr.error[0007]%"
		exit 7
	}

	:ULDR.ControlHTTPServer.RegisterMethods {
		%MOV% ULDR.ControlHTTPServer.Start ":ULDR.ControlHTTPServer Start"
		%MOV% ULDR.ControlHTTPServer.Check ":ULDR.ControlHTTPServer Check"
		%MOV% ULDR.ControlHTTPServer.Done ":ULDR.ControlHTTPServer Destruct"
		%BRA% :ULDR.ControlHTTPServer.Exit
	}

	:ULDR.ControlHTTPServer.Start {		
		:: start msg, Open app in new terminal tab and return focus to our control flow tab.
		%JSR% :ULDR.DisplayMessage "%uldr.msg[0002]%"
		%JSR% wt --window 0 -d "%uldr.config.path%" --title "%uldr.config.appName%" "%uldr.config.powerShellExe%" "%uldr.config.path%\%uldr.config.loaderScript%"		
		%JSR% wt --window 0 focus-tab --target 0
		%BRA% :ULDR.ControlHTTPServer.Exit
		%RTS%
	}

	:ULDR.ControlHTTPServer.CheckProcedure {
		%JSR% :ULDR.DisplayMessage "%uldr.msg[0005]%"
		%JSR% :ULDR.ControlHTTPServer.PrepLoop
		%JSR% :ULDR.ControlHTTPServer.RunLoop
		%JSR% :ULDR.ControlHTTPServer.ExitLoop
		%BRA% :ULDR.ControlHTTPServer.Exit
	}

	:ULDR.ControlHTTPServer.PrepLoop {
		:: Assign default fail return, store flags and set loop counter to 0
		%MOV% uldr.return.CheckHTTPServerUP "False"
		%PUSHF%
		%LDX% %uldr.config.maxTriesHTTP%
		%RTS%
	}

	:ULDR.ControlHTTPServer.RunLoop {
		%JSR% :ULDR.DisplaySpinner "Probing Host: %uldr.config.ip%:%uldr.config.port%..." "2"
		:: Silently probe HTTP server and test stderr		
		%JSR% curl -s -o nul -I -f --max-time 1 http://%uldr.config.ip%:%uldr.config.port%
		%CMP% %errorlevel% 0
			%BNE% :ULDR.ControlHTTPServer.CheckMaxTries
			%BRA% :ULDR.ControlHTTPServer.IsUp

		:ULDR.ControlHTTPServer.MaxTriesExceeded
			%CMP% %uldr.gumInstalled% "False"
				%JEQ% :ULDR.MoveCursorUpNLines 1

			%JSR% :ULDR.DisplayMessage "%uldr.warn[0000]%"
			%RTS%

		:ULDR.ControlHTTPServer.IsUp
			%MOV% uldr.return.CheckHTTPServerUP "True"
			%CMP% %uldr.gumInstalled% "False"
				%JEQ% :ULDR.MoveCursorUpNLines 1

			%JSR% :ULDR.DisplayMessage "%uldr.msg[0001]%"
			%RTS%

		:ULDR.ControlHTTPServer.CheckMaxTries
			%DEX%
			%JSR% :ULDR.DisplaySpinner "Retries Remaining: %XR%..." "4"
			%CMP% %XR% 0
				%BEQ% :ULDR.ControlHTTPServer.MaxTriesExceeded
				%BRA% :ULDR.ControlHTTPServer.RunLoop
	}

	:ULDR.ControlHTTPServer.ExitLoop
		%POPF%
		%RTS%

	:ULDR.ControlHTTPServer.Destruct		
		%JSR% %pULDR.MMU.Free% ULDR.ControlHTTPServer		
		%BRA% :ULDR.ControlHTTPServer.Exit

	:ULDR.ControlHTTPServer.Exit
		%RTS%
}

:ULDR.LaunchBrowser {
	%BRA% :ULDR.LaunchBrowser.Dispatcher

	:ULDR.LaunchBrowser.Dispatcher {
		%CMP% "%1" "Init"
			%BEQ% :ULDR.LaunchBrowser.RegisterMethods

		%CMP% "%1" "Destruct"
			%BEQ% :ULDR.LaunchBrowser.Destruct

		:: Skip browser if skip debug variable set to true.
	 	%CMP% "%uldr.config.debug%" "True"
			%BEQ% :ULDR.LaunchBrowser.Skip

		:: Exit if Server is not running,
		%CMP% %uldr.return.CheckHTTPServerUP% True
			%BEQ% :ULDR.LaunchBrowser.Launch

		:: Catch, maybe trap with error.
		%BRA% :ULDR.LaunchBrowser.Exit
	}

	:ULDR.LaunchBrowser.RegisterMethods {
		%MOV% ULDR.LaunchBrowser.Do ":ULDR.LaunchBrowser Do"
		%MOV% ULDR.LaunchBrowser.Done ":ULDR.LaunchBrowser Destruct"
		%BRA% :ULDR.LaunchBrowser.Exit
	}

	:ULDR.LaunchBrowser.Skip
		:: Browser skip msg.
		%JSR% :ULDR.DisplayMessage "%uldr.msg[0004]%"
		%BRA% :ULDR.LaunchBrowser.Exit

	:ULDR.LaunchBrowser.Launch {
		:: Launch Message.	
		%JSR% :ULDR.DisplayMessage "%uldr.msg[0003]%"

		:: Launch Browser App with app profile.
		%JFR% "%uldr.config.appName%" "%uldr.config.browserPath%" %uldr.config.browserArgs%
		%BRA% :ULDR.LaunchBrowser.Exit
	}

	:ULDR.LaunchBrowser.Destruct {
		%JSR% %pULDR.MMU.Free% ULDR.LaunchBrowser
		%BRA% :ULDR.LaunchBrowser.Exit
	}
	
	:ULDR.LaunchBrowser.Exit
		%RTS%
}

:: -- Main Procedural Function

:_Main {
	:_Main.Procedure {
		%JSR% :_Main.Init
		%JSR% :ULDR.DisplayWelcomeMessage
		%JSR% :_Main.Configuration %1
		%JSR% :_Main.Orchestration
		%JSR% :ULDR.Bye
		%JSR% :_Main.DeallocateMemory
		%RTS%
	}

	:_Main.Init {
		:: Build namespace object, build first stage message array.
		%JSR% :ULDR.ManageNameSpace Init
		%JSR% :ULDR.ManageMessageTable
		%JSR% :ULDR.ControlSplash Init		
		%JSR% :ULDR.ControlHTTPServer Init
		%JSR% :ULDR.ControlTerminal Init
		%JSR% :ULDR.LaunchBrowser Init
		%RTS%
	}

	:_Main.Configuration {
		:: General configuration, pulls in variables from the ini file, builds second stage message array
		%JSR% :ULDR.CheckGumInstalled
		%JSR% :ULDR.LoadConfig user
		%JSR% :ULDR.LoadConfig %1
		%JSR% :ULDR.ManageMessageTable
		%RTS%
	}

	:_Main.Orchestration {
		:: Perform actions: [Terminal: Flip Minimize <> Restore], [Splash State: load >> Display >> Quit]
		%JSR% %ULDR.ControlSplash.Update%
		%JSR% %ULDR.ControlHTTPServer.Start%
		%JSR% %ULDR.ControlSplash.Update%
		%JSR% %ULDR.ControlTerminal.Flip%
		%JSR% %ULDR.ControlHTTPServer.Check%
		%JSR% %ULDR.ControlTerminal.Flip%
		%JSR% %ULDR.ControlSplash.Update%
		%JSR% %ULDR.LaunchBrowser.Do%
		%RTS%
	}

	:_Main.DeallocateMemory {
		%JSR% %ULDR.ControlSplash.Done%		
		%JSR% %ULDR.ControlHTTPServer.Done%
		%JSR% %ULDR.ControlTerminal.Done%		
		%JSR% %ULDR.LaunchBrowser.Done%		
		%JSR% :ULDR.GetIniKV Destruct
		%JSR% :ULDR.CheckGumInstalled Destruct
		%JSR% :ULDR.LoadConfig Destruct		
		%JSR% :ULDR.ManageMessageTable
		%JSR% %ULDR.ManageNameSpace.Done%
		%RTS%
	}
}

:: -- The End

:_end