require 'minitest/autorun'
require 'rustd'

class EnumTest < Minitest::Test
  class WebEvent < Rustd::Enum
    # An `Enum` variant may either be `unit-like`:
    PageLoad = variant
    PageUnload = variant
    # or may include data:
    KeyPress = variant(:char)
    Paste = variant(:string)
    Click = variant(:x, :y)

    def to_s
      case self
      in WebEvent::PageLoad
        'page loaded'
      in WebEvent::PageUnload
        'page unloaded'
      # Destructure `c` like a tuple value from inside the `Enum` variant.
      in WebEvent::KeyPress(c)
        "pressed #{c}"
      in WebEvent::Paste(s)
        "pasted #{s}"
      # Destructure `Click` into `x` and `y` (c-like struct/hash).
      in WebEvent::Click(x:, y:)
        "clicked at x=#{x}, y=#{y}"
      end
    end
  end

  def setup
    @pressed = WebEvent::KeyPress.new('x')
    @pasted = WebEvent::Paste.new('my text')
    @click = WebEvent::Click.new(x: 20, y: 80)
    @load = WebEvent::PageLoad.new
    @unload = WebEvent::PageUnload.new
  end

  def test_new_err
    assert_raises(NoMethodError) { WebEvent.new }
  end

  def test_pattern_matching
    assert_equal('pressed x', @pressed.to_s)
    assert_equal('pasted my text', @pasted.to_s)
    assert_equal('clicked at x=20, y=80', @click.to_s)
    assert_equal('page loaded', @load.to_s)
    assert_equal('page unloaded', @unload.to_s)

    assert_equal(true, (WebEvent::PageLoad in WebEvent::PageLoad))
    assert_equal(true, (WebEvent::PageLoad.new in WebEvent::PageLoad))

    assert_equal(true, (WebEvent::KeyPress in WebEvent::KeyPress))
    assert_equal(true, (WebEvent::KeyPress.new('C') in WebEvent::KeyPress(_)))
    assert_equal(true, (WebEvent::KeyPress.new('c') in WebEvent::KeyPress('c')))
    assert_equal(true, (WebEvent::KeyPress.new('c') in WebEvent::KeyPress))

    assert_equal(true, (WebEvent::KeyPress.new('c') in WebEvent))
  end

  def test_case_equal
    assert_equal(true, WebEvent::PageLoad === WebEvent::PageLoad) # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
    assert_equal(true, WebEvent === WebEvent::PageLoad)
    assert_equal(true, WebEvent === WebEvent::PageLoad.new)
    assert_equal(true, WebEvent::PageLoad === WebEvent::PageLoad.new)

    assert_equal(true, WebEvent === WebEvent::KeyPress.new('c'))
    assert_equal(true, WebEvent::KeyPress === WebEvent::KeyPress.new('c'))

    assert_equal(false, WebEvent::PageLoad === WebEvent)
    assert_equal(false, WebEvent::KeyPress.new('c') === WebEvent)

    assert_equal(false, WebEvent::PageLoad === WebEvent::PageUnload)
    assert_equal(false, WebEvent::PageUnload === WebEvent::PageLoad)

    assert_equal(false, WebEvent::PageLoad === WebEvent::PageUnload.new)
    assert_equal(false, WebEvent::PageUnload === WebEvent::PageLoad.new)
  end

  def test_kind_of
    assert_equal(true, WebEvent::PageLoad.is_a?(WebEvent))
    assert_equal(true, WebEvent::PageLoad.is_a?(WebEvent::PageLoad))

    assert_equal(true, WebEvent::PageLoad.new.is_a?(WebEvent))
    assert_equal(true, WebEvent::PageLoad.new.is_a?(WebEvent::PageLoad))

    assert_equal(false, WebEvent.is_a?(WebEvent::PageLoad))

    assert_equal(false, WebEvent::PageLoad.is_a?(WebEvent::PageUnload))
    assert_equal(false, WebEvent::PageUnload.is_a?(WebEvent::PageLoad))

    assert_equal(false, WebEvent::PageLoad.new.is_a?(WebEvent::PageUnload))
    assert_equal(false, WebEvent::PageUnload.new.is_a?(WebEvent::PageLoad))
  end
end
