:_PreInit {	
    if "%al.Initialized%" NEQ "True" (
        echo [Fatal] Mable Dependency not initialized in caller tree.
        exit 999
    )

    %JSR% :_Class.MableMMU %1 %2
    %RTS%
}

/*
    Class: Mable - Memory Manager Unit Library
    Author: (C) Autumn 2026
    License: GPL 3
    Kennel: https://github.com/DreamsInAutumn/Mable
*/

/*
    Thoughts
        Perhaps register namespaces in a linked list. Validate agaisnt the list before destroying the namespace, and remove from the list.
        Try to keep the list simple, there may be ways of having such a list wihtout building one from scratch.
*/

:_Class.MableMMU {    
    %BRA% :_Class.MableMMU.Dispatcher

    :_Class.MableMMU.Dispatcher {
        %CMP% "%2" ""
            %BEQ% :_Mable.MMU.MissingPointerRef

        %CMP% "%1" "Singleton"
            %BEQ% :_Mable.MMU.exportMethods

        %CMP% "%1" "Free"
            %BEQ% :_Mable.MMU.Free
    
        %CMP% "%1" "Destruct"
            %BEQ% :_Mable.MMU.Destruct

        %BRA% :_Mable.MMU.UnsupportedInstruction

	    %RTS%
    }

    :_Mable.MMU.exportMethods {        
        %CMP% %_MableMMU.Initialized% "True"
            %JEQ% :_Mable.MMU.MultipleInstanceAttempt

        %MOV% %2.MMU.Free "%~df0 free"
        %MOV% %2.MMU.Destruct "%~df0 Destruct"

        :: this needs to be pointer based for non singleton objects
        %MOV% _MableMMU.Initialized "True"
        %BRA% :_Class.MableMMU.Exit
    }

    :_Mable.MMU.Free {        
        for /f "delims==" %%i in ('set %2') do (            
            set "%%i="
	    )
        %BRA% :_Class.MableMMU.Exit
    }

    :_Mable.MMU.Destruct {        
        %MOV% %2.MMU.Destruct ""
        %MOV% %2.MMU.Free ""
        %MOV% _MableMMU.Initialized
        %BRA% :_Class.MableMMU.Exit
    }

    :_Mable.MMU.MissingPointerRef {
        echo [Fatal ] Missing Invalid Pointer References passed to MMU.
        exit 999
    }

    :_Mable.MMU.MultipleInstanceAttempt {
        :: Enforce singleton.
        echo [Fatal ] MMU Does not support multiple instances.
        exit 999
    }

    :_Mable.MMU.UnsupportedInstruction {
        :: Enforce singleton.
        echo [Fatal ] Unsupported MMU Instruction.
        exit 999
    }

    :_Class.MableMMU.Exit
        %RTS%
}
