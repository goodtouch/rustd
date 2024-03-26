# Traits for Shared Behavior

## Problem

Ruby doesn't have a native support for interfaces or traits, which are powerful tools for defining shared behaviors in a more flexible and composable way than traditional inheritance or mixins.

We generally use mixins (/concerns) or inheritance (with abstract classes and virtual methods) to achieve similar results.

While these approaches work well in many cases, they make it hard to enforce the implementation of required methods (conforming to contracts, interfaces or protocols).

Some people argue that [tests are better than interfaces](https://morningcoffee.io/interfaces-in-ruby.html), but I tend to disagree on this one.

Although tests are fine, I think we can easily do better.

<!-- It's also not easy to dynamically compose behaviors from multiple sources without conflicts (especially when the source code we want to extand is not under our control). -->

## Proposed Solution

Adapt Rust's traits into Ruby as a means to define shared behavior across classes and modules in a more flexible and composable way than traditional inheritance or mixins.

We can use the same constructs we already use in mixins (and `ActiveSupport::Concern`s) to declare the `required_methods`, and then use the `impl` keyword to scope their implementation for a specific class while also enforcing that all (and only) required methods are implemented during "load time".

This could offer a powerful tool for code reuse and polymorphism, encouraging more modular and decoupled design patterns within Ruby applications.

Example:

```ruby
module ZeroWing
  module RequiredMethods # or: required_methods do
    def bases; end
    def survive; end
  end

  def transcript
    <<~TRANSCRIPT
      Mechanic: Somebody set up us the bomb.
      Operator: Main screen turn on.
      CATS: #{bases}.
      CATS: #{survive}.
      Captain: Move 'ZIG'.
      Captain: For great justice.
    TRANSCRIPT
  end
end

# Example 1

class English
  include Rustd::Impl

  impl ZeroWing do
    def bases
      'All your base are belong to us'
    end

    def survive
      'You have no chance to survive make your time'
    end
  end
end

English.new.transcript

# Example 2

class WillRaiseError
  include Rustd::Impl

  impl ZeroWing do
    def bases
      'All your base are'
    end
  end
end
#=> raises Required method `survive` not implemented

# Example 3 (must-have/nice-to-have?)

class NotExtendedYet; end

impl ZeroWing, for: NotExtendedYet do
  def bases
    "All your base are belong to us"
  end

  def survive
    "You have no chance to survive make your time"
  end
end
```

<!--

**TODO:**

> Elaborate and talk about:

- `trait` and `impl` in Rust
  - https://doc.rust-lang.org/book/ch10-02-traits.html
- Ruby doesn't have a native support for interfaces or traits
- We generally use Mixins (& Concerns)
- Abstract classes (+ virtual methods)
- [The Power of Interfaces in Ruby — by Igor Šarčević](https://morningcoffee.io/interfaces-in-ruby.html)
  - recommands using unit tests to ensure that the classes that include the module implement the methods, and says that tests are better than interfaces (for which I tend to disagree, although I understand the point of view and like that it can do some type & arity checking)
- Interfaces in Sorbet
  https://sorbet.org/docs/abstract
- Refinements?
- Extend concerns & mixins to implement this

-->
