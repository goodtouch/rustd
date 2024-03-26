# Rustd

## What is Rustd?

This gem adds Rust-like `enums`, `traits`, `Result`, `Option`, and more to Ruby.

### Principles

* **Idiomatic** - The code should feel natural to Ruby developers.
* **Minimalistic** - The implementation should be as simple as possible.
* **Stable** - The API should be stable and predictable, so it's easy to maintain and evolve.
* **User-friendly** - The API should be easy to understand and use, even for people who are not familiar with Rust.
* **Fun** - The project should be fun to work on.

### Use cases

I started this side project to see if some Rust concepts could enrich the language with more expressive definitions and new ways to structure and organize Ruby code. You might find it useful if:

* You're curious about Rust and want to adopt some of its best practices into your Ruby app or library.
* You want to learn Rust and are looking for a way to bridge the gap between the two languages.
* You want to quickly prototype an app in Ruby and later rewrite parts of it in Rust without having to change the structure of the code too much.
* You want to get familiar with Rust without fighting with the borrow checker (yet).

### 🚧 A word of warning 🚧

> This project is still in early "R&D mode".
>
> I'm making it public so I can quickly share it and gather feedback while shaping its future.
>
> Here is what you can expect during that phase:
>
> * Work in progress global architecture & API design
> * Unimplemented or untested features
> * Minimal & incomplete bullet point documentation
> * Breaking changes
> * Force-pushes until the first stable release (😈)

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add rustd
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install rustd
```

## Design

I wondered if I could find an idiomatic and (if possible) elegant way to implement some interesting Rust features within Ruby's dynamic and flexible environment. Could this make Ruby even cooler than it already is?

So this is what this gem is about:

* [**Enums with Associated Data**](docs/design/enums.md)
* [**Traits for Shared Behavior**](docs/design/traits.md)
* [**Robust Error Handling with Result**](docs/design/result.md)
* [**The Option Type for Nullable Values**](docs/design/option.md)

## Development

After checking out the repo, run `make` to see what you can do and get started.

To release a new version:

1. update the version number in `version.rb`,
2. update `CHANGELOG.md`,
3. tag and push the git ref,
4. then run `make release`, which will push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/goodtouch/rustd. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/goodtouch/rustd/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rustd project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/goodtouch/rustd/blob/main/CODE_OF_CONDUCT.md).
