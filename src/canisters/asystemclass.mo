

import D "mo:base/Debug";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Timer "mo:base/Timer";
import ClassPlusLib "../";


module {

  public type State = {
    var message: Text;
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
  };

  //////////
  // The following boilerplate can be added your classes to save
  // significant lines of code
  //////////
  public type ClassPlus = ClassPlusLib.ClassPlusSystem<AClass, 
    State,
    InitArgs,
    Environment>;

  public func ClassPlusSystemGetter<system>(item: ?ClassPlus) : (<system>() -> AClass) {
    ClassPlusLib.ClassPlusSystemGetter<system, AClass, State, InitArgs, Environment>(item);
  };


  

  public func Init<system>(config : {
      manager: ClassPlusLib.ClassPlusInitializationManager;
      initialState: State;
      args : ?InitArgs;
      pullEnvironment : ?(() -> Environment);
      onInitialize: ?(AClass -> async*());
      onStorageChange : ((State) ->())
    }) : <system>() -> AClass {

      ClassPlusLib.ClassPlusSystem<system,
        AClass, 
        State,
        InitArgs,
        Environment>({config with constructor = AClass}).get;
      
    };

  

  public class AClass<system>(stored: ?State, caller: Principal, canister: Principal, args: ?InitArgs, _environment: ?Environment, onStateChange: (State) -> ()){

    public let state = switch(stored){
      case(?val) val;
      case(null) initialState() : State;
    };

    onStateChange(state);

    let environment : Environment = switch(_environment){
      case(?val) val;
      case(null) D.trap("No Environment Set");
    };

    switch(args){
      case(?val) {
        if(state.message == "Uninitialized" ){
          state.message := val.messageModifier;
        };
      };
      case(null) {};
    };

    public func message() : Text {
      state.message # " from canister " # Principal.toText(Principal.fromActor(environment.thisActor)) # " and " # Principal.toText(canister) # " created by " # Principal.toText(caller);
    };

    public func setMessage(x: Text) : () {
      state.message := x;

    };

    ignore Timer.setTimer<system>(#seconds(1), func() : async () {
      D.print("Timer Triggered");
    
    });

  };

};