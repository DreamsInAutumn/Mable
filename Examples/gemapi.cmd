:: -- system intialization --

:_sysInit (
	@echo off
	cls
	:: import core library
	set "appVer=0.45a"
	set "assemblyLibrary=assembly.library.cmd"
	call :_importCoreLib %assemblyLibrary%
	:: The one and only literal goto!
	goto _main
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

:: -- application functions --

:appInit (
	:: configuration file
	set "configFile=gemapi.conf"	

	:: basic messages
	set "welcomeMessage=Gemini CLI Loader %appVer%"

	:: error messagse
	set "err[0x0001]=[Fatal] API Key file not found."
	set "err[0x0002]=[Fatal] API Key not found in API key file."
	set "err[0x0003]=[Fatal] Config file not found."

	:: declare app  globals	
	set "appState="

	:: declare app constants
	set "LoaderDelay=2"

	:: change directory to the script location (where config is)
	cd %~dp0

	%RET%
)

:setAppState (
	:: external variable set: avoids delayed expansion issues.
	set "appState=%1"
	%RET%
)

:loadConfig_SetElement (
	:: check if heading, or key=value, skip if heading (no value)
	%CMP% "%2" ""
		%BEQ% loadConfig_SetElement_Skip

	set "%1=%2"
	:loadConfig_SetElement_Skip
	%RET%
)

:loadConfig_ElementLoop (
	:: loop: load key/value lines from config into globals, pass to set function
	:: Push / Pop make logical code sense nested in "loadConfig_SetElement", placed externally to lessen being called inside the loop.
	:: - we save the state to preserve the outer comparrison in loadConfig from the comparrison in "loadConfig_SetElement"
	%PUSHF%	
		for /f "usebackq tokens=1,* delims==" %%a in ("%configFile%") do (
			%JSR% :loadConfig_SetElement %%a %%b			
		)	
	%POPF%
	%RET%
)

:loadConfig (
	:: test if config exists:
	:: -true: call load each element
	:: -false set specific error
	:: output message for true/false
	%FEX% "%configFile%"
		%JEQ% :loadConfig_ElementLoop
		%JNE% :setAppState 0x0003

	%JSR%  :outputMessage "[%appState%] Loading Config"
	%RET%
)

:loadAPIKey_SetKey (
	set /p GEMINI_API_KEY=<%apiKeyFile%	
	%RET%
)

:loadAPIKey (
	:: Loads the API key from file
	:: test file exist: true: call setvar sub, false: call set error code sub
	%FEX% "%apiKeyFile%"
		%JEQ% :loadAPIKey_SetKey
		%JNE% :setAppState 0x0001

	%JSR%  :outputMessage "[%appState%] Loading API Key"
	%RET%
)

:checkAPIKey (
	:: Checks if the API key file contains *any* data
	:: Error State: set specific error if key data is empty	
	%CMP% "%GEMINI_API_KEY%" ""
		%JEQ% :setAppState 0x0002
	
	%JSR%  :outputMessage "[%appState%] Checking API Key"
	%RET%
)

:outputMessage_Sub (
	echo.	
	%RET%
)

:outputMessage (
	:: strip quotes from %1 arg and output.
	:: check for new line arg %2, call sub to print newline	
	echo.%~1
	%CMP% "%~2" "nl"
		%JEQ% :outputMessage_Sub

	%RET%
)

:delayTimer (
	:: basic universal silent delay
	timeout -t %1 > nul
	%RET%
)

:runApp (
	:: dispalay message and run an external application pased as ARG_1, skip over execution if we are in debug mode
	%JSR% :outputMessage "[%appState%] Launching Gemini CLI..." "nl"
	%JSR% :delayTimer %LoaderDelay%
	%CMP% %debug% true	
		%JNE% %appName%
		%JEQ% :outputMessage "Debug Mode, execution skipped"

	%RET%
)

:: -- main function --

:_main (
	:: Initialize constants, global varaibles
	%JSR% :appInit

	:: Say hi
	%JSR% :outputMessage "%welcomeMessage%" "nl"

	:: Set 'local' state variable to "ok": the happy state
	%JSR% :setAppState ok

	:: try to load Config, if it didn't load, bail to error handler, else continue	
	%JSR% :loadConfig	
	%CMP% %appState% ok
		%BNE% :_main.handleError

    :: try to load API key file, if it didn't load, bail to error handler, else continue
	%JSR% :loadAPIKey
	%CMP% %appState% ok
		%BNE% :_main.handleError

    :: check API key has a value, if it does not, bail to error handler, else continue
	%JSR% :checkAPIKey
	%CMP% %appState% ok 
		%BNE% :_main.handleError

	:: the holy grail safe to run Gemini
	%JSR% :runApp
	%BRA% :_main.bye

	:: display specific application error using state
:_main.handleError
	%JSR% :outputMessage "%%err[%appState%]%%"	

:_main.bye
	:: Adois	
	%JSR% :outputMessage "%byeMessage%" nl
	%BRA% _end
)

:: -- the end --

:_end
