# ClassPlus

A Motoko library designed to reduce boilerplate when instantiating and managing class-like objects within actor classes. ClassPlus enables developers to create modular, upgrade-friendly classes that leverage stable variables for persistence across upgrades.

---

## Requirements

- **DFX Version**: Requires DFX 0.24.0 or later.
- **Motoko Version**: Requires Motoko 1.1.0 or later for enhanced orthogonal persistence and migration support.

---

## Installation

`mops add class-plus`

## Overview

ClassPlus simplifies the process of defining and managing objects in actor classes by:

1. **Reducing Boilerplate**: It minimizes repetitive code for constructing and maintaining objects.
2. **Supporting Upgrades**: Ensures objects can be reconstituted from stable variables after an upgrade.
3. **Encapsulating Complexity**: Provides a unified interface for initialization, state management, and environment configuration.
4. **Migration Support**: Works seamlessly with Motoko's new explicit migration pattern for state evolution.

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
        org_icdevs_class_plus_manager = initManager;
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

## State Migration with ClassPlus

Motoko's enhanced orthogonal persistence (available in Motoko 1.1.0+) provides a powerful migration pattern for evolving your class state across upgrades. This section explains how to use ClassPlus with the new migration syntax.

### Why Migration?

When you need to change the structure of your State type (adding fields, changing types, or reorganizing data), you need to tell Motoko how to transform the old state into the new state. Without migration, incompatible state changes will cause upgrades to fail.

### The Migration Pattern

The migration pattern uses a migration function that:
- **Consumes** specific fields from the old actor state
- **Produces** specific fields for the new actor state
- Is **selective** - fields not mentioned are preserved automatically

### Step-by-Step Migration Guide

#### Step 1: Define the Old and New State Types

First, define both the old state type (what you're migrating FROM) and the new state type (what you're migrating TO) in a migration module:

```motoko
// Migration.mo
import Time "mo:core/Time";

module Migration {

  // Old state type from v1
  public type OldState = {
    var message: Text;
    var counter: Nat;
  };

  // New state type for v2 - adds new fields
  public type NewState = {
    var message: Text;
    var counter: Nat;
    var lastUpdated: Int;    // NEW field
    var version: Text;       // NEW field
  };

  // Migration function
  public func migration(old : { var myClass_state : OldState }) : { var myClass_state : NewState } {
    {
      var myClass_state : NewState = {
        var message = old.myClass_state.message;    // Preserve message
        var counter = old.myClass_state.counter;    // Preserve counter
        var lastUpdated = Time.now();               // Initialize new field
        var version = "v2-migrated";                // Initialize new field
      };
    };
  };

};
```

#### Step 2: Update Your Class Module

Create the v2 version of your class module with the new State type:

```motoko
// MyClass_v2.mo
module {

  public type State = {
    var message: Text;
    var counter: Nat;
    var lastUpdated: Int;    // NEW
    var version: Text;       // NEW
  };

  public func initialState() : State = {
    var message = "Uninitialized";
    var counter = 0;
    var lastUpdated = 0;
    var version = "v2";
  };

  // ... rest of ClassPlus boilerplate and class implementation
};
```

#### Step 3: Add Migration to Your Actor

Use the `(with migration)` syntax before your actor declaration:

```motoko
// MyActor_v2.mo
import MyClassLib "MyClass_v2";
import { migration } "Migration";
import ClassPlus "mo:class-plus";
import Principal "mo:core/Principal";

(with migration)  // <-- This tells Motoko to run the migration function on upgrade
shared ({ caller = _owner }) persistent actor class MyActor() = this {

  type MyClass = MyClassLib.MyClass;
  type State = MyClassLib.State;

  transient let initManager = ClassPlus.ClassPlusInitializationManager<system>(
    _owner, Principal.fromActor(this), true
  );

  // State variable - populated by migration on upgrade from v1
  var myClass_state : State = MyClassLib.initialState();

  transient let myClass = MyClassLib.Init({
    org_icdevs_class_plus_manager = initManager;
    initialState = myClass_state;
    args = ?({ messageModifier = "Hello World v2" });
    pullEnvironment = ?(func() : Environment { /* ... */ });
    onInitialize = null;
    onStorageChange = func(new_state: State) {
      myClass_state := new_state;
    };
  });

  // ... public methods
};
```

### Important Migration Considerations

#### 1. Selective Migration

The migration function only needs to specify fields that are being transformed. Fields not mentioned are handled automatically:

```motoko
// If you have multiple stable variables:
persistent actor {
  var myClass_state : State = ...;     // Needs migration (type changed)
  var otherData : Nat = 0;             // No migration needed (preserved automatically)
}

// Migration only mentions myClass_state:
func migration(old : { var myClass_state : OldState }) : { var myClass_state : NewState } {
  // otherData is preserved automatically!
  { var myClass_state = ... }
};
```

#### 2. Post-Migration Upgrades

After the initial migration (v1 → v2), subsequent upgrades (v2 → v2) should NOT use the migration function because:
- The migration function expects the OLD state format
- v2 state is already in the NEW format

**Solution**: Create a post-migration version without the `(with migration)` declaration:

```motoko
// MyActor_v2_post.mo - For upgrades AFTER migration is complete
shared ({ caller = _owner }) persistent actor class MyActor() = this {
  // Same code as v2, but WITHOUT (with migration)
  var myClass_state : State = MyClassLib.initialState();
  // ...
};
```

#### 3. Migration Workflow

1. **v1 deployed** - Original version running in production
2. **v1 → v2 (with migration)** - Deploy v2 with migration function
3. **v2 → v2_post** - Deploy post-migration version (removes migration code)
4. **v2_post → v2_post** - Future upgrades use the same version

### Complete Migration Example

See the `src/canisters/` directory for a complete working example:

- `migratableClass_v1.mo` - Initial class with basic state
- `migratableClass_v2.mo` - Updated class with new fields
- `migratableExampleMigration.mo` - Migration function
- `migratableExample_v1.mo` - v1 actor
- `migratableExample_v2.mo` - v2 actor with migration
- `migratableExample_v2_post.mo` - v2 actor for post-migration upgrades

### Testing Migrations

The `pic/` directory contains PocketIC tests that verify:
- State persistence across same-version upgrades
- Proper state migration from v1 to v2
- New field initialization during migration
- Post-migration upgrade compatibility

Run tests with:
```bash
cd pic
npm install
npm test
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

  - calls: Buffer.Buffer(() ->async\*())
    - queue up functions to call during initialization by adding them to the calls buffer. They will be executed in the order you add them.

#### **`ClassPlus`**

Encapsulates logic for creating and managing a class instance.

`public class AClass<system>(stored: ?State, caller: Principal, canister: Principal, args: ?InitArgs, _environment: ?Environment, onStateChange: (State) -> ())`

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

#### **`ClassPlusSystem`**

Same as `ClassPlus` but with a system constructor

### **Helper Functions**

#### **`ClassPlusGetter`**

Simplifies retrieval of a class instance.

```motoko
public func ClassPlusGetter<T, S, A, E>(x: ?ClassPlus<T, S, A, E>): () -> T;
```

#### **`ClassPlusSystemGetter`**

Simplifies retrieval of a class instance that has a system constructor.

```motoko
public func ClassPlusSystemGetter<T, S, A, E>(x: ?ClassPlus<T, S, A, E>): <system>() -> T;
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
- **Migration-Friendly**: Works seamlessly with Motoko's explicit migration pattern.

---

## Testing

ClassPlus includes comprehensive PocketIC tests covering:
- Basic initialization and state management
- State persistence across upgrades
- State migration between versions

```bash
# Build canisters
dfx build --check

# Run PIC tests
cd pic
npm install
npm test
```

---

This library is ideal for projects requiring modular, upgrade-friendly object management in Motoko. By leveraging ClassPlus, developers can focus more on functionality and less on boilerplate code.


