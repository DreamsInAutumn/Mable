# Mable Assembly Framework
## Design Draft: The Dynamic Context & Memory Management Specification (WIP)

**Status:** *State of Flux / Active Sandbox*  
**Revision:** *v1.1-WIP*  

---

## 1. The Context Register (`CX`) Paradigm

In traditional assembly, branching is strictly bound to hardcoded, static labels. While highly predictable, this forces the programmer to duplicate subroutines or manage complex routing ladders to avoid instruction pointer collisions. 

The `CX` (Context Register) is introduced to act as a **Dynamic Pointer of Active Execution**. It allows the programmer to write highly generic, reusable, and self-documenting templates where the branch targets are resolved dynamically at runtime.

### Mechanics of the Context Pointer
When a subroutine begins, it claims the `CX` register, binding it to its own namespace. 

```batch
:MySubroutine {
    %PUSHF%
    %MOV% CX MySubroutine   ; Binds the Context Register
    
    :: Logic occurs here...

    %BRA% %CX%.Exit         ; Expands dynamically to MySubroutine.Exit
}
```

### Stack-Preserved Contexts
To allow nested subroutine calls without trashing the parent’s context, the `CX` register is fully integrated into the stack frame lifecycle:

*   **`%PUSHF%`:** Pushes the caller's current `CX` value onto the stack, and clears `CX` to `null` to ensure the next subroutine starts with a clean slate.
*   **`%POPF%`:** Pops and restores the parent's `CX` value, instantly returning the execution context to its original state upon subroutine return.

If a programmer attempts any type of branch after a comparison before initializing `CX`, the interpreter safely traps the `null` value, throwing an explicit Null Pointer exception instead of silently wandering into dead memory.

---

## 2. The Dynamic Memory Management Unit (`_MMU`)

Environment variable bloat and global state bleed are the dual tragedies of standard command-line scripting. Mable's `_MMU` acts as a micro-device driver that releases memory once its lifecycle is complete.

### Dynamic Self-Registration (The Driver Pattern)
To minimize logic overhead during standard execution, the MMU registers its own macro pointers in memory during the application's boot phase. Calling `_MMU` with no arguments triggers its constructor:

```batch
    %JSR% :_MMU   ; Called during startup
```

The MMU then binds the macro pointers `%_MMU.Free%` and `%_MMU.Destruct%` dynamically:

```batch
    set "_MMU.Free=%JSR% :_MMU Free %1 %2"
    set "_MMU.Destruct=%JSR% :_MMU Destruct"
```

On exit, the main orchestrator calls `%_MMU.Destruct%`, causing the MMU to unbind its own macro pointers, leaving the environment entirely pristine.

### Prefix-Based Garbage Collection
Instead of manually nullifying dozens of variables, the MMU utilizes a highly optimized prefix-matching iteration loop to deallocate entire structured namespaces in a single pass:

```batch
    %_MMU.Free% uldr.extapp
```

The underlying interpreter queries the environment block, captures all variables starting with the `uldr.extapp` namespace, and destroys them in a tight, unrolled loop, protecting the host system from memory leaks.

---

## 3. Implicit Context Deallocation

When we combine the `CX` register with the `_MMU`, we unlock the ultimate goal of modular architecture: **The Generic, Self-Cleaning Destructor.**

Because `CX` always holds the string of the currently executing function, and the `_MMU` can free variables dynamically by prefix, a subroutine no longer needs to hardcode its own cleanup targets. Every subroutine can share the exact same, single-line destructor template:

```batch
    :MySubroutine.Destruct
        %_MMU.Free% uldr.%CX%
        %BRA% %CX%.Exit
```

This ensures that the subroutine dynamically destroys *only* its own allocated local variables, restoring the memory space of the system to a pristine state before returning control to the caller.
