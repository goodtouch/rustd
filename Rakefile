# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'minitest/test_task'
require 'rubocop/rake_task'
require 'yard'

RuboCop::RakeTask.new

# see https://docs.seattlerb.org/minitest/#label-Rake+Tasks
Minitest::TestTask.create

# see https://github.com/lsegal/yard?tab=readme-ov-file#usage
YARD::Rake::YardocTask.new

task default: :rubocop
