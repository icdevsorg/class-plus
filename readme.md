# ClassPlus


A simple library to reduce boilerplate when instantiating ClassPlus Objects in Motoko.

# Requirements

At least DFX 0.24.0


# Usage

ClassPlus classes should be used from actor classes. They simplify boilerplate for constructing class objects that *virtually* survive upgrades.  Upon each upgrade they are reconstituted from stable variables in the canister.

ClassPlus objects need to be created with the signature:

`public class AClass(stored: ?State, caller: Principal, canister: Principal, _environment: ?Environment)`

The State and Environment Objects can very and are handled with generic typing so you can define those to be what every you need. Typically you'll want to use a migration pattern for your state structure and it needs to be made up of stable compatible objects.

In your class will need to define:

- `public type State = {}` - What is the shape of your state. These all need to be stable compatible variables.
- `public let initialState = {}` - What are the defaults? You can update these in the initialization step if they are not ready.
- `public type Environment = {}` - Your class can support environment style variables unique to your class instantiation.


Instantiating your class in your actor is accomplished as follows:

```

  let initManager = ClassPlus.ClassPlusInitializationManager();

  stable let aClass_state : AClass.State = AClass.initialState;

  let aClass = ClassPlus.ClassPlus<system,
    AClass.AClass, 
    AClass.State,
    AClass.Environment>(
      _owner, //typically the msg.caller from your canister creation
      actor(Principal.toText(Principal.fromActor(this))), //important - helps capture the current canister you are running on.
      aClass_state, 
      AClass.AClass,
      initManager,
      // set up any environment settings here
      ?(func() : AClass.Environment {
        {
          //you can set up any post install references here. If you need references to other Class Plus items here you can reference them here as long as they are initialized before hand. Order is important.
          thisActor = actor(Principal.toText(Principal.fromActor(this)));
        };
      }),
      //any initialization code
      ?(func () : async* () {
        D.print("Initializing AClass");
        //do any work here necessary for initialization
      })
    ).get;

  public shared func getMessage() : async Text {
    //this is how you use your class
    aClass().message();
  }
```