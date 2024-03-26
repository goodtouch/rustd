# rubocop:disable Layout/LeadingCommentSpace
module Rustd
  # Represents an optional value: every `Option` is either `Some` and contains
  # a value, or `None`, and does not.
  class Option < Enum
    # No value
    None = Option.variant
    # Some value
    Some = Option.variant(:value)

    # Creates an instance of `Option::Some` variant.
    def self.Some(value) = Some[value]

    # No value.
    def self.None = None

    #region:    --- Querying the contained values

    # @!group Querying the contained values

    # Returns `true` if the option is a `Option::Some` value.
    #
    # @return [Boolean]
    #
    # # Examples
    #
    # ```
    # include Rustd
    #
    # x = Option::Some.new(2)
    # x.is_some # => true
    #
    # x = Option::None
    # x.is_some # => false
    # ```
    def is_some
      self in Some(_)
    end

    # FIXME: document
    def is_some_and(f = nil, &block)
      raise NotImplementedError
    end

    # FIXME: document
    def is_none
      !is_some
    end

    # @!endgroup

    #endregion: --- Querying the contained values

    #region:    --- Getting to contained values

    # @!group Getting to contained values

    # FIXME: document
    # @raise RuntimeError if the value is `None`
    def expect(msg)
      case self
      in Some(val) then val
      in None then raise msg
      end
    end

    # FIXME: document
    # @raise RuntimeError if the value is `None`
    def unwrap
      case self
      in Some(val) then val
      in None then raise 'called `Option#unwrap()` on a `None` value'
      end
    end

    # FIXME: document
    def unwrap_or(default)
      case self
      in Some(val) then val
      in None then default
      end
    end

    def unwrap_or_else(f = nil, &block)
      fn = f || block
      expect_callable_argument!(fn)

      case self
      in Some(val) then val
      in None then fn.call
      end
    end

    # @!endgroup

    #endregion: --- Getting to contained values

    #region:    --- Transforming contained values

    # @!group Transforming contained values

    # FIXME: document
    def map(f = nil, &block)
      fn = f || block
      expect_callable_argument!(fn)

      case self
      in Some(val) then Some(fn.call(val))
      in None then None
      end
    end

    # FIXME: document
    def map_or(default, f = nil, &block)
      fn = f || block
      expect_callable_argument!(fn)

      case self
      in Some(val) then fn.call(val)
      in None then default
      end
    end

    # FIXME: document
    def map_or_else(default, f)
      expect_callable_argument!(default, with_block: false)
      expect_callable_argument!(f, with_block: false)

      case self
      in Some(val) then f.call(val)
      in None then default.call
      end
    end

    # FIXME: document
    def ok_or(err)
      case self
      in Some(val) then Ok(val)
      in None then Err(err)
      end
    end

    # FIXME: document
    def ok_or_else(f = nil, &block)
      fn = f || block
      expect_callable_argument!(fn)

      case self
      in Some(val) then Ok(val)
      in None then Err(fn.call)
      end
    end

    #region:    --- Boolean operations on the values, eager and lazy

    # @!group Boolean operations on the values, eager and lazy

    # FIXME: document
    def and(other)
      case self
      in Some(_) then other
      in None then None
      end
    end

    # FIXME: document
    def and_then(f = nil, &block)
      fn = f || block
      expect_callable_argument!(fn)

      case self
      in Some(val) then fn.call(val)
      in None then None
      end
    end

    # FIXME: document
    def filter(predicate = nil, &block)
      predicate ||= block
      expect_callable_argument!(predicate)

      case self
      in Some(val) then predicate.call(val) ? self : None
      in None then None
      end
    end

    # FIXME: document
    def or(other)
      case self
      in Some(_) => x then x
      in None then other
      end
    end

    # FIXME: document
    def or_else(f = nil, &block)
      fn = f || block
      expect_callable_argument!(fn)

      case self
      in Some(_) => x then x
      in None then fn.call
      end
    end

    # FIXME: document
    def xor(other)
      case [self, other]
      in [Some(_) => a, None] then a
      in [None, Some(_) => b] then b
      in _ then None
      end
    end

    # @!endgroup

    #endregion: --- Boolean operations on the values, eager and lazy

    #endregion: --- Transforming contained values

    # FIXME: document
    def flatten
      case self
      in Some(Some(_) => inner) then inner
      in None then None
      in _
        raise TypeError.new(
          "called `Option#flatten()` on non `Option` value: #{self.inspect}}"
        )
      end
    end

    private

      def expect_callable_argument!(fn, with_block: true)
        unless fn.respond_to?(:call)
          target = with_block ? 'object or block' : 'object'
          raise ArgumentError.new(
            "expected a callable #{target}, got: #{fn.inspect}"
          )
        end
      end
  end
end

# rubocop:enable Layout/LeadingCommentSpace
