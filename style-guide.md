# The Mable Style Guide
### A Companion for the Command Line Wilderness

Mable is named after a fiercely loyal, incredibly fun-loving pet who brought joy and structure to chaotic days. The Mable framework attempts to do exactly the same thing for your codebase. 

Windows Batch is a wild, untamed environment. Left to its own devices, it tangles into unreadable knots of logic. Mable sits by your side, offering a protective, structured environment inspired by the elegance of macro-assembly. She invites you to write code that is predictable, visually beautiful, and deeply reliable. 

Here are the guiding paradigms for writing scripts alongside Mable. While not absolute laws, they suggest keeping your architecture sound and your execution predictable.

Note: During development, Mable has seen many refinements to styles and best practices. The example file: uniloader.cmd is the present "gold standard".

---

### 1. The Departure from `IF`

In traditional high-level scripting langauges we tend to lean heavily on `IF` and `ELSE` to make decisions. Mable asks us to leave that concept behind. We do not use `IF` statements. 

Instead, we embrace the rhythm of the hardware. We evaluate a truth, and then branch based on that truth. This separates the act of *asking a question* from the act of *taking action*. 

When you need to make a decision, you ask Mable to compare two values, which quietly sets the environment's internal flags. Following the comparison, you provide the branch instructions.

```batch
    :: We evaluate the state.
    %CMP% %errorlevel% 0
        %BNE% :Network.Offline
        %BRA% :Network.Online
```

This paradigm eliminates nested logic blocks entirely. The code remains flat, readable, and perfectly linear. 

### 2. The Unified Epilogue (Single Entry, Single Exit)

Mable is a tidy companion who likes to ensure everything is put back exactly where she found it. When a function begins, we often ask her to hold onto the current state of the CPU flags using `%PUSHF%`. 

Because execution branches out into many different paths, it is tempting to return to the caller (`%RTS%`) the moment a task is finished. We encourage you to resist that temptation. 

Instead, guide every branch toward a single, unified exit point at the bottom of your function. This creates perfect architectural symmetry and where necessary, guarantees that your flags are  safely restored before the function ends.

```batch
    :CheckStatus.True
        set "Status=Online"
        %BRA% :CheckStatus.Exit

    :CheckStatus.False
        set "Status=Offline"
        %BRA% :CheckStatus.Exit

    :CheckStatus.Exit
        %POPF%
        %RTS%
```

### 3. Dispatch Tables over Waterfalls

When presented with multiple choices, scripting languages often encourage developers to chain decisions together—checking one condition, and if it fails, falling into the next, and the next. 

Mable prefers the elegance of a Dispatch Table. We group all of our comparisons at the very top of a routine. This creates a clean, easily readable "router" that directs traffic to independent worker blocks below. The worker blocks do their job and jump to the exit, completely unaware of each other. 

```batch
    :LoadApp.Dispatcher
        %CMP% "%1" "AppOne"
            %BEQ% :LoadApp.AppOne

        %CMP% "%1" "AppTwo"
            %BEQ% :LoadApp.AppTwo

        :: A safe trapdoor for unexpected guests.
        %BRA% :LoadApp.Exit
```

This keeps your routing logic completely decoupled from your execution logic. You can add a dozen new applications to the dispatcher without ever risking a tangled execution path.

### 4. Visual Theater for the Human Eye

Code is read far more often than it is written. While the command interpreter only sees a flat list of instructions, we can use visual scaffolding to communicate intent to the human reading the screen.

Mable encourages the use of curly braces `{ }` to visually encapsulate in routing logic, loops or blocks of code that operates together as a sub-function within the scope of its owner. The interpreter ignores them as long as they follow an unconditional branch or a label. For the developer's eye, they instantly frame the code's purpose.

```batch
    :MonitorNetwork.Loop {
        %JSR% :PingServer
        %CMP% %ServerStatus% "Online"
            %BEQ% :MonitorNetwork.Exit
            %BRA% :MonitorNetwork.Loop
    }
```

### 5. Naming with Action and Intent

Mable thrives on clarity. When naming your subroutines, Mable invites you to adopt a Verb-Noun cadence. 

Names should describe exactly the action taking place and the object being acted upon. `InitializeApplication` tells a better story than `AppStart`. `ControlTerminal` is more descriptive than `TerminalManager`. 

When reading the `_main` execution loop, the sequence of instructions should read like a clear, declarative story.

```batch
    %JSR% :InitNameSpace
    %JSR% :LoadUserConfig
    %JSR% :ControlSplash Init
    %JSR% :StartServer
```

### A Final Thought

Mable was designed to remove the fragility of traditional command-line batch scripting in Windows. When you write alongside her, you are free from wrestling with variable assignment soup stemming from nesting.

Keep your code flat. Keep your state clean. Trust the routing tables. Mable will take care of the rest.