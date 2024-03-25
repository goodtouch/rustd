# frozen_string_literal: true

# rubocop:disable Layout/LineLength
require_relative 'lib/rustd/version'

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'rustd'
  s.version = Rustd::VERSION
  s.summary = 'Rust-inspired features for Ruby'
  s.description = 'Ruby implementation of Rust-inspired APIs for concepts such as enum, traits, Result, Option, and beyond.'

  s.required_ruby_version = '>= 3.2.0'

  s.license = 'MIT'

  s.author = 'Jean-Paul Bonnetouche'
  s.email = 'goodtouch@gmail.com'
  s.homepage = 'https://github.com/goodtouch/rustd'

  s.metadata = {
    'changelog_uri' => 'https://github.com/goodtouch/rustd/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://www.rubydoc.info/gems/rustd',
    'homepage_uri' => s.homepage,
    # 'source_code_uri' => 'TODO: https://github.com/goodtouch/rustd',
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  s.bindir = 'exe'
  s.executables = s.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  s.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # s.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end

# rubocop:enable Layout/LineLength
