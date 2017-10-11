% Lightweight Static Capabilities
% Yawar Amin (<yawar.amin@gmail.com>)
% 2017-10-11

# Introduction

## About

- Paper by Oleg Kiselyov and Chung-chieh Shan:
  [http://okmij.org/ftp/papers/lightweight-static-capabilities.pdf](http://okmij.org/ftp/papers/lightweight-static-capabilities.pdf)
- Slides available at
  [https://github.com/yawaramin/lightweght-static-capabilities](https://github.com/yawaramin/lightweght-static-capabilities)
  (that's not a typo)
- Base requirement: statically-typed programming language
- Slightly more advanced techniques possible with higher-rank types

## Why?

- We want safety
- Type safety is good
- Dependent types can be hard
- What if there was a middle ground?
- What if we can centralise all runtime checks into _one_ check and multiple
  runs?

# Concepts

## Ingredients

- Small piece of trusted (certified) code
- A unique type given to above trusted code so that code that typechecks is
  _certified_
- 'Proxy' types represent dynamic values statically (compile-time
  metaprogramming like C++ templates)

# Example: reverse list

## Basic reverse with multiple null checks

```ocaml
let rec rev list acc =
  if null list then acc else rev (tail list) (cons (head list) acc)
```

- We don't use pattern matching because we're targeting any data structure
  that supports the list interface (`null`, `head`, `tail`)
- Runtime checks for empty list in _three_ places for each list--`null`,
  `head`, and `tail` (will throw exception for latter two rather than allow
  undefined behaviour)

## Smart reverse with one null check

Define what the paper calls a _security kernel,_ i.e. a type:

```ocaml
module NEList : sig
  type 'a t
  val fromList : 'a list -> 'a t option
  val toList : 'a t -> 'a list
  val head : 'a t -> 'a
  val tail : 'a t -> 'a list
end = struct
  (* No extra allocation *)
  type 'a t = 'a list
  let fromList list = if null list then None else Some list
  let toList list = list
  let head = Unsafe.head
  let tail = Unsafe.tail
end
```

## Implement smart reverse:

```ocaml
let rec rev list acc = match NEList.fromList list with
  | None -> acc
  | Some list -> rev (NEList.tail list) (cons (NEList.head list) acc)

(* val rev : 'a list -> 'a list -> 'a list *)
```

- But this creates and immediately uses an `option` value on each iteration
- The paper shows a continuation-passing style `rev` that sidesteps
  allocation problem

# Formalisation

## Strict

- Formalise security kernel in a language called Strict
- Strict has a sound type system (formally proven)
- Strict forbids things like creating a `NEList.t` that contains an empty
  list

## Lax

- 'Transpile' Strict into a language called Lax
- Lax potentially allows incorrect code like a `NEList.t` which contains an
  empty list, but it can be 'sandboxed' by the 'transpile' process so that in
  practice it contains only what Strict allows
- Lax is easy to embed into statically-typed languages using type-safety
  techniques like modules, types, etc.
- We can visually inspect the implementation (the security kernel) to verify
  correctness

# Types as static capabilities

## Domain-specific kernel of trust

- Use an expressive programming language to encode correctness assertions
- Assertions are wrapped in a _kernel of trust_
- Each assertion must be inspected for correctness, but allows defining an
  extensible library of static checks.

## Capabilities for extending trust

- The type system _certifies_ safety conditions and then _propagates_ them
  out through the program
- Abstract data types are perfect for this job because they're tightly
  controlled by their associated modules, and because their names are unique
  identifiers for their safety conditions
- I.e., abstract data types model _capabilities_

## Static proxies for dynamic values

- We can tag or _proxy_ values with types that indicate some dynamic property
  of the value
- E.g. we can tag an array with a type that represents its length to convert
  array bounds-safe operations into type-safe operations
- Or we can use OCaml functors to create arrays that only allow accesses
  within a given length

# Discussion

## Overview

- ML-language type systems are a static capability language that can manage
  permissions
- Crucial limitation: relies on implementer to manually verify the trusted
  kernel

## On trusting trust

- We don't have formal guarantee that the 'trusted kernel' is safe
- But it's easier to work towards it since we're isolating smaller components
  that need to be verified

## (Comparisons to) dependent type systems

- Can be thought of as a 'poor man's dependent types'
- Instead of lifting values to type level, we _proxy_ values using designated
  types
- Instead of trusting fully automated proofs, we manually verify and trust a
  kernel of code

## On continuation-passing style

- Used for performance reasons in OCaml
- Can be ugly
- Might be mitigated by using option types instead and letting a more
  optimising compiler (OCaml's flambda optimiser?) erase them

# Not just for OCaml

## How do you guarantee that a list should be sorted?

## Sorted list in Java

```java
import java.util.*;

final class SortedList<A extends Comparable<A>> {
  private ArrayList<A> _list;

  public SortedList(List<A> list) {
    _list = new ArrayList<>(list); _list.sort(null);
  }

  public List<A> toList() {
    // We know this is safe, but Java doesn't because of type erasure.
    return (List<A>)_list.clone();
  }
}
```

## Implementation notes

- Not a value type so will pay price of allocation
- Immediately sort internal list on construction to enforce invariant
- Enforcing that elements are comparable--needed for sort
- Return shallow copy of internal list--prevent changes
- Use composition rather than inheritance to manage invariants more
  precisely
- Could also use an immutable list type like from
  [http://www.functionaljava.org/](http://www.functionaljava.org/javadoc/4.7/functionaljava/index.html)

## Trade-offs

- Manually implement internal sorting
- `SortedList<A>` is an abstract type that certifies list sorting
- IOW, guarantee that function that takes a `SortedList<A>` will get a sorted
  list
- Sort _once,_ reuse everywhere that needs the sorted list, with same
  guarantee

# Bonus

## C++

From [https://github.com/I3ck/FlaggedT](https://github.com/I3ck/FlaggedT):

```cpp
//if no exception is thrown, wrapped is now guarenteed >= 0
auto wrapped = NonNegative<int>(3);

auto wontCompile = NonNull<int*>(nullptr); //won't compile

//creating any Sorted<T> will directly sort its data and keep it that way
auto alwaysSorted =
  Sorted<std::vector<int>>(std::vector<int>({4,9,2,13,15,17}));
```

Look familiar? 😊
