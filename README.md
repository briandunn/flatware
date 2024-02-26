# Flatware [![Code Climate][code-climate-badge]][code-climate]

[code-climate-badge]: https://codeclimate.com/github/briandunn/flatware.svg
[code-climate]: https://codeclimate.com/github/briandunn/flatware

Flatware parallelizes your test suite to significantly reduce test time.

### Flatware

Add the runners you need to your Gemfile:

```ruby
gem 'flatware-rspec', require: false    # one
gem 'flatware-cucumber', require: false # or both
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

The rspec runner can balance worker loads, making your suite even faster.

It forms balaced groups of spec files according to their last run times, if you've set `example_status_persistence_file_path` [in your RSpec config](https://relishapp.com/rspec/rspec-core/v/3-8/docs/command-line/only-failures).

For this to work the configuration option must be loaded before any specs are run. The `.rspec` file is one way to achive this:

    --require spec_helper

But beware, if you're using ActiveRecord in your suite you'll need to avoid doing things that cause it to establish a database connection in `spec_helper.rb`. If ActiveRecord connects before flatware forks off workers, each will die messily. All of this will just work if you're following [the recomended pattern of splitting your helpers into `spec_helper` and `rails_helper`](https://github.com/rspec/rspec-rails/blob/v3.8.2/lib/generators/rspec/install/templates/spec/rails_helper.rb). Another option is to use [the configurable hooks](
#faster-startup-with-activerecord
).

### Options

If you'd like to limit the number of forked workers, you can pass the 'w' flag:

```sh
$ flatware -w 3
```

You can also pass most cucumber/rspec options to Flatware. For example, to run only
features that are not tagged 'javascript', you can:

```sh
$ flatware cucumber -t 'not @javascript'
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

### Faster Startup With ActiveRecord

Flatware has a couple lifecycle callbacks that you can use to avoid booting your app
over again on every core. One way to take advantage of this via a `spec/flatware_helper.rb` file like so:

```ruby
##
# uncomment if you get a segmentation fault from the "pg" gem
# @see https://github.com/ged/ruby-pg/issues/311#issuecomment-1609970533
# ENV["PGGSSENCMODE"] = "disable"

Flatware.configure do |conf|
  conf.before_fork do
    require 'rails_helper'

    ActiveRecord::Base.connection.disconnect!
  end

  conf.after_fork do |test_env_number|
    ##
    # uncomment if you're using SimpleCov and have started it in `rails_helper` as suggested here:
    # @see https://github.com/simplecov-ruby/simplecov/tree/main?tab=readme-ov-file#use-it-with-any-framework
    # SimpleCov.at_fork.call(test_env_number)

    config = ActiveRecord::Base.connection_db_config.configuration_hash

    ActiveRecord::Base.establish_connection(
      config.merge(
        database: config.fetch(:database) + test_env_number.to_s
      )
    )
  end
end
```
Now when I run `bundle exec flatware rspec -r ./spec/flatware_helper` My app only boots once, rather than once per core.

## SimpleCov

If you're using SimpleCov, follow [their directions](https://github.com/simplecov-ruby/simplecov/tree/main?tab=readme-ov-file#use-it-with-any-framework) to install. When you have it working as desired for serial runs, add
`SimpleCov.at_fork.call(test_env_number)` to flatware's `after_fork` hook. You should now get the same coverage stats from parallel and serial runs.

## Segmentation faults in the PG gem

If you get a segmentation fault on start you may need to add `ENV["PGGSSENCMODE"] = "disable"` to the top of your flatware helper.

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

Flatware relies on a message passing system to enable concurrency. The main process forks a worker for each cpu in the computer. These workers are each given a chunk of the tests to run. The workers report back to the main process about their progress. The main process prints those progress messages. When the last worker is finished the main process prints the results.

## Resources

[a]: https://github.com/cucumber/aruba

## Contributing to Flatware

Do whatever you want. I'd love to help make sure Flatware meets your needs.

## About

[![Hashrocket logo](https://hashrocket.com/hashrocket_logo.svg)](https://hashrocket.com)

Flatware is supported by the team at [Hashrocket](https://hashrocket.com), a multidisciplinary design & development consultancy. If you'd like to [work with us](https://hashrocket.com/contact-us/hire-us) or [join our team](https://hashrocket.com/contact-us/jobs), don't hesitate to get in touch.


# TODO:

possible simplecov fixes

1. seems like we won't get the same results as serial rspec runs unless we start simplecov after fork. And if we do that, I think a process needs to claim to be the last one for simplecov to run the merge.
