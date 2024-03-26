# rubocop:disable Layout/LeadingCommentSpace
module Rustd
  class Result < Enum
    # Contains the success value.
    Ok = Result.variant(:value) do
      def initialize(value: Unit)
        super(value:)
      end
    end

    # Contains the error value.
    Err = Result.variant(:error)

    # Creates an instance of [Ok] variant.
    # @see Kernel.Array for example of this style of naming/defining ctors.
    def self.Ok(v = Unit) = Ok.new(v)

    # Creates an instance of [Err] variant.
    # @see Kernel.Array for example of this style of naming/defining ctors.
    def self.Err(e) = Err.new(e)

    # Returns `true` if the result is [Ok].
    #
    # # Examples
    #
    # ```
    # include Rustd
    #
    # x = Ok(-2)
    # x.is_ok # => true
    #
    # x = Err("Some error message")
    # x.is_ok # => false
    # ```
    #
    # @return [Boolean]
    def is_ok
      self in Result::Ok(_)
    end

    # Returns `true` if the result is [Ok] and the value inside of it
    #   matches a predicate.
    #
    # # Examples
    #
    # ```
    # include Rustd
    #
    # x = Ok(2)
    # x.is_ok_and { |x| x > 1 } # => true
    #
    # x = Ok(0)
    # x.is_ok_and { |x| x > 1 } # => false
    #
    # x = Err("hey")
    # x.is_ok_and { |x| x > 1 } # => false
    # ```
    #
    # @param f [Proc<T, Boolean>, #call] the predicate to test if [Ok]. Can be
    #   provided as a block instead.
    # @yield [value] the success value
    # @yieldreturn [Boolean] whether the success value matches a predicate
    # @return [Boolean]
    def is_ok_and(f = nil, &block)
      case self
      in Result::Ok(x)
        !!(f || block).call(x)
      in Result::Err
        false
      end
    end

    # Returns `true` if the result is [Err].
    #
    # # Examples
    #
    # ```
    # include Rustd
    #
    # x = Ok(-3)
    # x.is_ok # => false
    #
    # x = Err("Some error message")
    # x.is_ok # => true
    # ```
    #
    # @return [Boolean]
    def is_err
      !is_ok
    end

    # Returns `true` if the result is [Err] and the value inside of
    # it matches a predicate.
    #
    # # Examples
    #
    # ```
    # include Rustd
    #
    # Error = Data.define(:kind, :message)
    # ErrorKind = Class.new(Enum)
    # ErrorKind::NotFound = ErrorKind.define
    # ErrorKind::PermissionDenied = ErrorKind.define
    #
    # x = Err(Error.new(ErrorKind::NotFound, "!"))
    # x.is_err_and { |x| x.kind == ErrorKind::NotFound } # => true
    #
    # x = Err(Error.new(ErrorKind::PermissionDenied, "!"))
    # x.is_err_and { |x| x.kind == ErrorKind::NotFound } # => false
    #
    # x = Ok(123)
    # x.is_err_and { |x| x.kind == ErrorKind::NotFound } # => false
    # ```
    #
    # @param f [Proc<E, Boolean>, #call] the predicate to test if [Err]. Can
    #   be provided as a block instead.
    # @yield [error] the error value
    # @yieldreturn [Boolean] whether the error value matches a predicate
    # @return [Boolean]
    def is_err_and(f = nil, &block)
      case self
      in Result::Ok
        false
      in Result::Err(e)
        # TODO: get return type and check if it's a boolean instead
        !!(f || block).call(e)
      end
    end

    #region:    --- Adapters for each variants

    # # @!group Adapters for each variants

    # Converts from [Result<T, E>] to [Option<T>].
    #
    # Converts `self` into an [Option<T>], discarding the error, if any.
    #
    # # Examples
    #
    # ```
    # include Rustd
    #
    # x = Ok(2)
    # x.ok() # => Some(2)
    #
    # x = Err("Nothing here")
    # x.ok() # => None
    # ```
    #
    # @return [Option<T>]
    # TODO: Implement Option first
    # def ok
    #   case self
    #   in Ok(x) then Option::Some(x)
    #   in Err(_) then Option::None
    #   end
    # end

    # Converts from [Result<T, E>] to [Option<E>].
    #
    # Converts `self` into an [Option<E>], discarding the success value, if
    # any.
    #
    # # Examples
    #
    # ```
    # include Rustd
    #
    # x = Ok(2)
    # x.err() # => None
    #
    # x = Err("Nothing here")
    # x.err() # => Some("Nothing here")
    # ```
    #
    # @return [Option<E>]
    # TODO: Implement Option first
    # def err
    #   case self
    #   in Ok(_) then Option::None
    #   in Err(e) then Option::Some(e)
    #   end
    # end

    #endregion: --- Adapters for each variants

    #region:    --- Adapters for working with references

    # Ignoring adapters for working with references
    #
    # ignored def as_ref
    # ignored def as_mut

    #endregion: --- Adapters for working with references

    #region:    --- Transforming contained values

    # @!group Transforming contained values

    # Maps a [Result<T, E>] to [Result<U, E>] by applying a function to a
    # contained [Ok] value, leaving an [Err] value untouched.
    #
    # This function can be used to compose the results of two functions.
    #
    # # Examples
    #
    # ```
    # include Rustd
    #
    # def parse_int(str)
    #   Ok(Integer(str))
    # rescue => e
    #   Err(e)
    # end
    #
    # line = "1\n2\n3\n4\nabc\n"
    #
    # line.lines(chomp: true).map do |num|
    #   case parse_int(num).map { |i| i * 2 }
    #   in Ok(x) then x
    #   in Err(**) then Unit
    #   end
    # end
    # # => [2, 4, 6, 8, Unit]
    # ```
    # TODO: maybe change signature to `map(op=nil, &block)`
    #
    # @param f [Proc<T, U>, #call] the function to call if [Ok]. Can be
    #   provided as a block instead.
    # @yield [value] the success value
    # @yieldreturn [U] the transformed success value
    # @return [Result<U, E>]
    def map(f = nil, &block)
      fn = f || block

      case self
      in Ok(x) then Result::Ok(fn.call(x))
      in Err(_) then self
      end
    end

    # Returns the provided default (if [Err]), or applies a function to the
    # contained value (if [Ok]).
    #
    # Arguments passed to `map_or` are eagerly evaluated; if you are passing
    # the result of a function call, it is recommended to use {#map_or_else},
    # which is lazily evaluated.
    #
    # # Examples
    #
    # ```
    # include Rustd
    #
    # x = Ok("foo")
    # x.map_or(42) { |v| v.size } # => 3
    #
    # x = Err("bar")
    # x.map_or(42) { |v| v.size } # => 42
    # ```
    #
    # @param default [U] the default value to return if [Err]
    # @param f [Proc<T, U>, #call] the function to call if [Ok]. Can be
    #   provided as a block instead.
    # @yield [value] the success value
    # @yieldreturn [U] the transformed success value
    # @return [U]
    def map_or(default, f = nil, &block)
      fn = f || block

      case self
      in Ok(x) then fn.call(x)
      in Err(_) then default
      end
    end

    # Maps a [Result<T, E>] to [U] by applying fallback function `default` to
    # a contained [Err] value, or function `f` to a contained [Ok] value.
    #
    # This function can be used to unpack a successful result while handling
    # an error.
    #
    #
    # # Examples
    #
    # ```
    # k = 21
    #
    # x = Ok("foo")
    # x.map_or_else( -> e { k * 2 }, -> v { v.len() }) # => 3
    #
    # x = Err("bar")
    # x.map_or_else( -> e { k * 2 }, -> v { v.len() }) # => 42
    # ```
    #
    # @param default [Proc<E, U>, #call] the default function to call if [Err]
    # @param f [Proc<T, U>, #call] the function to call if [Ok]
    # @return [U]
    def map_or_else(default, f = nil, &block)
      fn = f || block

      case self
      in Ok(x) then fn.call(x)
      in Err(e) then default.call(e)
      end
    end

    # Maps a [Result<T, E>] to [Result<T, F>] by applying a function to a
    # contained [Err] value, leaving an [Ok] value untouched.
    #
    # This function can be used to pass through a successful result while
    # handling an error.
    #
    # # Examples
    #
    # ```
    # include Rustd
    #
    # stringify = -> e { "error code #{e}" }
    #
    # x = Ok(2)
    # x.map_err(stringify) # => Ok(2)
    #
    # x = Err(13)
    # x.map_err(stringify) # => Err("error code 13")
    # ```
    #
    # @param f [Proc<E, F>, #call] the function to call if [Err]. Can be
    #   provided as a block instead.
    # @yield [error] the error value
    # @yieldreturn [F] the transformed error value
    # @return [Result<T, F>]
    def map_err(f = nil, &block)
      fn = f || block

      case self
      in Ok(_) then self
      in Err(e) then Result::Err(fn.call(e))
      end
    end

    # Calls the provided closure with the contained success value (if [Ok]).
    #
    # # Examples
    #
    # ```
    # include Rustd
    #
    # def parse_int(str)
    #   Ok(Integer(str))
    # rescue => e
    #   Err(e)
    # end
    #
    # x = "4"
    #   .then(&method(:parse_int))
    #   .inspect_ok { |x| puts "original: #{x}" }
    #   .map { |x| x.pow(3) }
    #   .expect
    # ```
    def inspect_ok(f = nil, &block)
      fn = f || block

      fn.call(value) if fn && self in Ok(_)

      self
    end

    # Calls the provided closure with the contained error value (if [Err]).
    #
    # # Examples
    #
    # ```
    # include Rustd
    #
    #
    # ```

    #endregion: --- Transforming contained values

    #region:    --- Extract a value

    # @!group Extract a value

    # Returns the contained [Ok] value.
    #
    # Because this function may raise, its use is generally discouraged.
    # Instead, prefer to use pattern matching and handle the [Err] case
    # explicitly, or call {#unwrap_or}, {#unwrap_or_else}, or
    # {#unwrap_or_default}.
    #
    # # Raises
    #
    # Raises the self is [Err], with a message including the passed message,
    # and the content of the [Err].
    #
    # # Examples
    #
    # ```
    # x = Err("emergency failure")
    # x.expect("Testing expect") # => raises "Testing expect: emergency failure"
    # ```
    #
    # # Recommended Message Style
    #
    # We recommend that {#expect} messages are used to describe the reason you
    # _expect_ the [Result] to be [Ok].
    #
    # ```
    # path = Env.var("IMPORTANT_PATH")
    #   .expect("env variable `IMPORTANT_PATH` should be set by `wrapper_script.sh`")
    # ```
    #
    # **Hint**: If you're having trouble remembering how to phrase expect
    # error messages remember to focus on the word "should" as in "env
    # variable should be set by blah" or "the given binary should be available
    # and executable by the current user".
    #
    # @param msg [String] the message to include in the error. @raise
    # [RuntimeError] if self is [Err]. @return [T]
    def expect(msg)
      case self
      in Ok(t) then t
      in Err(e) then unwrap_failed!(msg, e)
      end
    end

    #endregion: --- Extract a value

    private

      # @raise [RuntimeError] if self is [Err].
      def unwrap_failed!(msg, error)
        raise "#{msg}: #{error.inspect}"
      end
  end
end

# rubocop:enable Layout/LeadingCommentSpace
