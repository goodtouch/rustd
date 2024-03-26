# Enumerations with Associated Data

In Rust, enums are not just a set of named values; they can also hold data. Each variant of an enum can have its own data type and structure.

Using a sum type and pattern matching makes them a powerful tool for creating type-safe unions, and model complex data with clarity.

## Problem

In Ruby, we typically use a mix of classes, modules, symbolic constants and/or inheritance to represent variants their associated data.

However, those approaches can be verbose and less expressive than Rust's enums.

Let's have a look at some examples:

```ruby
class Card
  attr_accessor :rank, :suit

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
  end

  def name
    "#{@rank} of #{@suit}"
  end
end

module Suit
  SPADES = :spades
  HEARTS = :hearts
  DIAMONDS = :diamonds
  CLUBS = :clubs
end

Card.new(1, Suit::SPADES).name
# => "1 of Spades"
```

Here we are mostly using symbolic constants mapped to symbols as a way make Ruby catch some typos.

As soon as we need to carry associated data, we often end up using more complex approaches like this:

```ruby
class Message
  def call
    raise NotImplementedError, "Subclasses must implement the `call` method"
  end

  class Quit < Message
    def call
      "Quitting..."
    end
  end

  class Move < Message
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def call
      "Moving to (#{@x}, #{@y})"
    end
  end

  class Write < Message
    attr_reader :content

    def initialize(content)
      @content = content
    end

    def call
      "Writing: #{@content}"
    end
  end

  class ChangeColor < Message
    attr_reader :r, :g, :b

    def initialize(r:, g:, b:)
      @r = r
      @g = g
      @b = b
    end

    def call
      "Changing color to (#{@r}, #{@g}, #{@b})"
    end
  end
end

messages = [
  Message::Write.new("Hello, world!"),
  Message::Move.new(1, 2),
  Message::ChangeColor.new(r: 255, g: 0, b: 0),
  Message::Quit.new
]

messages.each { |message| puts message.call }
```

While this approach is not bad, its verbose and leads to a lot of questions:

* Shall `Message` be a namespacing module or a class?
* Should we use an abstract `Base` class and a `Message(s)` module?
* Do we want `Message::Quit.new.is_a?(Message)` to work? Are we ok with just `Message::QuitMessage.new.is_a?(Message::Base)`?
* Should we put our subclasses in dedicated files?
* Should we really use virtual methods and override them in subclasses?
* Wouldn't it be better pattern match on subclasses inside `Message#call` with a simple `case` statement?
  * sure that would break some OOP principles, but if we consider functional programming, this is perfectly fine.
* Should we implement more complex constructors to handle positional and keyword arguments?

There are no right or wrong answers to these questions. They focus more about how to structure the code to make it work than about domain logic, and most the answers could probably be "it depends" (see the [Expression Problem](https://wiki.c2.com/?ExpressionProblem) for example).

Let's look at how we would implement the same thing using Rust:

```rust
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
    ChangeColor { r: u8, g: u8, b: u8 },
}

impl Message {
    fn call(&self) {
        match self {
            Message::ChangeColor { r, g, b } => println!("Changing color to ({}, {}, {})", r, g, b),
            Message::Move { x, y } => println!("Moving to ({}, {})", x, y),
            Message::Quit => println!("Quitting..."),
            Message::Write(content) => println!("Writing: {}", content),
        }
    }
}

fn main() {
    let messages = vec![
        Message::Write("Hello, world!".to_string()),
        Message::Move { x: 1, y: 2 },
        Message::ChangeColor { r: 255, g: 0, b: 0 },
        Message::Quit,
    ];

    for message in messages {
        message.call();
    }
}
```

This is much more concise and expressive thanks to Rust's enums and pattern matching.

I'm pretty sure that even if you're not familiar with Rust, you can read and understand this code.

## Proposed Solution

Let's see how we could introduce a similar construct in Ruby:

```ruby
class Message < Rustd::Enum
  Quit = Message.variant
  Move = Message.variant(:x, :y)
  Write = Message.variant(:content)
  ChangeColor = Message.variant(:r, :g, :b)

  def call
    case self
    in ChangeColor(r, g, b) then "Changing color to (#{r}, #{g}, #{b})"
    in Move(x, y) then "Moving to (#{x}, #{y})"
    in Quit then  "Quitting..."
    in Write(content) then "Writing: #{content}"
    end
  end
end

messages = [
  Message::Write.new("Hello, world!"),
  Message::Move.new(1, 2),
  Message::ChangeColor.new(r: 255, g: 0, b: 0),
  Message::Quit.new
]

messages.each { |message| puts message.call }
```

## Implementation Strategy

You might have noticed that the `Quit = Message.variant` method here looks very similar to the `Data.define` construct introduced in Ruby 3.2 with the [Data class](https://docs.ruby-lang.org/en/3.2/Data.html), and for a good reason as the `Rustd::Enum` class is based on it (replacing `define` with `variant` to better reflect the intent).

The [Data class](https://docs.ruby-lang.org/en/3.2/Data.html) defines constructors with positional and keyword arguments, uses inheritance to `define` Data (`Measure.new(12, 'kg').is_a?(Data)`), and implements the `deconstruct*` methods that enable this cool `case in` pattern matching.

This solves most of the questions we had earlier, and while the Data class was originally designed for value objects, I think it's a very elegant way to implement enums (with or without associated data).

<!--

TODO:

> Add a section about the differences between these implementations and the one proposed in Rustd

- `enum` in Rust
  - https://doc.rust-lang.org/book/ch06-01-defining-an-enum.html
- `T::Enum` in Sorbet
  - https://sorbet.org/docs/tenum
- `Dry::Types::Sum` and `Dry::Types::String.enum` in dry-rb
  - https://dry-rb.org/gems/dry-types/1.2/sum/
  - https://dry-rb.org/gems/dry-types/1.2/enum/
- `ActiveRecord::Enum` in Rails
  - https://api.rubyonrails.org/v5.1/classes/ActiveRecord/Enum.html

> Add implementation details and examples

- Implementation based on the Data class
- Showcase usage of pattern matching using the `case in` statement with the new `enum` construct

-->
