/////////
//
// Why? The use of this class reduces boilerplate in actor classes by about 
// 39%. It also allows for a more organized and modular approach to setting up
// your classes and simplifies the types a developer needs to know about. Finally
// it removes the need to self call your self for initialization as the timer and
// timer management is baked in.
//
// It does add some boilerplate to the class definition, but this is a one-time
// cost that is paid off by the time saved in the future.
//
/////

import D "mo:base/Debug";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Timer "mo:base/Timer";

module{

  public type ClassPlusInitList = [() -> ()];

  public class ClassPlusInitializationManager(_owner : Principal, _canister : Principal, autoTimer: Bool) {
    public var timer: ?Nat = null;
    public let calls = Buffer.Buffer<() -> async* ()>(1);
    public let owner = _owner;
    public let canister = _canister;
    public let auto = autoTimer;
    public func initialize() : async* (){
       for(init in calls.vals()){
          await* init();
        };
    };
  };

  public func ClassPlusGetter<T,S,A,E>(x: ?ClassPlus<T,S,A,E>) : () -> T {
    func () : T {
      switch(x){
        case(?val) val.get();
        case(null) D.trap("No Value Set");
      };
    };
  };



  public func BuildInit<system, T, S, A, E >(Constructor:  ((?S, Principal, Principal, ?A, ?E, ((S)->())) -> T)) : (<system>({
      manager: ClassPlusInitializationManager;
      initialState: S;
      args : ?A;
      pullEnvironment : ?(() -> E);
      onInitialize: ?(T -> async*());
      onStorageChange : ((S) ->())
    }) -> (()-> T)) {

      return func<system>(config: {
        manager: ClassPlusInitializationManager;
        initialState: S;
        args : ?A;
        pullEnvironment : ?(() -> E);
        onInitialize: ?(T -> async*());
        onStorageChange : ((S) ->())
      }) : (()-> T) {
        ClassPlus<system,
          T, 
          S,
          A,
          E>({config with constructor = Constructor}).get;
      };
  };

  //constructor
  public class ClassPlus<system, T, S, A, E>(config: {//ClassType, StateType, ArgsType, EnvironmentType, 
      manager: ClassPlusInitializationManager;
      initialState: S;
      constructor: ((?S, Principal, Principal, ?A, ?E, ((S)->())) -> T);
      args: ?A;
      pullEnvironment: ?(() -> E);
      onInitialize : ?((T) -> async*());
      onStorageChange : ((S) -> ());
    }) {

      D.print("Class Plus Constructor");
      switch(config.pullEnvironment){
        case(?val) D.print("Pull Environment Set");
        case(null) D.print("Pull Environment Not Set");
      };

    let caller = config.manager.owner;
    let canister = config.manager.canister;

    var _value : ?T = null;
    var _thisEnvironment : ?E = null;

    public func setEnvironment(x : E) : (){
      _thisEnvironment := ?x;
    };

    public func getEnvironment() : ?E {
      switch(_thisEnvironment){
        case(null){
          switch(config.pullEnvironment){
            case(?val){
              setEnvironment(val());
              getEnvironment();
            };
            case(null){
              null;
            };
          };
        };
        case(?val) ?val;
      };
    };

    //todo...can maybe remove
    public func getState() : S{
      config.initialState;
    };

    public func initialize() : async* (){
      switch(config.pullEnvironment){
        case(?val) setEnvironment(val());
        case(_){};
      };

      let thisClass = get(); //forces construction
      
      switch(config.onInitialize){
        case(?val) await* val(thisClass);
        case(null) {};
      };
      return
    };

    public func get() : T {
      switch(_value){
        case(null){
          let value = config.constructor(?config.initialState, caller, canister, config.args, getEnvironment(), config.onStorageChange);
          _value := ?value;
          value;
        };
        case(?val) val;
      };
    };

    public let tracker = config.manager;

    if(tracker.auto){
      switch(tracker.timer){
        case(null){
            tracker.timer := ?Timer.setTimer<system>(#nanoseconds(0), func () : async () {
            await* tracker.initialize();
          });
        };
        case(_){};
      };
    };

    tracker.calls.add(initialize)
  };

};