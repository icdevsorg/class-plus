/// Migratable Example v2 (Post-Migration) - After migration from v1
///
/// This version is used AFTER the migration from v1 to v2 has completed.
/// It does NOT include the migration function because:
/// 1. The migration was already done
/// 2. v2-to-v2 upgrades don't need the migration
///
/// IMPORTANT: Use this version for subsequent upgrades after the initial v1->v2 migration.

import MigratableClassLib "migratableClass_v2";
import Debug "mo:core/Debug";
import ClassPlus "../";
import Principal "mo:core/Principal";


shared ({ caller = _owner }) persistent actor class MigratableExample_v2_post() = this {

  type MigratableClass = MigratableClassLib.MigratableClass;
  type State = MigratableClassLib.State;
  type InitArgs = MigratableClassLib.InitArgs;
  type Environment = MigratableClassLib.Environment;

  transient let initManager = ClassPlus.ClassPlusInitializationManager<system>(_owner, Principal.fromActor(this), true);

  // The state variable - no migration needed for v2->v2 upgrades
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
        Debug.print("Initializing MigratableClass v2 (post-migration)");
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
