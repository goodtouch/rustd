require 'minitest/autorun'
require 'rustd'

class MutDataTest < Minitest::Test
  def test_define
    klass = Rustd::MutData.define(:foo, :bar)
    assert_kind_of(Class, klass)
    assert_equal(%i[foo bar], klass.members)
    klass = Rustd::MutData.define('foo', 'bar')
    assert_equal(%i[foo bar], klass.members)

    assert_raises(NoMethodError) { Rustd::MutData.new(:foo) }
    assert_raises(TypeError) { Rustd::MutData.define(0) }

    # Because some code is shared with Struct, check we don't share unnecessary
    # functionality
    assert_raises(TypeError) { Rustd::MutData.define(:foo, keyword_init: true) }

    refute_respond_to(
      Rustd::MutData.define, :define, 'Cannot define from defined Data class'
    )
  end

  def test_define_edge_cases
    # non-ascii
    klass = Rustd::MutData.define(:résumé)
    o = klass.new(1)
    assert_equal(1, o.send(:résumé))

    # junk string
    # We diverge from the MRI Data class here:
    assert_raises(NameError) { Rustd::MutData.define(:"a\x00") }
    # MRI allows this:
    # klass = Rustd::MutData.define(:"a\x00")
    # o = klass.new(1)
    # assert_equal(1, o.send(:"a\x00"))

    # special characters in attribute names
    assert_raises(NameError) { Rustd::MutData.define(:a, :b?) }
    # MRI allows this:
    # klass = Rustd::MutData.define(:a, :b?)
    # x = Object.new
    # o = klass.new('test', x)
    # assert_same(x, o.b?)

    assert_raises(NameError) { Rustd::MutData.define(:a, :b!) }
    # MRI allows this:
    # klass = Rustd::MutData.define(:a, :b!)
    # x = Object.new
    # o = klass.new('test', x)
    # assert_same(x, o.b!)

    assert_raises(ArgumentError) { Rustd::MutData.define(:x=) }

    assert_raises(ArgumentError, /duplicate member/) {
      Rustd::MutData.define(:x, :x)
    }
  end
end
