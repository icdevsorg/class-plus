

import D "mo:base/Debug";
import Text "mo:base/Text";
import Principal "mo:base/Principal";


module {

  public type State = {
    message: Text;
  };

  public type Environment = {
    thisActor: actor {
      auto_init: () -> async ();
    };
  };

  /// Function to create an initial state for the Approval ICRC37 management.
  public let initialState : State = {
    message = "Hello World!";
  };

  /// Current ID Version of the Library, used for Migrations
  public let currentStateVersion = #v0_1_0(#id);


  public class AClass(stored: ?State, caller: Principal, canister: Principal, _environment: ?Environment){

    public let state = switch(stored){
      case(?val) val;
      case(null) initialState;
    };

    func getEnvironment() : Environment {
      switch(_environment){
        case(?val) val;
        case(null) D.trap("No Environment Set");
      };
    };

    public func message() : Text {
      state.message # " from canister " # Principal.toText(Principal.fromActor(getEnvironment().thisActor)) # " and " # Principal.toText(canister) # " created by " # Principal.toText(caller);
    };

  };

};