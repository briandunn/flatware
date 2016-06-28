# Flatware [![Build Status][travis-badge]][travis] [![Code Climate][code-climate-badge]][code-climate]

[travis-badge]: https://travis-ci.org/briandunn/flatware.png
[travis]: http://travis-ci.org/briandunn/flatware
[code-climate-badge]: https://codeclimate.com/github/briandunn/flatware.png
[code-climate]: https://codeclimate.com/github/briandunn/flatware

Flatware parallelizes your test suite to significantly reduce test time.

## Requirements

* ZeroMQ > 4.0

## Installation

### ZeroMQ

#### Linux Ubuntu

See this [webpage](https://tuananh.org/2015/06/16/how-to-install-zeromq-on-ubuntu/) for installation instructions.

#### Mac OSX

```
brew install zeromq
```

### Flatware

Add this to your Gemfile:

```
gem 'flatware'
```

then run

```
bundle install
```

## Usage

### Cucumber

To run your entire suite with the default cucumber options, just:

```
$ flatware cucumber
```

### RSpec

To run your entire suite with the default rspec options, just:

```
$ flatware rspec
```

### Options

If you'd like to limit the number of forked workers, you can pass the 'w' flag:

```
$ flatware -w 3
```

You can also pass most cucumber/rspec options to Flatware. For example, to run only
features that are not tagged 'javascript', you can:

```
$ flatware cucumber -t ~@javascript
```

Additionally, for either cucumber or rspec you can specify a directory:

```
$ flatware rspec spec/features
```

## Typical Usage in a Rails App

Add the following to your config/database.yml:

```
test:
  database: foo_test
```

becomes:

```
test:
  database: foo_test<%=ENV['TEST_ENV_NUMBER']%>
```

Run the following:

```
$ rake db:setup # if not already done
$ flatware fan rake db:test:prepare
```

Now you are ready to rock:

```
$ flatware
```

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

## Contributing to Flatware

* Check out the latest master to make sure the feature hasn't been implemented
  or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it
  and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to
  have your own version, or is otherwise necessary, that is fine, but please
  isolate to its own commit so I can cherry-pick around it.
