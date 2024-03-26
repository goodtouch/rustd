module Rustd
  # The MutEnum class allows the creation of a type that can only be one of a
  # fixed set of variants. Each variant can have any number of named mutable
  # members, which can be accessed with dot notation, and use to pattern-match
  # values of the corresponding enumerated type.
  #
  # ```
  # class Animal < Rustd::MutEnum
  #   Dog = Animal.variant
  #   Cat = Animal.variant
  # end
  #
  # a = Animal::Dog
  # ```
  #
  # ## Variants
  #
  # Variants are defined with {.variant} and takes an optional list of symbols,
  # which represent the names of the members of the variant.
  #
  # ```
  # class Message < Rustd::MutEnum
  #   Quit = Message.variant
  #   Move = Message.variant(:x, :y)
  #   Write = Message.variant(:content)
  #   ChangeColor = Message.variant(:r, :g, :b)
  # end
  # ```
  #
  # The members can be accessed with dot notation:
  #
  # ```
  # msg = Message::Write.new("hello")
  # msg.content # => "hello"
  # msg.content += " world"
  # msg.content # => "hello world"
  # ```
  #
  # ## Constructors
  #
  # Variants can be instantiated with `new`.
  #
  # The `new` method takes keyword arguments, where the keys are the names of
  # the variant members.
  #
  # The values of the members can be any Ruby object.
  #
  # ```
  # msg = Message::Move.new(x: 2, y: 3)
  # msg.x # => 2
  # ```
  #
  # The `new` method can also be called with positional arguments where the
  # order of the arguments matches the order of the members' definition:
  #
  # ```
  # msg = Message::Move.new(2, 3)
  # msg.x # => 2
  # ```
  #
  # ## Pattern matching
  #
  # The `case` statement can be used to pattern match on the variant:
  #
  # ```
  # msg = Message::Move.new(3, 4)
  #
  # case msg
  # in Message::Quit
  #   puts "I got Quit"
  # in Message::Move(x, y)
  #   puts "I got Move to #{x.value}, #{y.value}"
  # in Message::Write
  #   puts "I got a new message:"
  #   puts msg.content
  # in Message::ChangeColor(r, g, b)
  #   puts "Changing color to rgb(#{r}, #{g}, #{b})"
  # end
  # ```
  class MutEnum < MutData
    CLASS_DESCRIPTOR = 'enum'

    class << self
      undef_method(:define)

      # @!method variant(*members, &block)
      #   Define a new variant of the enum.
      #   @abstract This method is only implemented in subclasses of {MutEnum}.
      #   @param members [Array<Symbol>] the members of the variant -
      #     optional
      #   @param block [Proc] a block to be evaluated in the context of the
      #    variant class definition - optional

      # @!method variants
      #   List of all the variants of the enum.
      #   @abstract This method is only implemented in subclasses of {MutEnum}.
      #   @return [Array<Class>]

      def inherited(subclass) # :nodoc:
        class << subclass
          define_method(:variant, MutData.method(:define))
          alias_method :variants, :subclasses
        end
      end
    end
  end
end
