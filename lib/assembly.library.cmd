:_PreInit {
	set "al.self=assembly.library.cmd"
	goto :_main
}

/*
	Macro Assembly Batch Library Extension: Mable
	---------------------------------------------

	Version 1.1.2	

	A poem to our pet Mai, sometimes lovingly called Mable.
	
	Purpose:
		Provide programmatic structure through an assembly-like Mnemonics to suggest Single Responsibility Principles.

	Intent and usage:
		The majority of Batch code is written in a catastrophically idiomatic style promoted by Microsoft themselves.
	(Go look at a DOS 5 manual, or Microsoft's 'Learn' Library for proof.)

		Avoid: Using setlocal / endlocal and enabledelayedexpansion hell
		Use: The CMP comparator instead and then branch / jump. 
		Use: scoped variables
			local function.var, function.return - clean up as you go.
			global applicationname.var

		CMP is itself is translated to a single nest, and then leaves keeping your code a simple flat never-nester heaven.
	
	For someone familiar with structured programming, and with a basic understanding of Assembly language: The provided
	examples show that by following organized principles, Batch scripts can have clear structure and explicit conditional logic.
	Batch can do it without	pseudo Assembly, of course... Yet people don't, they write tangled spaghettified tragedies.
	
	Thought consideration:
		When writing production-ready and maintainable code in assembly for archaic CPU's such as a 6502; an Assembly style
	pushes you harder to think in structured methodologies such as sub routines, unrolling nesting as much as possible (unless
	optimizing for performance), or the code quickly dissolves into chaos.

	Desirable Coding Style
		1. Use single responsibility functions where possible.
		2. The use of "Happy Path" stateful branching is encouraged.

	Contrivancy:
		Admittedly going down the path of stylistically using macro assembly principles for architecting system scripting
	could appear as excessive to some. If, however think about Batch code inside the scope of the application and not the
	library, resultant programs become easier to read and maintain when the principles are adhered to.
		Introducing branching via enhancing goto with conditions in a high level language may feel like a step backward. I
	counter that by asking that you apply the logical flow that macro assembly uses.
	
	Hope:
		My hope is that there will be fewer Batch tragedies.
*/

/*
	ToDo:
		1: Flag separation
			Migrate from pushing only flags, to pushing flags and registers separately
			PUSH: Pushes Registers and Flags
			PUSHF: Pushes Flags	

		3: RISC - CISC
			RISC - this wil be a pure RISC Library
			CISC - Move FEX into a new CISC library.
*/

/*
	Testing CX register
		safe branching with context switching by storing the fucntion name in CX
		PUSH POP on function entry / exit
		use internal functions %CX%.name
*/

:al.destructor {
	set "al.self="
	exit /b
}

:al.exportMnemonics_v1.1 {

	set "al.Initialized=True"

	:: unconditional jumps
		:: Jump to SubRoutine
		set "JSR=call"

		:: Jump FaR - used for external apps
		set "JFR=start %1 %2 %3 %4"

		:: probably should be: ...
		::set "JFR=start"

	:: termination
		:: RETurn - from subroutine
		set "RET=exit /b %1"

		:: Return To Sender
		set "RTS=exit /b %1"

	:: Flow / Sync Control
		set "NOP=REM"
		set "BRK=exit"

	:: microcode instructions - modifies jumps / branches as flags.
		:: CoMPare
		set "CMP=call %al.self% CMP"

		:: if File EXist
		set "FEX=call %al.self% FEX"

	:: register manipulation
		set "LDX=call %al.self% LDX"
		set "LDY=call %al.self% LDY"

	:: increment X Register: XR
		set "INX=call %al.self% INX"
		set "INY=call %al.self% INY"

	:: increment X Register: XR
		set "DEX=call %al.self% DEX"
		set "DEY=call %al.self% DEY"

	:: Move instruction
		set "MOV=call %al.self% MOV"

	:: stack instructions
		:: PUSH
		set "PUSHF=call %al.self% PUSHF"

		:: POP
		set "POPF=call %al.self% POPF"

		:: stack and pointer
		set "al.stack="
		set "al.sp=0"

	:: Registers
		:: current
		set "XR=0"
		set "YR=0"
		set "CX=null"

		:: unused
		set "AR=0"

	exit /b
}

:al.exportFlags_v1.1 {
	:: Not really flags, analogous in behavior, CMP microcode dynamically alters their behavior.
	:: branching
		:: unconditional BRAnch		
		set "BRA=GOTO"

		:: conditional: Branch if EQual
		set "BEQ=REM"

		:: conditional: Branch if Not Equal
		set "BNE=REM"

		:: conditional: Branch if Less Than
		set "BLT=REM"

		:: conditional: Branch if Greater Than
		set "BGT=REM"

	:: jumps
		:: conditional: Jump if EQual
		set "JEQ=REM"

		:: conditional: Jump if Not Equal
		set "JNE=REM"

		:: conditional: Jump if Less Than
		set "JLT=REM"

		:: conditional: Jump if Greater Than
		set "JGT=REM"

	exit /b
}

:: Load var into X, does not set any flags yet
:al.LDX {
	set /a "XR=%1"
	exit /b
}

:al.LDY {
	set /a "YR=%1"
	exit /b
}

:: increment X Register
:al.INX {
	set /a "XR+=1"
	exit /b
}

:: increment Y Register
:al.INY {
	set /a "YR+=1"
	exit /b
}

:: decrement X Register
:al.DEX {
	set /a "XR-=1"
	exit /b
}

:: decrement Y Register
:al.DEY {
	set /a "YR-=1"
	exit /b
}

:: Move %2 into %1. NOTE: %1 is named reference, and %2 is a value.
:al.MOV {	
	set "%~1=%~2"
	exit /b
}

:al.FEX {
	call set "JEQ=REM"
	call set "JNE=REM"
	call set "BEQ=REM"
	call set "BNE=REM"

	if exist %1 (
		call set "JEQ=call"
		call set "BEQ=goto"
	) else (
		call set "JNE=call"
		call set "BNE=goto"
	)
	exit /b
}

:al.PUSHF {
	:: increment stack pointer
	call set /a "al.sp+=1"

	:: push Branch flags
	call set "al.stack[%al.sp%].BEQ=%BEQ%"
	call set "al.stack[%al.sp%].BNE=%BNE%"
	call set "al.stack[%al.sp%].BLT=%BLT%"
	call set "al.stack[%al.sp%].BGT=%BGT%"

	:: push Jump flags
	call set "al.stack[%al.sp%].JEQ=%JEQ%"
	call set "al.stack[%al.sp%].JNE=%JNE%"
	call set "al.stack[%al.sp%].JLT=%JLT%"
	call set "al.stack[%al.sp%].JGT=%JGT%"

	:: push register(s)
	call set "al.stack[%al.sp%].XR=%XR%"
	call set "al.stack[%al.sp%].YR=%YR%"
	call set "al.stack[%al.sp%].CX=%CX%"
	call set "CX=null"

	exit /b
}

:al.POPF {
	:: **** stack underflow detection ****
	if "%al.sp%" EQU "0" (
		echo.[FATAL] Stack Underflow
		exit 2
	)

	:: pop branch flags
	call set "BEQ=%%al.stack[%al.sp%].BEQ%%"
	call set "BNE=%%al.stack[%al.sp%].BNE%%"
	call set "BLT=%%al.stack[%al.sp%].BLT%%"
	call set "BGT=%%al.stack[%al.sp%].BGT%%"

	:: pop jump flags
	call set "JEQ=%%al.stack[%al.sp%].JEQ%%"
	call set "JNE=%%al.stack[%al.sp%].JNE%%"
	call set "JLT=%%al.stack[%al.sp%].JLT%%"
	call set "JGT=%%al.stack[%al.sp%].JGT%%"

	:: pop register(s)
	call set "XR=%%al.stack[%al.sp%].XR%%"
	call set "YR=%%al.stack[%al.sp%].YR%%"	
	call set "CX=%%al.stack[%al.sp%].CX%%"

	:: decrement stack pointer
	set /a "al.sp-=1"
	exit /b
}

:al.ContextCheck {
	:: test for null context pointer
	if "%CX%" EQU "null" (
		echo.[FATAL] Null Context Pointer Exception
		exit 999
	)
	exit /b
}

:: intentionally unrolled and linear for performance - CMP is a high-frequency function, keep literal functon calls to a minumum here.
:al.CMP {
	:: Enables conditional jumps if conditions are met, else sets to a NOP command (REM).
	
	if "%contextAwareness%" EQU "True" (
		call :al.ContextCheck
	)

	:al.CMP.ResetBranchFlags
		call set "JEQ=REM" & call set "JNE=REM" & call set "JLT=REM" & call set "JGT=REM" & call set "BEQ=REM" & call set "BNE=REM" & call set "BLT=REM" & call set "BGT=REM"

	:al.CMP.Equal
		:: Equality comparison is universal for string and int evaluation.
		if /i "%~1" EQU "%~2" (
			call set "BEQ=goto"
			call set "JEQ=call"
		) else (
			call set "BNE=goto"
			call set "JNE=call"
		)

	:: Int Guard Clause: We can not evaluate strings with less than, or greater tham comparator operations.
	:: - Therefore: Test and bail before reaching the comparator.
	:al.CMP.StringOrInt
		:: Protect against empty inputs evaluating to 0
		if "%~1"=="" goto :al.cmp.Exit
		if "%~2"=="" goto :al.cmp.Exit

		:: If a bit-shifted and non zero value is still zero, it's a string - bail
		:: Note: Allows for singed ints, and a single CMP instruction for strings and ints.
		set /a "al.cmp.v1=(%~1) << 1" 2>nul		
		if "%~1" NEQ "0" if %al.cmp.v1% EQU 0 goto :al.cmp.Exit
		set /a "al.cmp.v2=(%~2) << 1" 2>nul
		if "%~2" NEQ "0" if %al.cmp.v2% EQU 0 goto :al.cmp.Exit

	:: -- Proceede with safe integer comparisons for less and greater than and evaluations.
	:al.CMP.Less
		:: if a less than b
		if %~1 LSS %~2 (
			call set "BLT=goto"
			call set "JLT=call"
		)

	:al.CMP.Greater
		:: if a greater than b	
		if %~1 GTR %~2 (
			call set "BGT=goto"
			call set "JGT=call"
		)

	:al.cmp.Exit
		set "al.cmp.v1="
		set "al.cmp.v2="
		exit /b
}

:al.versionSelector {
	if "%1" EQU "1.1" (
		call :al.exportMnemonics_v1.1
		call :al.exportFlags_v1.1	
	) else (
		echo Valid API version not supplied
	)
	exit /b
}

:_main {
	:: test the first passed argument, if = "import", initialize CPU states
	:: - else check if we are testing specific mnemonics, and call their code
	if "%1" EQU "import" (
		call :al.versionSelector %2

	) else if "%1" EQU "CMP" (
	    call :al.CMP %2 %3

	) else if "%1" EQU "FEX" (
		call :al.FEX %2

	) else if "%1" EQU "PUSHF" (
		call :al.PUSHF

	) else if "%1" EQU "POPF" (
		call :al.POPF

	) else if "%1" EQU "INX" (
		call :al.INX

	) else if "%1" EQU "INY" (
		call :al.INY

	) else if "%1" EQU "DEX" (
		call :al.DEX

	) else if "%1" EQU "DEY" (
		call :al.DEY

	) else if "%1" EQU "LDX" (
		call :al.LDX %2

	) else if "%1" EQU "LDY" (
		call :al.LDY %2

	) else if "%1" EQU "MOV" (
		call :al.MOV %2 %3

	) else (
		echo Assembly Library Import Error or bad mnemonic reference.
		pause
	)

	call :al.destructor
	goto :_end
}

:_end

