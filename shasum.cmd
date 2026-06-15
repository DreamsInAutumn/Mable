:sysInit {
    @echo off
	:: Import Libraries
	set "assemblyLibrary=assembly.library.cmd"
	call %assemblyLibrary% import 1.1

	:: jump to entry point
	%BRA% _main	

	:: exit failsafe if import fails.
	cls
	echo. & echo [Fatal] Import Failure.
	goto _end
}

:shaSum {
    :: performs sha 256 or 512 on input file
    :: arg 1 = file, arg 2 - number of bits
    echo Performing %2 hash on %1...
    certUtil -hashfile %1 %2
    %RTS%
}

:displayMsg {
    :: displays specific error message and a generic info line
    echo.
    echo [error] %~1
    echo  - valid inputs are filename + 256 or 512 for SHA256 and SHA512
    %RTS%
}

:__appMain.RemovedCode {
   :: test if input was 256, if true, perform shasum, then exit
    %CMP% "%2" "256"
        %JEQ% :shaSum %1 SHA256
        %BEQ% :appMain.exit

    :: test if input was 512, if true, perform shasum, then exit
    %CMP% "%2" "512"
        %JEQ% :shaSum %1 SHA512        
        %BEQ% :appMain.exit


    :: handles uncaught exception: file exists, but neither numeric input is valid
    :: pass error string to output function
    %JSR% :displayMsg "Invalid or missing bit lenght"

}


:appMain {
    :: test if input file exists, show error if not and then exit
    %FEX% "%1"
        %JNE% :displayMsg "file not found"
        %BNE% :appMain.exit 

    :: test if input was 512, if not assume 256
    %CMP% "%2" "512"
        %JEQ% :shaSum %1 SHA512
	%JNE% :shaSum %1 SHA256

    :appMain.exit
    %RTS%
}

:_main {
    %JSR% :appMain %1 %2
    %BRA% :_end
}

:_end

