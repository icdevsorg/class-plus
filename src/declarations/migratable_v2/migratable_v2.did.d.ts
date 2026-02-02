import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface MigratableExample_v2 {
  /**
   * / Get the counter
   */
  'getCounter' : ActorMethod<[], bigint>,
  /**
   * / Get the last updated timestamp (NEW in v2)
   */
  'getLastUpdated' : ActorMethod<[], bigint>,
  /**
   * / Get the current message
   */
  'getMessage' : ActorMethod<[], string>,
  /**
   * / Get full state info (extended in v2)
   */
  'getStateInfo' : ActorMethod<
    [],
    {
      'counter' : bigint,
      'lastUpdated' : bigint,
      'version' : string,
      'message' : string,
    }
  >,
  /**
   * / Get the version string (NEW in v2)
   */
  'getVersion' : ActorMethod<[], string>,
  /**
   * / Increment the counter
   */
  'increment' : ActorMethod<[], bigint>,
  /**
   * / Set a new message
   */
  'setMessage' : ActorMethod<[string], undefined>,
}
/**
 * / Migratable Example v2 - Actor with explicit migration from v1
 * /
 * / This actor demonstrates the ClassPlus pattern with Motoko's new migration syntax.
 * / When upgrading from migratableExample_v1.mo to this version:
 * / 1. The migration function in migratableExampleMigration.mo is called
 * / 2. Old state (message, counter) is preserved
 * / 3. New fields (lastUpdated, version) are initialized with migration values
 * /
 * / IMPORTANT: The `(with migration)` syntax before the actor declaration
 * / tells Motoko to run the migration function during upgrade.
 */
export interface _SERVICE extends MigratableExample_v2 {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
