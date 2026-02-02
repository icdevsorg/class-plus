/// MigratableClass v2 - Version with new field and migration
/// 
/// This module demonstrates the Motoko migration pattern with ClassPlus.
/// It adds a `lastUpdated` field to the state and provides a migration function
/// to convert v1 state to v2 state.

import Runtime "mo:core/Runtime";
import Text "mo:core/Text";
import Principal "mo:core/Principal";
import Int "mo:core/Int";
import Time "mo:core/Time";
import ClassPlusLib "../";


module {

  /// The old State type from v1 - used in migration
  public type OldState = {
    var message: Text;
    var counter: Nat;
  };

  /// The new State type for v2 - adds lastUpdated timestamp
  public type State = {
    var message: Text;
    var counter: Nat;
    var lastUpdated: Int; // Time.Time is Int
    var version: Text;
  };

  public type InitArgs = {
    messageModifier: Text;
  };

  public type Environment = {
    thisActor: actor {
      auto_init: () -> async ();
    };
  };

  /// Initial state for fresh installations
  public func initialState() : State = {
    var message = "Uninitialized";
    var counter = 0;
    var lastUpdated = 0;
    var version = "v2";
  };

  /// Migration function: converts v1 State to v2 State
  /// This is called when upgrading from v1 to v2
  public func migrateState(old: OldState) : State {
    {
      var message = old.message;
      var counter = old.counter;
      var lastUpdated = Time.now();
      var version = "v2-migrated";
    };
  };

  //////////
  // ClassPlus boilerplate
  //////////
  public type ClassPlus = ClassPlusLib.ClassPlus<MigratableClass, 
    State,
    InitArgs,
    Environment>;

  public func ClassPlusGetter(item: ?ClassPlus) : () -> MigratableClass {
    ClassPlusLib.ClassPlusGetter<MigratableClass, State, InitArgs, Environment>(item);
  };

  public func Init(config : {
      org_icdevs_class_plus_manager: ClassPlusLib.ClassPlusInitializationManager;
      initialState: State;
      args : ?InitArgs;
      pullEnvironment : ?(() -> Environment);
      onInitialize: ?(MigratableClass -> async*());
      onStorageChange : ((State) ->())
    }) :()-> MigratableClass{

      ClassPlusLib.ClassPlus<
        MigratableClass, 
        State,
        InitArgs,
        Environment>({config with constructor = MigratableClass}).get;
    };

  /// The MigratableClass v2 implementation
  public class MigratableClass(stored: ?State, _caller: Principal, _canister: Principal, args: ?InitArgs, _environment: ?Environment, onStateChange: (State) -> ()){

    public let state = switch(stored){
      case(?val) val;
      case(null) initialState() : State;
    };

    onStateChange(state);

    let _env : Environment = switch(_environment){
      case(?val) val;
      case(null) Runtime.trap("No Environment Set");
    };

    switch(args){
      case(?val) {
        if(state.message == "Uninitialized" ){
          state.message := val.messageModifier;
          state.lastUpdated := Time.now();
        };
      };
      case(null) {};
    };

    /// Get the current message
    public func getMessage() : Text {
      state.message;
    };

    /// Set a new message (updates lastUpdated)
    public func setMessage(x: Text) : () {
      state.message := x;
      state.lastUpdated := Time.now();
    };

    /// Get the counter
    public func getCounter() : Nat {
      state.counter;
    };

    /// Increment the counter (updates lastUpdated)
    public func increment() : Nat {
      state.counter += 1;
      state.lastUpdated := Time.now();
      state.counter;
    };

    /// Get the last updated timestamp
    public func getLastUpdated() : Int {
      state.lastUpdated;
    };

    /// Get the version string
    public func getVersion() : Text {
      state.version;
    };

    /// Get the full state info for debugging
    public func getStateInfo() : {message: Text; counter: Nat; lastUpdated: Int; version: Text} {
      {
        message = state.message;
        counter = state.counter;
        lastUpdated = state.lastUpdated;
        version = state.version;
      };
    };
  };

};
