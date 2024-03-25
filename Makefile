.DEFAULT_GOAL := help

FMT_BLUE = \033[36m
FMT_BOLD = \033[1m
FMT_END = \033[0m

deps := .stamps/deps
version_file := lib/*/version.rb
version := $(shell grep VERSION $(version_file) | sed -e 's/VERSION =//' -e 's/[ '"'"'"]//g')

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make ${FMT_BLUE}<target>${FMT_END}\n"} \
	/^[a-zA-Z0-9_-]+:.*?##/ { printf "  ${FMT_BLUE}%-46s${FMT_END} %s\n", $$1, $$2 } \
	/^##@/ { printf "\n${FMT_BOLD}%s${FMT_END}\n", substr($$0, 5) } \
	' $(MAKEFILE_LIST)

##@ Develop

.PHONY: deps
deps: .stamps/deps ## Install dependencies

.stamps/deps: .stamps/deps-gems | .stamps
	@touch .stamps/deps

.stamps/deps-gems: Gemfile.lock | .stamps
	@echo "\n📌 Setting up project..."
	./bin/setup
	@touch .stamps/deps-gems

Gemfile.lock: Gemfile
	@echo "\n📌 Installing gems..."
	bundle install

.PHONY: console
console: .stamps/deps ## Run an IRB console with the gem loaded
	./bin/console

##@ Test

.PHONY: test
test: .stamps/deps ## Run the test suite
	bundle exec rake test

##@ Check

check: check-rubocop ## Check everything

.PHONY: check-rubocop
check-rubocop: .stamps/deps ## Check code with RuboCop
	bundle exec rubocop

##@ Build

.PHONY: build
build: pkg/rustd-$(version).gem ## Build the gem

pkg/rustd-$(version).gem: $(version_file) rustd.gemspec .stamps/deps | pkg
	@echo "\n📌 Building pkg/rustd-$(version).gem..."
	gem build rustd.gemspec
	mv rustd-$(version).gem pkg/

pkg:
	mkdir -p pkg

##@ Install

.PHONY: install
install: rustd-$(version).gem ## Install the gem
	gem install ./rustd-$(version).gem

##@ Document

.PHONY: doc
doc: .stamps/deps ## Build documentation
	bundle exec yard

.PHONY: doc-serve
doc-serve: .stamps/deps ## Start a local documentation server
	bundle exec yard server --reload

##@ Release

.PHONY: release
release: pkg/rustd-$(version).gem ## Publish the gem on RubyGems
	gem push pkg/rustd-$(version).gem

##@ Utility

.PHONY: clean
clean: ## Clean everything
	@echo "\n📌 Cleaning..."
	rm -rf .stamps
	rm -rf .yardoc
	rm -f pkg/rustd-*.gem

.stamps: ## Create directory for Makefile stamps
	@mkdir -p .stamps
