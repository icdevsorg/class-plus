# ClassPlus

A Motoko library designed to reduce boilerplate when instantiating and managing class-like objects within actor classes. ClassPlus enables developers to create modular, upgrade-friendly classes that leverage stable variables for persistence across upgrades.

---

## Requirements

- **DFX Version**: Requires DFX 0.24.0 or later.

---

## Installation

`mops add class-plus`

## Overview

ClassPlus simplifies the process of defining and managing objects in actor classes by:

1. **Reducing Boilerplate**: It minimizes repetitive code for constructing and maintaining objects.
2. **Supporting Upgrades**: Ensures objects can be reconstituted from stable variables after an upgrade.
3. **Encapsulating Complexity**: Provides a unified interface for initialization, state management, and environment configuration.

ClassPlus objects are instantiated with a predefined structure and integrate seamlessly into actor classes.

---

## Usage

### Core Concepts

1. **State**: The shape of the class's state, stored in stable variables, must be composed of stable-compatible types.
2. **Environment**: Optional environment variables passed to the class for contextual operations.
3. **Initialization**: Initialization logic, including setup and configuration, can be provided during class creation.

### Class Definition

To define a class compatible with ClassPlus, follow this structure:

#### Example Class Definition

```motoko
public class AClass(stored: ?State, caller: Principal, canister: Principal, args: ?InitArgs, _environment: ?Environment, onStateChange: (State) -> ()) {
    // Define the initial state.
    public let state = switch(stored) {
        case (?val) val;
        case (null) initialState();
    };

    // Notify about state changes.
    onStateChange(state);

    // Capture environment settings.
    let environment: Environment = switch(_environment) {
        case (?val) val;
        case (null) D.trap("No Environment Set");
    };

    // Apply initial arguments, if provided.
    switch (args) {
        case (?val) {
            if (state.message == "Uninitialized") {
                state.message := val.messageModifier;
            }
        };
        case (null) {};
    };

    // Define class methods.
    public func message(): Text {
        state.message # " from canister " # Principal.toText(canister) # " created by " # Principal.toText(caller);
    };

    public func setMessage(x: Text): () {
        state.message := x;
    };
}
```

#### Required Definitions

1. **`State`**: Define the structure of the class's state.

   ```motoko
   public type State = {
       var message: Text;
   };
   ```

2. **`Environment`**: Define any environment variables (optional).

   ```motoko
   public type Environment = {
       thisActor: actor {
           auto_init: () -> async ();
       };
   };
   ```

3. **`initialState`**: Define default state values.

   ```motoko
   public func initialState(): State = {
       var message = "Uninitialized";
   };
   ```

4. **`InitArgs`**: Define any arguments required for initialization (optional).

   ```motoko
   public type InitArgs = {
       messageModifier: Text;
   };
   ```

### Instantiating the Class in an Actor

Use the `ClassPlus` library to simplify instantiation and initialization within an actor.

#### Example Actor Definition

```motoko
import AClassLib "aclass";
import ClassPlus "../";

shared ({ caller = _owner }) actor class Token () = this {
    type AClass = AClassLib.AClass;
    type State = AClassLib.State;
    type InitArgs = AClassLib.InitArgs;
    type Environment = AClassLib.Environment;

    let initManager = ClassPlus.ClassPlusInitializationManager(_owner, Principal.fromActor(this), true);

    stable var aClass_state: State = AClassLib.initialState();

    let aClass = AClassLib.Init<system>({
        manager = initManager;
        initialState = aClass_state;
        args = ?({ messageModifier = "Hello World" });
        pullEnvironment = ?(func() : Environment {
            {
                thisActor = actor(Principal.toText(Principal.fromActor(this)));
            };
        });
        onInitialize = ?(func(newClass: AClassLib.AClass): async* () {
            D.print("Initializing AClass");
        });
        onStorageChange = func(new_state: State) {
            aClass_state := new_state;
        }
    });

    public shared func getMessage(): async Text {
        aClass().message();
    };

    public shared func SetMessage(x: Text): async () {
        aClass().setMessage(x);
    };

    private shared func initStuff(): async* (){
      //add init logic here
    }

    initManager.calls.add(initStuff);
};
```

---

## ClassPlus Library API

### **Modules and Classes**

#### **`ClassPlusInitializationManager`**

Handles initialization and tracking of ClassPlus objects.

- **Constructor**: `ClassPlusInitializationManager(_owner: Principal, _canister: Principal, autoTimer: Bool)`

  - `_owner`: The principal of the actor owner.
  - `_canister`: The principal of the canister where the object resides.
  - `autoTimer`: Automatically initialize objects on a timer.

- **Methods**:

  - `initialize(): async* ()`
    - Executes initialization logic for all registered classes.

- Members

  - calls: Buffer.Buffer(() ->async\*()
    - queue up functions to call during initialization by adding them to the calls buffer. They will be executed in the order you add them.

#### **`ClassPlus`**

Encapsulates logic for creating and managing a class instance.

- **Constructor**: `ClassPlus<system, T, S, A, E>(config: {...})`

  - `manager`: Instance of `ClassPlusInitializationManager`.
  - `initialState`: Initial state of the class.
  - `constructor`: Constructor function for the class.
  - `args`: Optional initialization arguments.
  - `pullEnvironment`: Function to retrieve environment variables.
  - `onInitialize`: Optional initialization logic.
  - `onStorageChange`: Callback for state updates.

- **Methods**:

  - `get(): T`
    - Retrieves the class instance, creating it if necessary.
  - `initialize(): async* ()`
    - Performs any setup logic for the class.
  - `getState(): S`
    - Retrieves the current state.
  - `getEnvironment(): ?E`
    - Retrieves the environment, initializing it if necessary.

### **Helper Functions**

#### **`ClassPlusGetter`**

Simplifies retrieval of a class instance.

```motoko
public func ClassPlusGetter<T, S, A, E>(x: ?ClassPlus<T, S, A, E>): () -> T;
```

#### **`BuildInit`**

Constructs initialization logic for a class.

```motoko
public func BuildInit<system, T, S, A, E>(Constructor: (...)): (...) -> ();
```

---

## Advantages of ClassPlus

- **Reduced Boilerplate**: Eliminates repetitive code in actor classes.
- **Upgrade-Safe**: Ensures class objects can be reconstituted from stable variables.
- **Modular and Organized**: Provides a clear structure for defining and managing classes.
- **Automatic Initialization**: Built-in timer management simplifies initialization.

---

This library is ideal for projects requiring modular, upgrade-friendly object management in Motoko. By leveraging ClassPlus, developers can focus more on functionality and less on boilerplate code.

