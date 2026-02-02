export const idlFactory = ({ IDL }) => {
  const MigratableExample_v2_post = IDL.Service({
    'getCounter' : IDL.Func([], [IDL.Nat], []),
    'getLastUpdated' : IDL.Func([], [IDL.Int], []),
    'getMessage' : IDL.Func([], [IDL.Text], []),
    'getStateInfo' : IDL.Func(
        [],
        [
          IDL.Record({
            'counter' : IDL.Nat,
            'lastUpdated' : IDL.Int,
            'version' : IDL.Text,
            'message' : IDL.Text,
          }),
        ],
        [],
      ),
    'getVersion' : IDL.Func([], [IDL.Text], []),
    'increment' : IDL.Func([], [IDL.Nat], []),
    'setMessage' : IDL.Func([IDL.Text], [], []),
  });
  return MigratableExample_v2_post;
};
export const init = ({ IDL }) => { return []; };
