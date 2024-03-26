module Rustd
  # The DataMut class is a mutable version of the ruby `Data` class. It's
  # similar to the `Struct` class, but with the minimal API of the `Data` class.
  #
  # Based on https://github.com/oracle/truffleruby/blob/master/src/main/ruby/truffleruby/core/data.rb
  #
  # ```
  # Measure = DataMut.define(:amount, :unit)
  #
  # # Positional arguments constructor is provided
  # distance = Measure.new(10, 'km')
  # #=> #<data Measure amount=100, unit="km">
  #
  # # Keyword arguments constructor is provided
  # weight = Measure.new(amount: 50, unit: 'kg')
  # #=> #<data Measure amount=50, unit="kg">
  #
  # # Alternative form to construct an object:
  # speed = Measure[10, 'mPh']
  # #=> #<data Measure amount=10, unit="mPh">
  #
  # # Works with keyword arguments, too:
  # area = Measure[amount: 1.5, unit: 'm^2']
  # #=> #<data Measure amount=1.5, unit="m^2">
  #
  # # Argument accessors are provided:
  # distance.amount #=> 100
  # distance.unit #=> "km"
  # ```
  class MutData
    CLASS_DESCRIPTOR = 'data'.freeze

    class << self
      # Make sure we don't call `new` on the base class
      undef_method(:new)

      def allocate
        # Make sure we don't call `allocate` on the base class.
        # Note: raises TypeError for compatibility with the Data class.
        raise TypeError, "allocator undefined for #{self}"
      end

      def define(*class_members, &block)
        members_hash = {}

        # Validate members and initialize member_hash
        class_members.each do |m|
          unless m.is_a?(Symbol) || m.is_a?(String)
            raise TypeError, "#{m.inspect} is not a symbol"
          end

          member = m.to_sym

          # We test this first as the MRI return an ArgumentError for this case
          if member.end_with?('=')
            raise ArgumentError, "invalid member: #{member}"
          end

          # Here we diverge from Data & Struct as we only allow valid instance
          # variable names.
          unless /^[_\p{Alpha}\P{ASCII}][_=\p{Alnum}\P{ASCII}]*$/.match?(member)
            raise NameError, "#{member} is not allowed as a member"
          end

          if members_hash[member]
            raise ArgumentError, "duplicate member: #{member}"
          end

          members_hash[member] = true
        end

        members = members_hash.keys
        members.freeze
        members_hash.freeze

        klass = Class.new(self) do
          const_set(:MEMBERS, members)
          const_set(:MEMBERS_HASH, members_hash)

          class << self
            def members = self::MEMBERS.dup

            # `define` was only for the base class
            undef_method(:define) if method_defined?(:define)
            # re-add the original `allocate` method in subclasses
            define_method(:allocate, BasicObject.method(:allocate))

            def new(*args, **kwargs)
              # Check and convert args or kwargs to kwargs so we can call
              # initialize with kwargs.

              arity = self::MEMBERS.size
              if !args.empty? && !kwargs.empty?
                raise ArgumentError,
                  'wrong number of arguments ' \
                  "(given #{args.size + 1}, expected #{arity})"
              end

              if kwargs.empty?
                if args.size > arity
                  raise ArgumentError,
                    'wrong number of arguments ' \
                    "(given #{args.size}, expected 0..#{arity})"
                end

                args.each_with_index { |arg, i| kwargs[self::MEMBERS[i]] = arg }
              end

              instance = allocate
              instance.send(:initialize, **kwargs)

              instance
            end
            alias_method(:[], :new)
          end

          # Define accessors for the members
          members.each do |member|
            # Hide the members in the singleton class
            define_method(member) do
              singleton_class.instance_variable_get(:"@#{member}")
            end
            define_method(:"#{member}=") do |value|
              singleton_class.instance_variable_set(:"@#{member}", value)
            end
          end
        end

        instance_methods_module = Module.new
        instance_methods_module.module_eval <<~'RUBY', __FILE__, __LINE__ + 1
          def initialize(**kwargs)
            members_hash = self.class::MEMBERS_HASH
            kwargs.each do |member, value|
              member = member.to_sym
              if members_hash.include?(member)
                singleton_class.instance_variable_set("@#{member}", value)
              else
                raise ArgumentError, "unknown keyword: :#{member}"
              end
            end

            if kwargs.size < members_hash.size
              missing_keywords = members_hash.keys - kwargs.keys
              keyword = missing_keywords.size == 1 ? "keyword" : "keywords"
              raise ArgumentError,
                    "missing #{keyword}: #{missing_keywords.join(', ')}}"
            end
            # self.freeze
          end

          def initialize_copy(other)
            other.class::MEMBERS.each do |member|
              singleton_class.instance_variable_set(
                "@#{member}",
                other.singleton_class.instance_variable_get("@#{member}")
              )
            end
            # self.freeze
            self
          end
        RUBY

        klass.include instance_methods_module
        klass.module_eval(&block) if block

        klass
      end
    end

    def members = self.class.members

    def with(**changes)
      return self if changes.empty?

      self.class.new(**to_h.merge(changes))
    end

    def to_h(&block)
      h = {}
      self.class::MEMBERS.each do |member|
        h[member] = singleton_class.instance_variable_get(:"@#{member}")
      end
      block ? h.to_h(&block) : h
    end

    def deconstruct
      self.class::MEMBERS.map do |member|
        singleton_class.instance_variable_get(:"@#{member}")
      end
    end

    def deconstruct_keys(keys)
      return to_h if keys.nil?

      unless keys.is_a?(Array)
        raise TypeError,
          "wrong argument type #{keys.class} (expected Array or nil)"
      end

      members_hash = self.class::MEMBERS_HASH
      return {} if members_hash.size < keys.size

      h = {}
      keys.each do |requested_key|
        case requested_key
        when Symbol
          symbolized_key = requested_key
        when String
          symbolized_key = requested_key.to_sym
        end

        if members_hash.include?(symbolized_key)
          h[requested_key] = singleton_class
            .instance_variable_get(:"@#{symbolized_key}")
        else
          return h
        end
      end
      h
    end

    def ==(other)
      return true if self.equal?(other)
      return false unless self.class == other.class

      detect_pair_recursion(self, other, :==) do
        return self.deconstruct == other.deconstruct
      end

      # Subtle: if we are here, we are recursing and haven't found any
      # difference, so:
      true
    end

    def eql?(other)
      return true if self.equal?(other)
      return false unless self.class == other.class

      detect_pair_recursion(self, other, :eql?) do
        return self.deconstruct.eql?(other.deconstruct)
      end

      # Subtle: if we are here, we are recursing and haven't found any
      # difference, so:
      true
    end

    def hash
      klass = self.class
      members = klass::MEMBERS

      h = [klass.hash]
      h << members.size

      detect_outermost_recursion(self, :hash) do
        members.each do |member|
          h << singleton_class.instance_variable_get(:"@#{member}").hash
        end
      end

      h.hash
    end

    def inspect
      klass = self.class
      desc = klass::CLASS_DESCRIPTOR
      class_name = klass.name.to_s
      Thread.current[:__recursive_enum__] ||= Hash.new([])

      if Thread.current[:__recursive_enum__][:inspect].include?(self.object_id)
        "#<#{desc} #{class_name}:...}>"
      else
        begin
          Thread.current[:__recursive_enum__][:inspect] << self.object_id
          members_and_values = to_h.map do |member, value|
            " #{member}=#{value.inspect}"
          end.join(',')
          "#<#{desc} #{class_name}#{members_and_values}>"
        ensure
          Thread.current[:__recursive_enum__][:inspect].pop
        end
      end
    end
    alias_method :to_s, :inspect

    def pretty_print(q)
      klass = self.class
      desc = klass::CLASS_DESCRIPTOR
      class_name = self.class.name.to_s

      q.group(1, sprintf('#<%s %s', desc, class_name), '>') do
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
      desc = klass::CLASS_DESCRIPTOR
      class_name = klass.name.to_s

      q.text sprintf('#<%s %s:...>', desc, class_name)
    end

    private

      # detect_recursion will return if there's a recursion on obj. If there is
      # one, it returns true. Otherwise, it will yield once and return false.
      def detect_recursion(obj, method, &block)
        Thread.current[:__recursive_enum__] ||= {}
        objects = Thread.current[:__recursive_enum__][method] ||= []

        return true if objects.include?(self.object_id)

        begin
          objects << self.object_id
          yield self
        ensure
          objects.pop
        end

        false
      end

      def detect_pair_recursion(obj, paired_obj, method, &block)
        id = obj.object_id
        pair_id = paired_obj.object_id
        Thread.current[:__recursive_pair_enum__] ||= {}
        objects = Thread.current[:__recursive_pair_enum__][method] ||= {}

        case objects[id]

        # Default case, we haven't seen `obj` yet, so we add it and run the
        # block.
        when nil
          objects[id] = pair_id
          begin
            yield
          ensure
            objects.delete(id)
          end

        # We've seen `obj` before and it's got multiple paired objects
        # associated with it, so check the pair and yield if there is no
        # recursion.
        when Hash
          return true if objects[id][pair_id]

          objects[id][pair_id] = true
          begin
            yield
          ensure
            objects[id].delete(pair_id)
          end

        # We've seen `obj` with one paired object, so check the stored one for
        # recursion.
        #
        # This promotes the value to a Hash since there is another new paired
        # object.
        else
          previous = objects[id]
          return true if previous == pair_id

          objects[id] = {previous => true, pair_id => true}
          begin
            yield
          ensure
            objects[id] = previous
          end
        end

        false
      end

      class InnerRecursionDetected < Exception; end # rubocop:disable Lint/InheritException

      # Similar to detect_recursion, but will short circuit all inner recursion
      # levels
      def detect_outermost_recursion(obj, method, &)
        rec = Thread.current[:__recursive_enum__] ||= {}

        # If we are already running the outer recursion detection
        if rec.key?(:__detect_outermost_recursion__)
          # Run the block (unless we've seen self before)
          recursive = detect_recursion(obj, method, &)
          # If we've seen self, unwind back to the outer version
          raise InnerRecursionDetected if recursive
          false

        # Otherwise, we are the outermost version
        else
          rec[:__detect_outermost_recursion__] = true
          begin
            begin
              # Note: this might/will be recursive and probably call
              # `detect_outermost_recursion` again (see `hash` below for
              # example)
              detect_recursion(obj, method, &block)

            # An inner version will raise to return back here, indicating that
            # the whole structure is recursive. In which case, abandon most of
            # the work and return true.
            rescue InnerRecursionDetected
              return true
            end
            nil
          ensure
            rec.delete(:__detect_outermost_recursion__)
          end
        end
      end
  end
end
