import AClass "aclass";
import D "mo:base/Debug";
import ClassPlus "../";

import Principal "mo:base/Principal";
import Timer "mo:base/Timer";


shared ({ caller = _owner }) actor class Token  () = this{

  let initManager = ClassPlus.ClassPlusInitializationManager();

  stable let aClass_state : AClass.State = AClass.initialState;

  let aClass = ClassPlus.ClassPlus<system,
    AClass.AClass, 
    AClass.State,
    AClass.Environment>(
      _owner,
      actor(Principal.toText(Principal.fromActor(this))), 
      aClass_state, 
      AClass.AClass,
      initManager,
      // set up any enviornment settings here
      ?(func() : AClass.Environment {
        {
          thisActor = actor(Principal.toText(Principal.fromActor(this)));
          //bClass = func() : AClass.AClass{bClass()};
        };
      }),
      //any initialization code
      ?(func () : async* () {
        D.print("Initializing AClass");
        //do any work here necessary for initialization
      })
    ).get;


  public shared func getMessage() : async Text {
    aClass().message();
  }
};
