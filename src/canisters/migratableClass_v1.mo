/// MigratableClass v1 - Initial version
/// 
/// This module demonstrates the ClassPlus pattern with an initial state structure.
/// In v2, we will add a new field and demonstrate the migration pattern.

import Runtime "mo:core/Runtime";
import Text "mo:core/Text";
import Principal "mo:core/Principal";
import ClassPlusLib "../";


module {

  /// The State type for v1 - contains only a message
  public type State = {
    var message: Text;
    var counter: Nat;
  };

  public type InitArgs = {
    messageModifier: Text;
  };

  public type Environment = {
    thisActor: actor {
      auto_init: () -> async ();
    };
  };

  public func initialState() : State = {
    var message = "Uninitialized";
    var counter = 0;
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

  /// The MigratableClass v1 implementation
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
        };
      };
      case(null) {};
    };

    /// Get the current message
    public func getMessage() : Text {
      state.message;
    };

    /// Set a new message
    public func setMessage(x: Text) : () {
      state.message := x;
    };

    /// Get the counter
    public func getCounter() : Nat {
      state.counter;
    };

    /// Increment the counter
    public func increment() : Nat {
      state.counter += 1;
      state.counter;
    };

    /// Get the full state info for debugging
    public func getStateInfo() : {message: Text; counter: Nat} {
      {
        message = state.message;
        counter = state.counter;
      };
    };
  };

};
