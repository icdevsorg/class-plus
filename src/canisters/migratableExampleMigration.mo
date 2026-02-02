/// Migration module for MigratableExample v1 -> v2
///
/// This module contains the migration function that transforms
/// the old state (v1) to the new state (v2).
/// 
/// IMPORTANT: The migration function is SELECTIVE:
/// - Input: Only the OLD stable fields that need transformation (will be consumed/removed)
/// - Output: Only the NEW stable fields that result from the transformation
/// - Fields not mentioned in input/output are preserved automatically
///
/// In this example:
/// - migratable_state changes from v1 type to v2 type, so we need to transform it
/// - Any other stable variables would be preserved automatically

import Time "mo:core/Time";

module Migration {

  /// Old state type from v1 (the fields being consumed)
  public type OldState = {
    var message: Text;
    var counter: Nat;
  };

  /// New state type for v2 (the fields being produced)
  public type NewState = {
    var message: Text;
    var counter: Nat;
    var lastUpdated: Int;
    var version: Text;
  };

  /// Migration function: converts v1 stable variables to v2 stable variables
  /// 
  /// This function is called automatically during upgrade.
  /// 
  /// Pattern: func(old_fields_to_consume) : new_fields_to_produce
  /// 
  /// - The input specifies which old fields will be consumed (removed from old actor)
  /// - The output specifies which new fields will be initialized from the transformation
  /// - Fields NOT in input/output are preserved or initialized normally
  public func migration(old : { var migratable_state : OldState }) : { var migratable_state : NewState } {
    {
      var migratable_state : NewState = {
        var message = old.migratable_state.message;   // Preserve message
        var counter = old.migratable_state.counter;   // Preserve counter
        var lastUpdated = Time.now();                  // Initialize new field
        var version = "v2-migrated";                   // Initialize new field
      };
    };
  };

};
