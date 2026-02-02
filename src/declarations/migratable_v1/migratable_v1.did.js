export const idlFactory = ({ IDL }) => {
  const MigratableExample_v1 = IDL.Service({
    'getCounter' : IDL.Func([], [IDL.Nat], []),
    'getMessage' : IDL.Func([], [IDL.Text], []),
    'getStateInfo' : IDL.Func(
        [],
        [IDL.Record({ 'counter' : IDL.Nat, 'message' : IDL.Text })],
        [],
      ),
    'getVersion' : IDL.Func([], [IDL.Text], []),
    'increment' : IDL.Func([], [IDL.Nat], []),
    'setMessage' : IDL.Func([IDL.Text], [], []),
  });
  return MigratableExample_v1;
};
export const init = ({ IDL }) => { return []; };
