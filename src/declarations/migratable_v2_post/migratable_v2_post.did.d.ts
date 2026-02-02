import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface MigratableExample_v2_post {
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
 * / Migratable Example v2 (Post-Migration) - After migration from v1
 * /
 * / This version is used AFTER the migration from v1 to v2 has completed.
 * / It does NOT include the migration function because:
 * / 1. The migration was already done
 * / 2. v2-to-v2 upgrades don't need the migration
 * /
 * / IMPORTANT: Use this version for subsequent upgrades after the initial v1->v2 migration.
 */
export interface _SERVICE extends MigratableExample_v2_post {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
