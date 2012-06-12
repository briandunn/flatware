require 'thor'
module Flatware
  class CLI < Thor
    desc "dispatch", "fire up the dispatcher to distribute tests"
    def dispatch
      Dispatcher.dispatch!
    end

    desc "work", "request and perform work from a dispatcher"
    def work
     Worker.listen!
    end
  end
end
