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

	Features:
		Load desired app in a separate wt tab
		Windows Terminal - because pretty colored text.
		Opens App as a Browser stored application without the Browser Chrome, creating a more native application feel.
		Adds a pretty graphical splash while loading.
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
	:: -- User Config
		set "uldr.browserDelay=3"					:: Delay before browser starts, allows user to read our console messages breifly.
		set "uldr.appDelay=6"						:: Delay before exiting
		set "uldr.maxTriesHTTP=60"					:: Number of retrie to check if the HTTP Server is CheckServerRunning
		set "uldr.debug=False"						:: Pauses at the end, and disables the Browser Launch
		set "uldr.minMaxTerminal.state=void"		:: options: Disabled / Void

	:: -- App List
		set "uldr.app[0]=ComfyUI_3"
		set "uldr.app[1]=SillyTavern"

	:: Internal Config
		set "uldr.appver=v2.04a"		
		set "uldr.appPath=%~dp0"
		set "uldr.powerShellExe=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

	:: Splash Config		
		set "uldr.splashExe=%uldr.appPath%bin\splash2.exe"		
		set "uldr.splashIPCFile=splash.IPC"

	:: -- Browser Launch Config !! do not alter quoting !!
		set uldr.browserPath="C:\Program Files\BraveSoftware\Brave-Browser\Application\chrome_proxy.exe"

	:: -- Initialize Function Return Values
		set checkServerRunning.Return=False
	%RTS%
}

:Init_ComfyUI3 {
	:: --- Web Server Config
		set "uldr.port=8188"
		set "uldr.ip=127.0.0.1"

	:: -- Web App Config
		set "uldr.appName=ComfyUI_3"
		set "uldr.path=L:\comfy_ui_3"
		set "uldr.loaderScript=%uldr.path%\_start.bat"

	:: -- Splash Config
		set "uldr.splashImage=%uldr.appPath%img\comfyui-02-splash.jpeg"
	
	:: --- Browser Launch Config ---
		set "uldr.browserArgs=--profile-directory=Default --app-id=fdfllangmneamcbmopcnemepphpfaihc"

	%RTS%
}

:Init_SillyTavern {
	:: -- Web Server Config
		set "uldr.port=8000"
		set "uldr.ip=127.0.0.1"

	:: -- Web App Config
		set "uldr.appName=SillyTavern"
		set "uldr.path=L:\SillyTavern"
		set "uldr.loaderScript=%uldr.path%\Start.bat"

	:: -- Splash Config
		set "uldr.splashImage=%uldr.appPath%img\tavern-splash-05.jpg"

	:: -- Browser Launch Config
		set "uldr.browserArgs=--profile-directory=Default --app-id=mngloiodpbedloingimookgdhhkgcblo"

	%RTS%
}

:InitMessageTable {
	:: LowLevel error messages must be aailable before the data is ready to populate the messages in the Main section.
	%CMP% %1 LowLevel
		%BEQ% :InitMessageTable.LowLevel

	%CMP% %1 Main
		%BEQ% :InitMessageTable.Main

	%RTS%

	:InitMessageTable.LowLevel
		:: Don't embed variables inside LowLevel error strings! Init sequence will prevent them being active.
		set "uldr.error[0000]=[FATAL ] Error: Valid Application name must be supplied in the shortcut."
		set "uldr.error[0001]=[FAILED] Timed out waiting for the Application server to start."

		set "uldr.warn[0000]=[ Warn ] invalid Splash State."
		set "uldr.warn[0001]=[ Warn ] invalid MinMax State."
		%RTS%

	:InitMessageTable.Main
		set "uldr.msg[0000]=Universal ML Loader (C) 2026 Autumn"
		set "uldr.msg[0001]=[  OK  ] %uldr.AppName% server is running!"
		set "uldr.msg[0002]=[ INFO ] Starting %uldr.AppName%..."
		set "uldr.msg[0003]=[ INFO ] Launching %uldr.AppName% browser app..."
		set "uldr.msg[0004]=[ INFO ] Browser opening disabled. Server available at: http://%uldr.IP%:%uldr.Port%"
		set "uldr.msg[0005]=[ INFO ] Waiting for %uldr.AppName% server..."		
		set "uldr.msg[0006]=[ INFO ] Starting Background Splash Application"
		set "uldr.msg[0007]=[ INFO ] Display Splash Screen"
		set "uldr.msg[0008]=[ INFO ] Shutdown Splash Application"

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

:: -- Core Applicatoin Functions

:UpdateSplash {
	::
	%CMP% "%~1" "init"
		%BEQ% :UpdateSplash.init

	%CMP% %uldr.splash.State% init.Done
		%BEQ% :UpdateSplash.load

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
		start /b %uldr.splashExe% %uldr.splashImage% %uldr.splashIPCFile%
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
		%RTS%
}

:MinMaxTerminal {
	:: Is Disbled?, exit if so
	%CMP% "%uldr.minMaxTerminal.state%" "Disabled"
		%BEQ% :MinMaxTerminal.Exit

	:: State initialization check, initialize state variable or jump to toggles
	%CMP% "%1" "Init"
		%BEQ% :MinMaxTerminal.Init

	:: State check : Min
	%CMP% "%uldr.minMaxTerminal.state%" "Minimized"
		%BEQ% :MinMaxTerminal.Maximize

	:: State check : Max
	%CMP% "%uldr.minMaxTerminal.state%" "Maximized"
		%BEQ% :MinMaxTerminal.Minimize

	:: MinMaxTerminal Falltrhough State Safety and warn message
	%JSR% :DisplayMessage "%uldr.warn[0001]%"
	%RTS%

	:MinMaxTerminal.Init
		set "uldr.minMaxTerminal.state=Maximized"
		%RTS%

	:MinMaxTerminal.Minimize
		:: Don't vanish in an instant like suspicious software.
		%JSR% :Delay 2
		powershell -Command "$api = Add-Type -MemberDefinition '[DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow(); [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Name 'Win32Active' -PassThru; $api::ShowWindow($api::GetForegroundWindow(), 6)" > nul 2>&1
		set "uldr.minMaxTerminal.state=Minimized"
		%BRA% :MinMaxTerminal.Exit

	:MinMaxTerminal.Maximize
		powershell -Command "$api = Add-Type -MemberDefinition '[DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Name 'Win32Restore' -PassThru; Get-Process -Name WindowsTerminal, WindowsTerminalPreview -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | ForEach-Object { $api::ShowWindow($_.MainWindowHandle, 9) }" > nul 2>&1
		set "uldr.minMaxTerminal.state=Maximized"
		%BRA% :MinMaxTerminal.Exit

	:MinMaxTerminal.Exit
	%RTS%
}

:ShowWelcomeMessage {	
	%JSR% :DisplayMessage "%uldr.msg[0000]% %uldr.appver%" NL_Post
	%RTS%
}

:StartHTTPServer {
	:: start msg
	%JSR% :DisplayMessage "%uldr.msg[0002]%"

	: open app in new terminal tab, then return tab focus back to the first tab.
	wt --window 0 -d %uldr.path% --title %uldr.AppName% %uldr.powerShellExe% %uldr.LoaderScript%
	wt --window 0 focus-tab --target 0

	%RTS%
}

:CheckServerRunning {
	%JSR% :DisplayMessage "%uldr.msg[0005]%"

	:: safely store flags for compare
	%PUSHF%

	:: Set X Register (XR) to 0 (loop counter)
	%LDX% 0

	:CheckServerRunning.Loop
		:: HTTP Server check via powershell
		powershell -command "try { $response = Invoke-WebRequest -Uri http://%uldr.IP%:%uldr.Port% -Method HEAD -TimeoutSec 1 -ErrorAction Stop -UseBasicParsing; if ($response.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"

		:: Check if powershell returned an error while probing the http server.
		%CMP% %errorlevel% 0
			%BEQ% :CheckServerRunning.IsRunning_True
			%BNE% :CheckServerRunning.IsRunning_False

		:CheckServerRunning.IsRunning_True
			:: Run message
			%JSR% :DisplayMessage "%uldr.msg[0001]%" NL_Pre
			set checkServerRunning.Return=True

			:: Branch to exit and restore flags
			%BRA% :CheckServerRunning.Exit

		:CheckServerRunning.IsRunning_False
			:: Increment loop counter
			%INX%
			set checkServerRunning.Return=False

			:: Check for max retries, show timeout message on max
			%CMP% %XR% %uldr.maxTriesHTTP%
				%BEQ% :CheckServerRunning.Timeout
				%BNE% :CheckServerRunning.Continue

		:CheckServerRunning.Timeout
			:: Output timout error
			%JSR% :DisplayMessage "%uldr.error[0001]%" NL_Pre
			%BRA% :CheckServerRunning.Exit

		:CheckServerRunning.Continue
			echo|set /p="."
			%JSR% :delay 1

	%BRA% :CheckServerRunning.Loop

	:CheckServerRunning.Exit
		:: Resstore flags after compare
		%POPF%
	%RTS%
}

:LaunchBrowser {
	 :: Skip browser if skip  variable set.
	 %CMP% "%uldr.debug%" "True"
		%BNE% :LaunchBrowser.Try
		%BEQ% :LaunchBrowser.Skip

	:: Try to launch if server is running.
	:LaunchBrowser.Try
		%CMP% %checkServerRunning.Return% True
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

:LoadAIAppVariables {
	:: Compare command line argument to lauch commands
	%CMP% "%1" "%uldr.app[0]%"
		%BEQ% :LoadAIAppVariables.ComfyUI_3

	%CMP% "%1" "%uldr.app[1]%"
		%BEQ% :LoadAIAppVariables.SillyTavern

	:: Fatal Exception Fall-through: Exit if no valid application name passed. Otherwise this is Branched over.
	%JSR% :DisplayMessage "%uldr.error[0000]%" NL_Post
	pause
	%BRK% 1

	:: Load specific variables for each application
	:LoadAIAppVariables.ComfyUI_3
		%JSR% :Init_ComfyUI3
		%BRA% :LoadAIAppVariables.Exit

	:LoadAIAppVariables.SillyTavern
		%JSR% :Init_SillyTavern
		%BRA% :LoadAIAppVariables.Exit

	:LoadAIAppVariables.Exit
	%RTS%
}

:: -- Main Procedural Function

:_main {
	:: Initialization
	%JSR% :InitNameSpace					:: Initialize this.application variable namespace.
	%JSR% :InitMessageTable LowLevel		:: Initialize Low Level message strings.
	%JSR% :LoadAIAppVariables %1			:: Load AI app specific variables from command line argument. ("Load" because maybe config file some day).
	%JSR% :InitMessageTable Main			:: Initialize Main application message strings.
	%JSR% :ShowWelcomeMessage
	%JSR% :UpdateSplash	Init				:: Splash State machine Initialization.
	%JSR% :MinMaxTerminal Init				:: MinMax state machine Initialization.

	:: Body
	%JSR% :UpdateSplash						:: Splash state transition: Loads splash image application in the background, waits for IPC commands.
	%JSR% :StartHTTPServer					:: Start HTTP Server for AI Application.
	%JSR% :UpdateSplash						:: Splash state transition: Sends Display IPC Command to the Splash Application.
	%JSR% :MinMaxTerminal					:: MinMax Terminal State transition: Minimize Terminal.
	%JSR% :CheckServerRunning				:: Check if server is running (loop with max).

	:: Exit
	%JSR% :MinMaxTerminal					:: MinMax Terminal State transition: Maximize Terminal
	%JSR% :UpdateSplash						:: Splash state transition: Sends Quit IPC Command to the Splash Application.
	%JSR% :LaunchBrowser					:: Try to Launch Browser Application, Displays Browser IP/URL if Disabled in config.
	%JSR% :Bye								:: Wave.
	%RTS%
}

:: -- The End

:_end
