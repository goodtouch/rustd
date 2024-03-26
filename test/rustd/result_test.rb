require 'minitest/autorun'
require 'rustd'

class ResultTest < Minitest::Test
  include Rustd

  Error = Data.define(:kind, :message)

  class ErrorKind < Enum
    NotFound = variant
    PermissionDenied = variant
  end

  def test_is_ok
    x = Ok(-2)
    assert_equal(true, x.is_ok)

    x = Err('Some error message')
    assert_equal(false, x.is_ok)
  end

  def test_is_ok_and
    x = Ok(2)
    assert_equal(true, x.is_ok_and { |x| x > 1 })

    x = Ok(0)
    assert_equal(false, x.is_ok_and { |x| x > 1 })

    x = Ok(-3)
    assert_equal(false, x.is_ok_and { |x| x > 1 })
  end

  def test_is_err
    x = Ok(-2)
    assert_equal(true, x.is_ok)

    x = Err('Some error message')
    assert_equal(false, x.is_ok)
  end

  def test_is_err_and
    x = Err(Error.new(ErrorKind::NotFound, 'Not found'))
    assert_equal(true, x.is_err_and { |x| x.kind == ErrorKind::NotFound })

    x = Err(Error.new(ErrorKind::PermissionDenied, 'Permission denied'))
    assert_equal(false, x.is_err_and { |x| x.kind == ErrorKind::NotFound })

    x = Ok(123)
    assert_equal(false, x.is_err_and { |x| x.kind == ErrorKind::NotFound })
  end

  # TODO: Implement Option first
  # def test_ok
  #   x = Ok(2)
  #   assert_equal(Some(2), x.ok)

  #   x = Err('Nothing here')
  #   assert_equal(None, x.ok)
  # end

  # TODO: Implement Option first
  # def test_err
  #   x = Ok(2)
  #   assert_equal(None, x.err)

  #   x = Err('Nothing here')
  #   assert_equal(Some('Nothing here'), x.err)
  # end

  def test_map
    x = Ok(1)
    assert_equal(Ok(2), x.map { |x| x + 1 })

    x = Err('Nothing here')
    assert_equal(Err('Nothing here'), x.map { |x| x + 1 })
  end

  def test_map_or
    x = Ok('foo')
    assert_equal(3, x.map_or(42, -> (v) { v.size }))

    x = Err('bar')
    assert_equal(42, x.map_or(42, &:size))
  end

  def test_map_or_else
    k = 21

    x = Ok('foo')
    assert_equal(3, x.map_or_else(-> (e) { k * 2 }, -> (v) { v.size }))

    x = Err('bar')
    assert_equal(42, x.map_or_else(-> (e) { k * 2 }, &:size))
  end
end
