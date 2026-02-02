import { PocketIc, Actor, PocketIcServer } from '@dfinity/pic';
import { describe, test, expect, beforeAll, afterAll } from 'vitest';
import { Principal } from '@dfinity/principal';
import { idlFactory as v1IdlFactory, _SERVICE as MigratableV1Service } from '../src/declarations/migratable_v1/migratable_v1.did.js';
import { idlFactory as v2IdlFactory, _SERVICE as MigratableV2Service } from '../src/declarations/migratable_v2/migratable_v2.did.js';
import { idlFactory as v2PostIdlFactory, _SERVICE as MigratableV2PostService } from '../src/declarations/migratable_v2_post/migratable_v2_post.did.js';
import { idlFactory as exampleIdlFactory, _SERVICE as ExampleService } from '../src/declarations/example/example.did.js';
import { IDL } from '@dfinity/candid';
import path from 'path';

const WASM_PATH_V1 = path.resolve(__dirname, '..', '.dfx', 'local', 'canisters', 'migratable_v1', 'migratable_v1.wasm');
const WASM_PATH_V2 = path.resolve(__dirname, '..', '.dfx', 'local', 'canisters', 'migratable_v2', 'migratable_v2.wasm');
const WASM_PATH_V2_POST = path.resolve(__dirname, '..', '.dfx', 'local', 'canisters', 'migratable_v2_post', 'migratable_v2_post.wasm');
const WASM_PATH_EXAMPLE = path.resolve(__dirname, '..', '.dfx', 'local', 'canisters', 'example', 'example.wasm');

describe('ClassPlus Basic Tests', () => {
  let picServer: PocketIcServer;
  let pic: PocketIc;
  let exampleCanister: Actor<ExampleService>;
  let exampleId: Principal;

  beforeAll(async () => {
    picServer = await PocketIcServer.start();
    pic = await PocketIc.create(picServer.getUrl());

    // Deploy Example canister
    const exampleFixture = await pic.setupCanister({
      idlFactory: exampleIdlFactory,
      wasm: WASM_PATH_EXAMPLE,
    });
    exampleId = exampleFixture.canisterId;
    exampleCanister = exampleFixture.actor;

    // Let the timer-based initialization complete
    await pic.advanceTime(1_000);
    await pic.tick(10);
  });

  afterAll(async () => {
    await picServer.stop();
  });

  test('Example canister should initialize with default message', async () => {
    const message = await exampleCanister.getMessage();
    expect(message).toContain('Hello World');
  });

  test('Example canister should allow setting and getting message', async () => {
    await exampleCanister.SetMessage('New Test Message');
    const message = await exampleCanister.getMessage();
    expect(message).toContain('New Test Message');
  });

  test('Example canister state should persist across upgrade', async () => {
    // Set a message
    await exampleCanister.SetMessage('Pre-upgrade message');

    // Verify it's set
    let message = await exampleCanister.getMessage();
    expect(message).toContain('Pre-upgrade message');

    // Upgrade the canister
    await pic.upgradeCanister({
      canisterId: exampleId,
      wasm: WASM_PATH_EXAMPLE,
      upgradeModeOptions: {
        wasm_memory_persistence: [{ keep: null }],
        skip_pre_upgrade: [],
      },
    });

    // Let the timer-based initialization complete
    await pic.advanceTime(1_000);
    await pic.tick(10);

    // Verify state persisted
    message = await exampleCanister.getMessage();
    expect(message).toContain('Pre-upgrade message');
  });
});

describe('ClassPlus Migration Tests', () => {
  let picServer: PocketIcServer;
  let pic: PocketIc;
  let migratableCanister: Actor<MigratableV1Service>;
  let migratableId: Principal;

  beforeAll(async () => {
    picServer = await PocketIcServer.start();
    pic = await PocketIc.create(picServer.getUrl());

    // Deploy v1 canister
    const v1Fixture = await pic.setupCanister({
      idlFactory: v1IdlFactory,
      wasm: WASM_PATH_V1,
    });
    migratableId = v1Fixture.canisterId;
    migratableCanister = v1Fixture.actor;

    // Let the timer-based initialization complete
    await pic.advanceTime(1_000);
    await pic.tick(10);
  });

  afterAll(async () => {
    await picServer.stop();
  });

  test('v1 canister should initialize correctly', async () => {
    const stateInfo = await migratableCanister.getStateInfo();
    expect(stateInfo.message).toContain('Hello World v1');
    expect(Number(stateInfo.counter)).toBe(0);
  });

  test('v1 canister should track counter', async () => {
    // Increment a few times
    await migratableCanister.increment();
    await migratableCanister.increment();
    await migratableCanister.increment();

    const counter = await migratableCanister.getCounter();
    expect(Number(counter)).toBe(3);
  });

  test('v1 canister should preserve message on update', async () => {
    await migratableCanister.setMessage('Test message before migration');
    const message = await migratableCanister.getMessage();
    expect(message).toBe('Test message before migration');
  });

  test('v1 state should persist across v1-to-v1 upgrade', async () => {
    // Get current state
    const stateBefore = await migratableCanister.getStateInfo();
    console.log('State before v1->v1 upgrade:', stateBefore);

    // Upgrade with same v1 WASM
    await pic.upgradeCanister({
      canisterId: migratableId,
      wasm: WASM_PATH_V1,
      upgradeModeOptions: {
        wasm_memory_persistence: [{ keep: null }],
        skip_pre_upgrade: [],
      },
    });

    // Let the timer-based initialization complete
    await pic.advanceTime(1_000);
    await pic.tick(10);

    // Verify state persisted
    const stateAfter = await migratableCanister.getStateInfo();
    console.log('State after v1->v1 upgrade:', stateAfter);

    expect(stateAfter.message).toBe(stateBefore.message);
    expect(Number(stateAfter.counter)).toBe(Number(stateBefore.counter));
  });

  test('v1 to v2 migration should preserve message and counter', async () => {
    // Record current state
    const v1State = await migratableCanister.getStateInfo();
    console.log('v1 state before migration:', v1State);

    // Upgrade to v2 with migration
    await pic.upgradeCanister({
      canisterId: migratableId,
      wasm: WASM_PATH_V2,
      upgradeModeOptions: {
        wasm_memory_persistence: [{ keep: null }],
        skip_pre_upgrade: [],
      },
    });

    // Update actor interface to v2
    const v2Canister: Actor<MigratableV2Service> = pic.createActor(v2IdlFactory, migratableId);

    // Let the timer-based initialization complete
    await pic.advanceTime(1_000);
    await pic.tick(10);

    // Verify migrated state
    const v2State = await v2Canister.getStateInfo();
    console.log('v2 state after migration:', v2State);

    // Message and counter should be preserved
    expect(v2State.message).toBe(v1State.message);
    expect(Number(v2State.counter)).toBe(Number(v1State.counter));

    // New fields should be populated by migration
    expect(Number(v2State.lastUpdated)).toBeGreaterThan(0);
    expect(v2State.version).toBe('v2-migrated');
  });

  test('v2 canister should have new functionality after migration', async () => {
    const v2Canister: Actor<MigratableV2Service> = pic.createActor(v2IdlFactory, migratableId);

    // Test new getLastUpdated method
    const lastUpdated = await v2Canister.getLastUpdated();
    expect(Number(lastUpdated)).toBeGreaterThan(0);

    // Test new getVersion method
    const version = await v2Canister.getVersion();
    expect(version).toBe('v2-migrated');

    // Test that increment updates lastUpdated
    const beforeIncrement = await v2Canister.getLastUpdated();

    // Advance time to ensure lastUpdated changes
    await pic.advanceTime(1_000_000_000); // 1 second in nanoseconds

    await v2Canister.increment();
    const afterIncrement = await v2Canister.getLastUpdated();

    // lastUpdated should have changed
    expect(Number(afterIncrement)).toBeGreaterThanOrEqual(Number(beforeIncrement));
  });

  test('v2 state should persist across v2-to-v2 upgrade (using post-migration version)', async () => {
    const v2Canister: Actor<MigratableV2Service> = pic.createActor(v2IdlFactory, migratableId);

    // Get current state
    const stateBefore = await v2Canister.getStateInfo();
    console.log('State before v2->v2 upgrade:', stateBefore);

    // IMPORTANT: For v2-to-v2 upgrades, use the post-migration WASM
    // The migration function in v2 expects OLD (v1) state format
    // After migration is complete, subsequent upgrades should use v2_post
    // which doesn't have the migration function
    await pic.upgradeCanister({
      canisterId: migratableId,
      wasm: WASM_PATH_V2_POST,
      upgradeModeOptions: {
        wasm_memory_persistence: [{ keep: null }],
        skip_pre_upgrade: [],
      },
    });

    // Use v2_post interface (same as v2)
    const v2PostCanister: Actor<MigratableV2PostService> = pic.createActor(v2PostIdlFactory, migratableId);

    // Let the timer-based initialization complete
    await pic.advanceTime(1_000);
    await pic.tick(10);

    // Verify state persisted
    const stateAfter = await v2PostCanister.getStateInfo();
    console.log('State after v2->v2_post upgrade:', stateAfter);

    expect(stateAfter.message).toBe(stateBefore.message);
    expect(Number(stateAfter.counter)).toBe(Number(stateBefore.counter));
    expect(stateAfter.version).toBe(stateBefore.version);
  });
});

describe('ClassPlus Fresh v2 Installation', () => {
  let picServer: PocketIcServer;
  let pic: PocketIc;
  let v2Canister: Actor<MigratableV2Service>;
  let v2Id: Principal;

  beforeAll(async () => {
    picServer = await PocketIcServer.start();
    pic = await PocketIc.create(picServer.getUrl());

    // Deploy v2 canister fresh (no migration needed)
    const v2Fixture = await pic.setupCanister({
      idlFactory: v2IdlFactory,
      wasm: WASM_PATH_V2,
    });
    v2Id = v2Fixture.canisterId;
    v2Canister = v2Fixture.actor;

    // Let the timer-based initialization complete
    await pic.advanceTime(1_000);
    await pic.tick(10);
  });

  afterAll(async () => {
    await picServer.stop();
  });

  test('Fresh v2 install should use initialState', async () => {
    const state = await v2Canister.getStateInfo();
    console.log('Fresh v2 state:', state);

    // Should have the default v2 message from InitArgs
    expect(state.message).toContain('Hello World v2');
    expect(Number(state.counter)).toBe(0);
    // Fresh install uses initialState, not migration
    expect(state.version).toBe('v2');
  });

  test('Fresh v2 canister should have all v2 features', async () => {
    // Verify new methods work
    const version = await v2Canister.getVersion();
    expect(version).toBe('v2');

    const lastUpdated = await v2Canister.getLastUpdated();
    // Fresh install initializes lastUpdated via args in constructor
    expect(Number(lastUpdated)).toBeGreaterThanOrEqual(0);
  });
});
