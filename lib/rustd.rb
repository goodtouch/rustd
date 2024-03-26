# frozen_string_literal: true

require_relative 'rustd/version'
require_relative 'rustd/enum'
require_relative 'rustd/impl'
require_relative 'rustd/result'

module Rustd
  extend self

  # -- Some delegated aliases
  #
  # So that we can pattern match with `case x in Ok(x)`

  # Contains the success value.
  Ok = Result::Ok
  # Contains the error value.
  Err = Result::Err

  #
  # So that we can "instanciate" with `Ok(123)`

  # Creates an instance of {Result::Ok} variant.
  def Ok(v) = Result::Ok(v)

  # Creates an instance of `Result::Err` variant.
  def Err(e) = Result::Err(e)
end
