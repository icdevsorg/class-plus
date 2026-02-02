/// Migratable Example v1 - Actor using ClassPlus with migratable state
///
/// This actor demonstrates the ClassPlus pattern with state that can be migrated.
/// Deploy this first, add some data, then upgrade to migratableExample_v2.mo

import MigratableClassLib "migratableClass_v1";
import Debug "mo:core/Debug";
import ClassPlus "../";
import Principal "mo:core/Principal";


shared ({ caller = _owner }) persistent actor class MigratableExample_v1() = this {

  type MigratableClass = MigratableClassLib.MigratableClass;
  type State = MigratableClassLib.State;
  type InitArgs = MigratableClassLib.InitArgs;
  type Environment = MigratableClassLib.Environment;

  transient let initManager = ClassPlus.ClassPlusInitializationManager<system>(_owner, Principal.fromActor(this), true);

  var migratable_state : State = MigratableClassLib.initialState();

  transient let migratable = MigratableClassLib.Init({
    org_icdevs_class_plus_manager = initManager;
    initialState = migratable_state;
    args = ?({messageModifier = "Hello World v1"});
    pullEnvironment = ?(func() : Environment {
      {
        thisActor = actor(Principal.toText(Principal.fromActor(this)));
      };
    });
    onInitialize = ?(func (_newClass: MigratableClassLib.MigratableClass) : async* () {
        Debug.print("Initializing MigratableClass v1");
      });
    onStorageChange = func(new_state: State) {
        migratable_state := new_state;
      };
  });

  /// Get the current message
  public shared func getMessage() : async Text {
    migratable().getMessage();
  };

  /// Set a new message
  public shared func setMessage(x: Text) : async () {
    migratable().setMessage(x);
  };

  /// Get the counter
  public shared func getCounter() : async Nat {
    migratable().getCounter();
  };

  /// Increment the counter
  public shared func increment() : async Nat {
    migratable().increment();
  };

  /// Get full state info
  public shared func getStateInfo() : async {message: Text; counter: Nat} {
    migratable().getStateInfo();
  };

  /// Get version - v1 doesn't have a version field, so we return a static string
  public shared func getVersion() : async Text {
    "v1";
  };
};
