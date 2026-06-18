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
		set "uldr.appver=v2.10a"
		set "uldr.appPath=%~dp0"
		set "uldr.powerShellExe=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

	:: Ini Parser Config
		set "uldr.iniParser=%uldr.appPath%bin\iniparser.exe"
    	set "uldr.iniFile=%uldr.appPath%uniloader.ini"

	:: Minimize / Restore
		set "uldr.minResExe=%uldr.appPath%bin\minres.exe"

	:: Splash Config		
		set "uldr.splashExe=%uldr.appPath%bin\splash2.exe"
		set "uldr.splashIPCFile=splash.IPC"

	:: -- Browser Launch Config !! do not alter quoting !!
		set uldr.browserPath="C:\Program Files\BraveSoftware\Brave-Browser\Application\chrome_proxy.exe"

	:: -- Initialize Function Return Values
		set CheckHTTPServerUP.Return=False
	%RTS%
}

:InitMessageTable {
	:: LowLevel error messages must be avilable before the data is ready to populate the messages in the Main section.
	%CMP% %1 LowLevel
		%BEQ% :InitMessageTable.LowLevel

	%CMP% %1 Main
		%BEQ% :InitMessageTable.Main

	%RTS%

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
		set "uldr.error[0000]=[FATAL ] Error: Valid Application name must be supplied in the shortcut."
		set "uldr.error[0001]=[FAILED] Timed out waiting for the Application server to start."
		set "uldr.error[0002]=[FATAL ] Invalid arguments passed to ini Parser."
		set "uldr.error[0003]=[FATAL ] Ini file was not found."
		set "uldr.error[0004]=[FATAL ] Ini file Section not found."
		set "uldr.error[0005]=[FATAL ] Ini file Key not found."
		set "uldr.error[0006]=[FATAL ] Ini file Parser not found."

		:: Warnings
		set "uldr.warn[0000]=[ WARN ] invalid Splash State."
		set "uldr.warn[0001]=[ WARN ] invalid Terminal State."

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

:ShowWelcomeMessage {	
	%JSR% :DisplayMessage "%uldr.msg[0000]% %uldr.appver%" NL_Post
	%RTS%
}

:Bye {	
	%JSR% :Delay %uldr.appDelay%

	:: Pauses if debug enabled
	%CMP% %uldr.debug% True
		%JEQ% :PauseApp

	echo.
	:: echo Bye.
	%JSR% :DisplayMessage "Bye."
	%JSR% :Delay 2
	%RTS%
}

:DisplayMessage {
	:: Preserve flags
	%PUSHF%

	:: Expand arguments for readability,.
	set "DisplayMessage.msg=%~1"
	set "DisplayMessage.operation=%~2"

	:: New Line Branch Table	
	%CMP% "%DisplayMessage.operation%" "NL_Pre"
		%BEQ% :DisplayMessage.NL_Pre

	%CMP% "%DisplayMessage.operation%" "NL_Post"
		%BEQ% :DisplayMessage.NL_Post

	%CMP% "%DisplayMessage.operation%" "NL_Both"
		%BEQ% :DisplayMessage.NL_Both

	%BRA% :DisplayMessage.NL_None
	
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

:: -- Core Application Functions

:UpdateSplash {
	::
	%CMP% "%~1" "init"
		%BEQ% :UpdateSplash.Init

	%CMP% %uldr.splash.State% init.Done
		%BEQ% :UpdateSplash.Load

	%CMP% %uldr.splash.State% load.Done
		%BEQ% :UpdateSplash.Display

	%CMP% %uldr.splash.State% display.Done
		%BEQ% :UpdateSplash.Quit

	:: Exception: Fall-through
	%JSR% :DisplayMessage "%uldr.warn[0000]%"
	%RTS%

	:UpdateSplash.Init		
		set "uldr.splash.State=init.Done"
		%RTS%

	:UpdateSplash.Load
		%JSR% :DisplayMessage "%uldr.msg[0006]%"		
		%JFR% /b %uldr.splashExe% %uldr.splashImage% %uldr.splashIPCFile%
		set "uldr.splash.State=load.Done"
		%RTS%

	:UpdateSplash.Display
		%JSR% :DisplayMessage "%uldr.msg[0007]%"
		echo display > %uldr.splashIPCFile%	
		set "uldr.splash.State=display.Done"
		%RTS%

	:UpdateSplash.Quit
		%JSR% :DisplayMessage "%uldr.msg[0008]%"
		echo quit > %uldr.splashIPCFile%
		set "uldr.splash.State=null"
		%RTS%
}

:ControlTerminal {
	:: Is Disabled?, exit if so
	%CMP% "%uldr.controlTerminal.state%" "Disabled"
		%BEQ% :ControlTerminal.Exit

	:: State initialization check, initialize state variable or jump to toggles
	%CMP% "%1" "Init"
		%BEQ% :ControlTerminal.Init

	:: State check : Minimized
	%CMP% "%uldr.controlTerminal.state%" "Minimized"
		%BEQ% :ControlTerminal.Restore

	:: State check : Restored
	%CMP% "%uldr.controlTerminal.state%" "Restored"
		%BEQ% :ControlTerminal.Minimize

	:: ControlTerminal Fallthrough State Safety and warn message
	%JSR% :DisplayMessage "%uldr.warn[0001]%"
	%RTS%

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

	: open app in new terminal tab, then return tab focus back to the first tab.	
	wt --window 0 -d "%uldr.path%" --title "%uldr.appName%" "%uldr.powerShellExe%" "%uldr.LoaderScript%"
	wt --window 0 focus-tab --target 0

	%RTS%
}

:CheckHTTPServerUP {
	%JSR% :DisplayMessage "%uldr.msg[0005]%"

	:: Pre optimize HTTP Return state to false
	set CheckHTTPServerUP.Return=False

	:: Store CPU flags and set loop counter to 0
	%PUSHF%
	%LDX% 0

	:CheckHTTPServerUP.Loop
		:: Probe HTTP Server and test error output
		curl -s -o nul -I -f --max-time 1 http://%uldr.ip%:%uldr.port%
		%CMP% %errorlevel% 0
			%BEQ% :CheckHTTPServerUP.True
			%BNE% :CheckHTTPServerUP.False

		:CheckHTTPServerUP.True
			:: Display server Up message, set state and exit
			%JSR% :DisplayMessage "%uldr.msg[0001]%" NL_Pre
			set CheckHTTPServerUP.Return=True
			%BRA% :CheckHTTPServerUP.Exit

		:CheckHTTPServerUP.False
			:: Increment loop counter, then check max tries
			%INX%
			%CMP% %XR% %uldr.maxTriesHTTP%
				%BEQ% :CheckHTTPServerUP.Timeout
				%BNE% :CheckHTTPServerUP.Continue

		:CheckHTTPServerUP.Timeout
			:: Output timeout error and exit
			%JSR% :DisplayMessage "%uldr.error[0001]%" NL_Pre
			%BRA% :CheckHTTPServerUP.Exit

		:CheckHTTPServerUP.Continue
			:: Display moving dot per failed HTTP probe
			echo|set /p="."
			%JSR% :delay 1

	%BRA% :CheckHTTPServerUP.Loop

	:CheckHTTPServerUP.Exit
		:: Resstore flags after compare
		%POPF%
	%RTS%
}

:LaunchBrowser {
	 :: Skip browser if skip  variable set.
	 %CMP% "%uldr.debug%" "True"
		%BNE% :LaunchBrowser.Try
		%BEQ% :LaunchBrowser.Skip

	:: Try to launch if server is Up.
	:LaunchBrowser.Try
		%CMP% %CheckHTTPServerUP.Return% True
			%BNE% :LaunchBrowser.Exit

		:: Launch Message		
		%JSR% :DisplayMessage "%uldr.msg[0003]%" 
		%JSR% :delay %uldr.browserDelay%

		:: Launch Browser App with app profile
		%JFR% "%uldr.appName%" %uldr.browserPath% %uldr.browserArgs%
		%RTS%

	:LaunchBrowser.Skip
		:: Browser skip msg		
		%JSR% :DisplayMessage "%uldr.msg[0004]%"
		%RTS%

	:: Safety-net
	:LaunchBrowser.Exit
	%RTS%
}

:ReadIniKV.ErrorHandler {
	set "uldr.iniError=%1"

	%CMP% %uldr.iniError% 0
		%BEQ% :ReadIniKV.ErrorHandler.OK

	%CMP% %uldr.iniError% 1
		%BEQ% :ReadIniKV.ErrorHandler.Arg

	%CMP% %uldr.iniError% 2
		%BEQ% :ReadIniKV.ErrorHandler.File

	%CMP% %uldr.iniError% 3
		%BEQ% :ReadIniKV.ErrorHandler.Section

	%CMP% %uldr.iniError% 4
		%BEQ% :ReadIniKV.ErrorHandler.Key

	%RTS%

	:ReadIniKV.ErrorHandler.OK
        set /p uldr.iniResult=<"%TEMP%\uldr_ini_output.tmp"
		%BRA% :ReadIniKV.ErrorHandler.Exit

	:ReadIniKV.ErrorHandler.Arg
		%JSR% :DisplayMessage "%uldr.error[0002]%" NL_Post
		%BRA% :ReadIniKV.ErrorHandler.Break

	:ReadIniKV.ErrorHandler.File
		%JSR% :DisplayMessage "%uldr.error[0003]%" NL_Post
		%BRA% :ReadIniKV.ErrorHandler.Break

	:ReadIniKV.ErrorHandler.Section
		%JSR% :DisplayMessage "%uldr.error[0004]%" NL_Post
		%BRA% :ReadIniKV.ErrorHandler.Break

	:ReadIniKV.ErrorHandler.Key
		%JSR% :DisplayMessage "%uldr.error[0005]%" NL_Post
		%BRA% :ReadIniKV.ErrorHandler.Break	

	:ReadIniKV.ErrorHandler.Break
		del "%TEMP%\uldr_ini_output.tmp" 2>nul
		%JSR% :PauseApp
		%BRK%

	:ReadIniKV.ErrorHandler.Exit
		del "%TEMP%\uldr_ini_output.tmp" 2>nul
		%RTS%
}

:ReadIniKV {
	:: Test if Ini FIle Exists
	%FEX% "%uldr.iniParser%"
		%BEQ% :ReadIniKV.Read
		%BNE% :ReadIniKV.NoParser

	:: Call external Parser with key and value, return error level, and pipe stdout (return value) to file.
	:ReadIniKV.Read
		:: Clear Result Before Query
    	set "uldr.iniResult="
    	%JSR% "%uldr.iniParser%" "%uldr.iniFile%" "%1" "%2" > "%TEMP%\uldr_ini_output.tmp"
		%JSR% :ReadIniKV.ErrorHandler %errorlevel%
		%BRA% :ReadIniKV.Exit

	:ReadIniKV.NoParser
		%JSR% :DisplayMessage "%uldr.error[0006]%"
		%JSR% :PauseApp
		%BRK% 6

	:ReadIniKV.Exit
    	%RTS%
}

:LoadUserConfig {
	:: Loading
	%JSR% :DisplayMessage "%uldr.msg[0009]%"

	:: Delay before browser starts, allows user to read our console messages briefly.
	%JSR% :ReadIniKV user browserDelay
	set "uldr.browserDelay=%uldr.iniResult%"

	:: Delay before exiting.
	%JSR% :ReadIniKV user appDelay
	set "uldr.appDelay=%uldr.iniResult%"

	:: Number of retries to check if the HTTP Server is up.
	%JSR% :ReadIniKV user maxTriesHTTP
	set "uldr.maxTriesHTTP=%uldr.iniResult%"

	:: Pauses at the end, and disables the Browser Launch.
	%JSR% :ReadIniKV user debug
	set "uldr.debug=%uldr.iniResult%"

	:: options: Disabled / Void.
	%JSR% :ReadIniKV user controlTerminal.state
	set "uldr.controlTerminal.state=%uldr.iniResult%"
	%RTS%
}

:LoadExternalAppConfig {
	:: Loading Message
	%JSR% :DisplayMessage "%uldr.msg[0010]%"

	:: loads: AppName, Port, IP, Path, Loader Script, Splash Image, and Browser Arguments
	%JSR% :ReadIniKV %1 AppName
	set "uldr.appName=%uldr.iniResult%"

	%JSR% :ReadIniKV %1 port
	set "uldr.port=%uldr.iniResult%"

	%JSR% :ReadIniKV %1 ip
	set "uldr.ip=%uldr.iniResult%"

	%JSR% :ReadIniKV %1 path
	set "uldr.path=%uldr.iniResult%"

	%JSR% :ReadIniKV %1 loaderScript
	set "uldr.loaderScript=%uldr.path%\%uldr.iniResult%"

	%JSR% :ReadIniKV %1 splashImage
	set "uldr.splashImage=%uldr.appPath%%uldr.iniResult%"

	%JSR% :ReadIniKV %1 browserArgs
	set "uldr.browserArgs=%uldr.iniResult%"

	%RTS%
}

:: -- Main Procedural Function

:_main {
	:: Initialization

	%JSR% :InitNameSpace					:: Initialize this.application variable namespace.
	%JSR% :InitMessageTable LowLevel		:: Initialize Low Level message strings.
	%JSR% :ShowWelcomeMessage
	%JSR% :LoadExternalAppConfig %1			:: Load configuration variables for specific external HTTP Application.
	%JSR% :LoadUserConfig					:: Loads user configuration data from the ini file.
	%JSR% :InitMessageTable Main			:: Initialize Main application message strings.	
	::%JSR% :LoadUserConfig					:: Loads user configuration data from the ini file.

	%JSR% :UpdateSplash	Init				:: Splash State Initialization.
	%JSR% :ControlTerminal Init				:: Terminal state Initialization.

	:: Body
	%JSR% :UpdateSplash						:: Splash state transition: Loads splash image application in the background, waits for IPC commands.
	%JSR% :StartHTTPServer					:: Start HTTP Server for AI Application.
	%JSR% :UpdateSplash						:: Splash state transition: Sends Display IPC Command to the Splash Application.
	%JSR% :ControlTerminal					:: Terminal State transition: Minimize Terminal.
	%JSR% :CheckHTTPServerUP				:: Check if server is up (loop with max).

	:: Exit
	%JSR% :ControlTerminal					:: Terminal State transition: Restore Terminal
	%JSR% :UpdateSplash						:: Splash state transition: Sends Quit IPC Command to the Splash Application.
	%JSR% :LaunchBrowser					:: Try to Launch Browser Application, Displays Browser IP/URL if Disabled in config.
	%JSR% :Bye								:: Wave.
	%RTS%
}

:: -- The End

:_end