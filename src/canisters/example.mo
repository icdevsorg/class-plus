import AClassLib "aclass";
import D "mo:base/Debug";
import ClassPlus "../";

import Principal "mo:base/Principal";
import Timer "mo:base/Timer";


shared ({ caller = _owner }) actor class Token  () = this{

  type AClass = AClassLib.AClass;
  type State = AClassLib.State;
  type InitArgs = AClassLib.InitArgs;
  type Environment = AClassLib.Environment;

  let initManager = ClassPlus.ClassPlusInitializationManager(_owner, Principal.fromActor(this), true);

  stable var aClass_state : State = AClassLib.initialState();

  let aClass = AClassLib.Init<system>({
    manager = initManager;
    initialState = aClass_state;
    args = ?({messageModifier = "Hello World"});
    pullEnvironment = ?(func() : Environment {
      {
        thisActor = actor(Principal.toText(Principal.fromActor(this)));
      };
    });
    onInitialize = ?(func (newClass: AClassLib.AClass) : async* () {
        //_aClass := ?newClass;
        D.print("Initializing AClass");
      });
    onStorageChange = func(new_state: State) {
        aClass_state := new_state;
      } 
  });

  public shared func getMessage() : async Text {
    aClass().message();
  };

  public shared func SetMessage(x: Text) : async () {
    aClass().setMessage(x);
  }
};
