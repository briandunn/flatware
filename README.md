# Flatware [![Build Status][travis-badge]][travis] [![Code Climate][code-climate-badge]][code-climate]

[travis-badge]: https://travis-ci.org/briandunn/flatware.png
[travis]: http://travis-ci.org/briandunn/flatware
[code-climate-badge]: https://codeclimate.com/github/briandunn/flatware.png
[code-climate]: https://codeclimate.com/github/briandunn/flatware

Flatware is a distributed cucumber runner.

## Requirements

* ZeroMQ > 2.1

## Installation

Add this to your Gemfile:

```
gem 'flatware'
```

and `bundle install`.

## Usage

To run your entire suite with the default cucumber options, just:

```
$ flatware
```

If you'd like to limit the number of forked workers, you can pass the 'w' flag:

```
$ flatware -w 3
```

You can also pass most cucumber options to Flatware. For example, to run only
features that are not tagged 'javascript', you can:

```
$ flatware cucumber -t ~@javascript
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

## Planned Features

* Reliable enough to use as part of your Continuous Integration system
* Always accounts for every feature you ask it to run
* Use heuristics to run your slowest tests first
* speak Cucumber's DRB protocol; if you know how to use Spork you know how to
  use Flatware

## Design Goals

### Maintainable

* Fully test at an integration level. Don't be afraid to change the code. If you
  break it you'll know.
* Couple as loosely as possible, and only to the most stable/public bits of
  Cucumber.

### Minimal

* Projects define their own preperation scripts
* Only distribute to local cores (for now)
* Only handle cucumber

### Robust

* Depend on a dedicated messaging library
* Be acountable for completed work; provide progress report regardless of
  completing the suite.

## Tinkering

Flatware is tested with [aruba][]. In order to get a demo cucumber project you
can add the `@no-clobber` tag to `features/flatware.feature` and run the test
with `cucumber features/flatware.feature`. Now you should have a `./tmp/aruba`
directory. CD there and `flatware` will be in your path so you can tinker away.

[aruba]: https://github.com/cucumber/aruba

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

## Copyright

Copyright (c) 2011-2012 Brian Dunn. See LICENSE.txt for further details.
