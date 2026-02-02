export const idlFactory = ({ IDL }) => {
  const Token = IDL.Service({
    'SetMessage' : IDL.Func([IDL.Text], [], []),
    'getMessage' : IDL.Func([], [IDL.Text], []),
  });
  return Token;
};
export const init = ({ IDL }) => { return []; };
