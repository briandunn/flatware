# Flatware [![Build Status][travis-badge]][travis] [![Code Climate][code-climate-badge]][code-climate]

[travis-badge]: https://travis-ci.org/briandunn/flatware.svg?branch=master
[travis]: http://travis-ci.org/briandunn/flatware
[code-climate-badge]: https://codeclimate.com/github/briandunn/flatware.png
[code-climate]: https://codeclimate.com/github/briandunn/flatware

Flatware parallelizes your test suite to significantly reduce test time.

## Requirements

* ZeroMQ > 4.0

## Installation

### ZeroMQ

#### Linux Ubuntu

```sh
sudo apt-get install -qq libzmq3-dev
```

(Never you mind the 3. This package contains ZMQ version 4.)

#### Mac OSX

Ruby FFI isn't getting along with the latest ZMQ formula. A tweaked verson is available in the Hashrocket tap.

```sh
brew tap hashrocket/formulas
brew install hashrocket/formulas/zeromq
brew install zeromq
```

### Flatware

Add the runners you need to your Gemfile:

```ruby
gem 'flatware-rspec'    # one
gem 'flatware-cucumber' # or both
```

then run

```sh
bundle install
```

## Usage

### Cucumber

To run your entire suite with the default cucumber options, add the `flatware-cucumber` gem and just:

```sh
$ flatware cucumber
```

### RSpec

To run your entire suite with the default rspec options add the `flatware-rspec` gem and just:

```sh
$ flatware rspec
```

### Options

If you'd like to limit the number of forked workers, you can pass the 'w' flag:

```sh
$ flatware -w 3
```

You can also pass most cucumber/rspec options to Flatware. For example, to run only
features that are not tagged 'javascript', you can:

```sh
$ flatware cucumber -t ~@javascript
```

Additionally, for either cucumber or rspec you can specify a directory:

```sh
$ flatware rspec spec/features
```

## Typical Usage in a Rails App

Add the following to your `config/database.yml`:

```yml
test:
  database: foo_test
```

becomes:

```yml
test:
  database: foo_test<%=ENV['TEST_ENV_NUMBER']%>
```

Run the following:

```sh
$ rake db:setup # if not already done
$ flatware fan rake db:test:prepare
```

Now you are ready to rock:

```sh
$ flatware rspec && flatware cucumber
```

## Planned Features

* Use heuristics to run your slowest tests first

## Design Goals

### Maintainable

* Fully test at an integration level. Don't be afraid to change the code. If you
  break it you'll know.
* Couple as loosely as possible, and only to the most stable/public bits of
  Cucumber and RSpec.

### Minimal

* Projects define their own preparation scripts
* Only distribute to local cores (for now)

### Robust

* Depend on a dedicated messaging library
* Be accountable for completed work; provide progress report regardless of
  completing the suite.

## Tinkering

Flatware integration tests use [aruba][a]. In order to get a demo cucumber project you
can add the `@no-clobber` tag to `features/flatware.feature` and run the test
with `cucumber features/flatware.feature`. Now you should have a `./tmp/aruba`
directory. CD there and `flatware` will be in your path so you can tinker away.

## How it works

Flatware relies on a message passing system to enable concurrency.
The main process declares a worker for each cpu in the computer. Each
worker forks from the main process and is then assigned a portion of the
test suite.  As the worker runs the test suite it sends progress
messages to the main process.  These messages are collected and when
the last worker is finished the main process provides a report on the
collected progress messages.

## Resources

To learn more about the messaging system that Flatware uses, take a look at the
[excellent ZeroMQ guide][z].

[z]: http://zguide.zeromq.org/page:all
[a]: https://github.com/cucumber/aruba

## Contributing to Flatware

Do whatever you want. I'd love to help make sure Flatware meets your needs.

## About

[![Hashrocket logo](https://hashrocket.com/hashrocket_logo.svg)](https://hashrocket.com)

Flatware is supported by the team at [Hashrocket](https://hashrocket.com), a multidisciplinary design & development consultancy. If you'd like to [work with us](https://hashrocket.com/contact-us/hire-us) or [join our team](https://hashrocket.com/contact-us/jobs), don't hesitate to get in touch.
