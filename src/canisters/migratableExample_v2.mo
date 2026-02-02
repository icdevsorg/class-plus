/// Migratable Example v2 - Actor with explicit migration from v1
///
/// This actor demonstrates the ClassPlus pattern with Motoko's new migration syntax.
/// When upgrading from migratableExample_v1.mo to this version:
/// 1. The migration function in migratableExampleMigration.mo is called
/// 2. Old state (message, counter) is preserved
/// 3. New fields (lastUpdated, version) are initialized with migration values
///
/// IMPORTANT: The `(with migration)` syntax before the actor declaration
/// tells Motoko to run the migration function during upgrade.

import MigratableClassLib "migratableClass_v2";
import { migration } "migratableExampleMigration";
import Debug "mo:core/Debug";
import ClassPlus "../";
import Principal "mo:core/Principal";


(with migration)
shared ({ caller = _owner }) persistent actor class MigratableExample_v2() = this {

  type MigratableClass = MigratableClassLib.MigratableClass;
  type State = MigratableClassLib.State;
  type InitArgs = MigratableClassLib.InitArgs;
  type Environment = MigratableClassLib.Environment;

  transient let initManager = ClassPlus.ClassPlusInitializationManager<system>(_owner, Principal.fromActor(this), true);

  // The state variable - on upgrade from v1, this is populated by the migration function
  var migratable_state : State = MigratableClassLib.initialState();

  transient let migratable = MigratableClassLib.Init({
    org_icdevs_class_plus_manager = initManager;
    initialState = migratable_state;
    args = ?({messageModifier = "Hello World v2"});
    pullEnvironment = ?(func() : Environment {
      {
        thisActor = actor(Principal.toText(Principal.fromActor(this)));
      };
    });
    onInitialize = ?(func (_newClass: MigratableClassLib.MigratableClass) : async* () {
        Debug.print("Initializing MigratableClass v2");
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

  /// Get the last updated timestamp (NEW in v2)
  public shared func getLastUpdated() : async Int {
    migratable().getLastUpdated();
  };

  /// Get the version string (NEW in v2)
  public shared func getVersion() : async Text {
    migratable().getVersion();
  };

  /// Get full state info (extended in v2)
  public shared func getStateInfo() : async {message: Text; counter: Nat; lastUpdated: Int; version: Text} {
    migratable().getStateInfo();
  };
};
