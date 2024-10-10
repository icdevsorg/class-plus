import D "mo:base/Debug";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Timer "mo:base/Timer";

module{

  public type ClassPlusInitList = [() -> ()];

  public class ClassPlusInitializationManager(){
    public var timer: ?Nat = null;
    public let calls = Buffer.Buffer<() -> async* ()>(1);
    public func initialize() : async* (){
       for(init in calls.vals()){
          await* init();
        };
    };
  };
  
  //constructor
  public class ClassPlus<system, T,S,E>(
    caller: Principal,
    canisterActor: actor {},
    state: S, 
    constructor: ((?S, Principal, Principal, ?E) -> T), 
    _tracker: ClassPlusInitializationManager, 
    pullEnvironment: ?(() -> E), 
    _initialize : ?(() -> async* ())){
    var _value : ?T = null;
    var _thisEnvironment : ?E = null;

    public func setEnvironment(x : E) : (){
      _thisEnvironment := ?x;
    };

    public func getEnvironment() : E {
      switch(_thisEnvironment){
        case(null){
          switch(pullEnvironment){
            case(?val){
              setEnvironment(val());
              getEnvironment();
            };
            case(null){
              D.trap("No Environment Set");
            };
          };
        };
        case(?val) val;
      };
    };

    public func initialize() : async* (){
      switch(pullEnvironment){
        case(?val) setEnvironment(val());
        case(_){};
      };

      ignore get(); //forces construction

      switch(_initialize){
        case(?val) await* val();
        case(null) {};
      };
      return
    };

    public func get() : T {
      switch(_value){
        case(null){
          let value = constructor(?state, caller, Principal.fromActor(canisterActor),_thisEnvironment);
          _value := ?value;
          value;
        };
        case(?val) val;
      };
    };

    public let tracker = _tracker;

    switch(tracker.timer){
      case(null){
          tracker.timer := ?Timer.setTimer<system>(#nanoseconds(0), func () : async () {
          await* tracker.initialize();
        });
      };
      case(_){};
    };

    tracker.calls.add(initialize)
  };

};