module Rustd
  # The Enum class allows the creation of a type that can only be one of a
  # fixed set of variants. Each variant can have any number of named members,
  # which can be accessed with dot notation, and use to pattern-match values
  # of the corresponding enumerated type.
  #
  # ```
  # class Animal < Rustd::Enum
  #   Dog = Animal.define
  #   Cat = Animal.define
  # end
  #
  # a = Animal::Dog
  # ```
  #
  # ## Variants
  #
  # Variants are defined with {.define} and takes a list of symbols, which
  # represent the names of the members of the variant.
  #
  # ```
  # class Message < Rustd::Enum
  #   Quit = Message.define
  #   Move = Message.define(:x, :y)
  #   Write = Message.define(:content)
  #   ChangeColor = Message.define(:r, :g, :b)
  # end
  # ```
  #
  # The members can be accessed with dot notation:
  #
  # ```
  # msg = Message::Write.new("hello")
  # msg.content # => "hello"
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
  class Enum < Data
    class << self
      undef_method(:define)

      def inherited(subclass) # :nodoc:
        class << subclass
          define_method(:variant, Data.method(:define))
          alias_method :variants, :subclasses
        end
      end

      # So that we can case match.
      #
      # i.e.
      #   case action # where action is either an Action::Attack or Action::Heal.new(...)
      #   when Action::Attack
      #     ...
      #   end
      #
      # TODO: make sure we want to keep this feature
      def === other
        if other.is_a?(Class)
          self >= other || false # Module#>= can return nil
        else
          super(other)
        end
      end

      # So that we can do a is_a? at the class level.
      #
      # i.e. Action::Attack.is_a?(Action) #=> true
      #
      # TODO: make sure we want to keep this feature?
      def kind_of?(other)
        self <= other || super(other)
      end

      alias_method :is_a?, :kind_of?
    end

    def inspect
      klass = self.class
      class_name = klass.name.nil? ? '' : klass.name
      # Used to detect and break recursion while inspecting cyclic enums
      Thread.current[:__recursive_enum__] ||= Hash.new([])

      if Thread.current[:__recursive_enum__][:inspect].include?(self.object_id)
        "#<enum #{class_name}:...}>"
      else
        begin
          Thread.current[:__recursive_enum__][:inspect] << self.object_id
          members_and_values = to_h.map do |member, value|
            " #{member}=#{value.inspect}"
          end.join(',')
          "#<enum #{class_name}#{members_and_values}>"
        ensure
          Thread.current[:__recursive_enum__][:inspect].pop
        end
      end
    end
    alias_method :to_s, :inspect

    def pretty_print(q) # :nodoc:
      klass = self.class
      class_name = klass.name.nil? ? '' : klass.name

      q.group(1, sprintf('#<enum %s', class_name), '>') do
        q.seplist(members, lambda { q.text ',' }) do |member|
          q.breakable
          q.text member.to_s
          q.text '='
          q.group(1) do
            q.breakable ''
            q.pp public_send(member)
          end
        end
      end
    end

    def pretty_print_cycle(q) # :nodoc:
      klass = self.class
      class_name = klass.name.nil? ? '' : klass.name

      q.text sprintf('#<enum %s:...>', class_name)
    end
  end
end
