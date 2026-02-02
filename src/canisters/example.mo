import AClassLib "aclass";
import Debug "mo:core/Debug";
import ClassPlus "../";

import Principal "mo:core/Principal";


shared ({ caller = _owner }) persistent actor class Token  () = this{

  type AClass = AClassLib.AClass;
  type State = AClassLib.State;
  type InitArgs = AClassLib.InitArgs;
  type Environment = AClassLib.Environment;

  transient let initManager = ClassPlus.ClassPlusInitializationManager<system>(_owner, Principal.fromActor(this), true);

  var aClass_state : State = AClassLib.initialState();

  transient let aClass = AClassLib.Init({
    org_icdevs_class_plus_manager = initManager;
    initialState = aClass_state;
    args = ?({messageModifier = "Hello World"});
    pullEnvironment = ?(func() : Environment {
      {
        thisActor = actor(Principal.toText(Principal.fromActor(this)));
      };
    });
    onInitialize = ?(func (_newClass: AClassLib.AClass) : async* () {
        Debug.print("Initializing AClass");
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
