# Mable: Macro Assembly Batch Library Extension
## User Manual & Reference Guide

### 1. Introduction
Welcome to **Mable**. Mable is a structural paradigm shift for Windows Batch scripting, providing assembly-like mnemonics to enforce Single Responsibility Principles (SRP) and flat code hierarchies. By treating Batch scripts like macro assembly, Mable can transform spaghettified, nested nightmares into clean, readable, and maintainable state machines.

---

### 2. Table of Contents
1. [Introduction](#1-introduction)
2. [Table of Contents](#2-table-of-contents)
3. [Usage Intent & Philosophy](#3-usage-intent--philosophy)
4. [Instruction Set Architecture (Mnemonics)](#4-instruction-set-architecture-mnemonics)
5. [Understanding Conditionals](#5-understanding-conditionals)
6. [Understanding Flags (Jumps & Branches)](#6-understanding-flags-jumps--branches)
7. [The Stack](#7-the-stack)
8. [Usage Examples](#8-usage-examples)
9. [Addendum: What is Mable Actually Good For?](#9-addendum-what-is-mable-actually-good-for)

---

### 3. Usage Intent & Philosophy
The majority of Batch code is written in an idiomatic style that relies on deep nesting, `setlocal EnableDelayedExpansion` and tangled logical scopes. 

Mable exists to break this cycle. 

By applying the logical flow of macro assembly to a high-level scripting environment, Mable encourages:
*   **Flat Architecture:** Using the `%CMP%` (Compare) instruction allows you to evaluate state and branch immediately. There is no need for nested `IF/ELSE` blocks.
*   **Single Responsibility Functions:** Code is broken down into small, purposeful subroutines.
*   **Happy Path Branching:** Code execution should flow linearly, breaking off into subroutines or jumping out upon failure, making the primary logic path highly legible.
*   **Scoped State Management:** Because Batch variables are global, Mable provides Stack instructions (`%PUSHF%`, `%POPF%`) to save and restore execution states, ensuring nested subroutines do not destroy the state of their parents.

Think of your script an application running on a CPU. Evaluate state, jump to the appropriate routine, and clean up as you go.

---

### 4. Instruction Set Architecture (Mnemonics)

Instructions are executed by wrapping them in standard Batch variable expansion syntax (e.g., `%JSR% :Subroutine`).

#### Execution & Termination
| Mnemonic | Description |
| :--- | :--- |
| **`JSR`** | **J**ump to **S**ub**R**outine. Calls a local label. Execution returns here when finished. |
| **`RTS`** | **R**eturn **T**o **S**ender. Exits the current subroutine and returns to the caller. |
| **`RET`** | **RET**urn. An alias for RTS |
| **`JFR`** | **J**ump **F**a**R**. Launches an external application as an asynchronous background process. |
| **`BRK`** | **BR**ea**K**. Immediately terminates the script. |
| **`NOP`** | **N**o **OP**eration. A structural placeholder that does nothing. |
#### Future Additions to be implemented
| **`IOC`** | **I**nstantiate **O**bject **C**lass. Executes an external script acting as a class constructor. |
| **`DOC`** | **D**estruct **O**bject **C**lass. Executes an external script acting as a class constructor. |

#### Conditionals (Microcode)
| Mnemonic | Description |
| :--- | :--- |
| **`CMP`** | **C**o**MP**are. Evaluates two arguments and sets execution flags (Zero/Equal, Less Than, Greater Than). |
| **`FEX`** | **F**ile **EX**ist. Evaluates if a file exists on disk and sets Equal/Not Equal flags accordingly. |

#### Registers
| Mnemonic | Description |
| :--- | :--- |
| **`LDX`** | **L**oa**D** **X** Register. Assigns an integer value to the `%XR%` register. |
| **`LDY`** | **L**oa**D** **Y** Register. Assigns an integer value to the `%YR%` register. |
| **`INX`** | **IN**crement **X**. Adds 1 to the `%XR%` register. |
| **`INY`** | **IN**crement **Y**. Adds 1 to the `%YR%` register. |

#### Stack Operations
| Mnemonic | Description |
| :--- | :--- |
| **`PUSHF`** | **PUSH** **F**lags. Saves the current state of all conditional flags and Registers to the stack. |
| **`POPF`** | **POP** **F**lags. Restores the conditional flags and Registers from the top of the stack. |

---

### 5. Understanding Conditionals
In Mable, logic decisions are a two-step process. First, you run a **Conditional**, and second, you execute a **Flag**.

Conditionals—namely `%CMP%` and `%FEX%`—do not execute code or move the execution pointer. Instead, they evaluate the arguments you pass to them and dynamically map the Flag mnemonics in memory.

*   `%CMP% Arg1 Arg2` compares two strings or integers.
*   `%FEX% "C:\path\file.txt"` checks for file existence.

Once evaluated, the flags are "armed." If a condition is met (e.g., Arg1 equals Arg2), the corresponding "Equal" flags become executable instructions. If the condition is not met, those flags silently become `NOP` (No Operation) instructions and are safely ignored by the interpreter.

---

### 6. Understanding Flags (Jumps & Branches)
Flags are the second half of the logic equation. You place them immediately after a Conditional to dictate the flow of the program.

There are two distinct types of Flags: **Jumps** and **Branches**.

*   **Jumps (`JEQ`, `JNE`, `JLT`, `JGT`)**: These act like Subroutine calls. The script will leap to the target, execute it, and upon hitting a `%RET%`, will return to the line immediately following the Jump flag.
*   **Branches (`BEQ`, `BNE`, `BLT`, `BGT`)**: These are one-way trips. Execution moves to the new label and *does not return*. They are used to break out of loops, skip logic, or handle terminal states.
*   **Unconditional Branch (`BRA`)**: A one-way trip that happens regardless of any previous conditional evaluation.

#### Flag Reference
| Mnemonic | Type | Description |
| :--- | :--- | :--- |
| **`BRA`** | Branch | Unconditional **BRA**nch. Always moves execution to the target. |
| **`JEQ`** / **`BEQ`** | Jump/Branch | Execute if the preceding conditional was **EQ**ual. |
| **`JNE`** / **`BNE`** | Jump/Branch | Execute if the preceding conditional was **N**ot **E**qual. |
| **`JLT`** / **`BLT`** | Jump/Branch | Execute if Arg1 was **L**ess **T**han Arg2. |
| **`JGT`** / **`BGT`** | Jump/Branch | Execute if Arg1 was **G**reater **T**han Arg2. |

---

### 7. The Stack
Because Batch processes share a single global memory space, calling a subroutine that performs a `%CMP%` will overwrite the flags from the parent routine. 

To safely perform nested logic, use the Stack.
*   Call `%PUSHF%` before executing a nested comparison. This pushes the current state of all Jumps, Branches, and the `XR`/`YR` registers into memory and increments the Stack Pointer.
*   Call `%POPF%` when you are done. This pulls the previous state back into global scope and decrements the Stack Pointer.
*   *Note: Calling `%POPF%` when the stack is empty will result in a Fatal Stack Underflow and terminate the script.*

---

### 8. Usage Examples

*Note: All examples assume Mable has been imported and initialized.*

#### Example 1: Basic Subroutines (`JSR`, `RET`, `RTS`)
Keep your primary logic flat by delegating tasks.
```bat
:_main
    %JSR% :InitConfig
    %JSR% :StartServer
    %BRK% 0

:InitConfig
    set "App.Name=TestApp"
    %RTS%

:StartServer
    echo Starting %App.Name%...
    %RTS%
```

#### Example 2: Control Flow via Stacked Jumps (Dispatch Table)
You can stack flags right after a single `%CMP%` to create a highly readable, switch-like dispatch table.
```bat
:HandleInput
    :: Assuming %userInput% contains a command
    %CMP% "%userInput%" "Start"
        %JEQ% :StartService

    %CMP% "%userInput%" "Stop"
        %JEQ% :StopService

    %CMP% "%userInput%" "Restart"
        %JEQ% :StopService
        %JEQ% :StartService

    %CMP% "%userInput%" "Quit"
        %BEQ% :ExitApplication

    %RTS%
```

#### Example 3: File Existence & Fall-through Logic (`FEX`, `BNE`, `BRA`)
Use branches to skip code paths.
```bat
:LoadConfig
    %FEX% "config.ini"
        %BNE% :LoadConfig_Error

    echo Config found, loading...
    %BRA% :LoadConfig_End

:LoadConfig_Error
    echo Fatal: config.ini is missing!
    %BRK%

:LoadConfig_End
    %RTS%
```

#### Example 4: Registers & Loops (`LDX`, `INX`, `CMP`, `BLT`)
How to iterate safely without resorting to archaic `for` loop syntax.
```bat
:CountingLoop
    :: Initialize Register X to 0
    %LDX% 0

:Loop_Start
    echo Current Count: %XR%
    %INX%

    :: Compare XR to 5. If it is Less Than 5, branch back to start.
    %CMP% %XR% 5
        %BLT% :Loop_Start

    echo Loop complete.
    %RTS%
```

#### Example 5: Protecting Scope with The Stack (`PUSHF`, `POPF`)
When a subroutine needs to do its own comparisons without destroying the caller's conditional logic.
```bat
:CheckSystemState
    %CMP% "%SystemStatus%" "Degraded"
        %JEQ% :AttemptRecovery
        %BNE% :AllClear
    %RTS%

:AttemptRecovery
    :: We must save the parent flags, because we are about to use CMP again!
    %PUSHF%
        
        %CMP% "%RetryCount%" "3"
            %JEQ% :FatalError
            %JNE% :Recover
    
    :: Restore the flags so the parent routine functions normally
    %POPF%
    %RTS%
```

#### Example 6: Firing External Applications (`JFR`)
```bat
:LaunchBrowser
    :: Opens a web browser independently of the script
    set browser="C:\Program Files\App\browser.exe"
    %JFR% %browser% "http://localhost:8000"
    %RTS%
```

---

### 9. Addendum: What is Mable Actually Good For?

If you are looking at this and thinking, *"Why would anyone shoehorn a 1970s Assembly-language paradigm into a 1990s MS-DOS script interpreter to run on a modern Windows machine?"* ...you are asking the right questions.

**Mable is good for:**
1.  **Sysadmins who have seen too much:** If you've ever debugged a 400-line Batch file with 6 levels of nested `if / else` blocks featuring `!DelayedExpansion!` variables that randomly drop trailing spaces, Mable is a cup of cold water in hell. 
2.  **Architectural Discipline:** Batch actively encourages you to write terrible code. Mable actively encourages you to write structured code. By breaking logic into discrete comparisons and jumps, your scripts become deterministic state-machines.
3.  **Terminal Aesthetics:** There is an undeniable, nerdy satisfaction in reading `%CMP% %var% 1`, `%BEQ% :label`. It feels like you are programming bare metal, even though you are just tricking `cmd.exe` into behaving itself.
4. **Thoughts** If you conclude that I am simply hiding the horrors of goto in semantic abstraction, you're probably right - logicaly. However with conditional brancing bolted on it makes sense to me.
5.  **Job Security:** Nobody in your IT department is going to understand how your scripts work at first glance. But once you show them the manual, they will either revere you as a wizard or ask you to rewrite it in Python. (Choose the wizard path).
