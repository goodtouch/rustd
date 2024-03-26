# Robust Error Handling with Result

## Problem

Exception-based error handling is very powerful when you want to fail fast, or bubble exception at some higher level functions. But they are also error-prone, especially when used to model expected domain errors and want to make sure callers handle all the outcomes, and adapt the flow accordingly.

Functional programming languages like Elixir, Haskell, and Rust generally use a different approach to error handling, where functions return a value that represents the result of the operation, either a success or a failure.

I've seen a lot of projects using `dry-monads` for this, but I have mixed feelings about it.

I find the source code of `dry-rb` very interesting to explore and look at. It showcases a lot of functional programming concepts applied Ruby and is heavily documented.

But as a "consumer" of the gem, I also think that it's overkill and too complex for most Ruby projects. It forces the caller to become an expert in functional idioms (and/or in the full `dry-*` ecosystem and notations as soon as you start adding more) just so they can call the API.

The complexity of the implementation makes it a risk for the team to integrate (and potentially maintain) as a dependency.

And as soon as people start extracting some components (let's say API clients for example) from their main project into external gems (so that they can share common utils between 1, 2 or 100 services), managing the conflicting versions of the `dry-*` dependencies that end up in each project's Gemfile can become a nightmare.

## Proposed Solution

Implement a lightweight `Result` type using enums to encapsulate the outcome of operations that can either succeed or fail.

This type would encourage explicit handling of errors through pattern matching, and make functions' success or failure pathways clear whenever you need to.

We shouldn't have to explain what a "monad" is to use a `Result`. And if you look at the Rust documentation, you won't find the word "monad" anywhere. The Result type is just a simple wrapper enum with two variants: `Ok` and `Err` and a few methods to help you work with it.

## Implementation Strategy

We'll use the Rust API as a reference to design the API. It should be simple, user-friendly and stable. It will also make it easier to port code from Rust to Ruby and vice versa.

Keep the implementation as simple as possible. The implementation of the `Ok` and `Err` variants are very symmetrical. An implementation using pattern matching inside the `Result` class should be much more readable and maintainable than splitting the logic between two classes.

Consider this implementation:

```ruby
class Result < Rustd::Enum
  Ok = Result.variant(:value)
  Err = Result.variant(:error)

  def is_ok
    self in Ok(_)
  end

  def map
    case self
    in Ok(value) then Ok.new(yield(value))
    in Err(_) then self
    end
  end

  def map_err
    case self
    in Ok(_) then self
    in Err(error) then Err.new(yield(error))
    end
  end

  def map_or(default)
    case self
    in Ok(value) then yield(value)
    in Err(_) then default
    end
  end
end
```

Versus this one that would force you to jump back and forth between the two classes/files to understand the logic, increasing the cognitive load (and the risk of introducing bugs):

```ruby
class Result
  def is_ok = raise NotImplementedError
  def map = raise NotImplementedError
  def map_err = raise NotImplementedError
  def map_or(default) = raise NotImplementedError
end

class Ok < Result
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def is_ok
    true
  end

  def map
    Ok.new(yield(value))
  end

  def map_or(default)
    yield(value)
  end

  def map_err
    self
  end
end

class Err < Result
  attr_reader :error

  def initialize(error)
    @error = error
  end

  def is_ok
    false
  end

  def map
    self
  end

  def map_or(default)
    default
  end

  def map_err
    Err.new(yield(error))
  end
end
```
