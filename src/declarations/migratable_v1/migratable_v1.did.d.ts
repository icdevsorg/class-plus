import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface MigratableExample_v1 {
  /**
   * / Get the counter
   */
  'getCounter' : ActorMethod<[], bigint>,
  /**
   * / Get the current message
   */
  'getMessage' : ActorMethod<[], string>,
  /**
   * / Get full state info
   */
  'getStateInfo' : ActorMethod<[], { 'counter' : bigint, 'message' : string }>,
  /**
   * / Get version - v1 doesn't have a version field, so we return a static string
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
 * / Migratable Example v1 - Actor using ClassPlus with migratable state
 * /
 * / This actor demonstrates the ClassPlus pattern with state that can be migrated.
 * / Deploy this first, add some data, then upgrade to migratableExample_v2.mo
 */
export interface _SERVICE extends MigratableExample_v1 {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
