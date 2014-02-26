micro\_state\_machine
===================

[![Build Status](https://travis-ci.org/ssoroka/micro_state_machine.png?branch=master)](https://travis-ci.org/ssoroka/micro_state_machine)

A small state machine! You don't need all that other crap. What's not included here is as important as what's included.

Features Included:

- default state
- customizable state field
- before and after transition events
- "state?" current state query methods dynamically defined
- "state!" transition method to switch states
- exceptions thrown on invalid state transitions
- super-simple syntax

Features NOT included:

- Transition Guards. (small pull-requests may be accepted).
- Multiple state machines per object.

Usage Example
-------------

Rails Example:

    include MicroStateMachine

    # first state declared is automatically the default state for new objects
    state :new
    state :running, from: %w(new paused deferred)
    state :paused, from: %w(running)
    state :deferred, from: %w(new running paused deferred)
    state :completed, from: %w(new running paused deferred)
    state :closed, from: %w(new running paused deferred)


Ruby Object Example:

    include MicroStateMachine

    # first state declared is automatically the default state for new objects
    state :new
    state :running, from: %w(new paused deferred)
    state :paused, from: %w(running)
    state :deferred, from: %w(new running paused deferred)
    state :completed, from: %w(new running paused deferred)
    state :closed, from: %w(new running paused deferred)

    def initialize
      set_initial_state
    end

Event Transitions:

    after_state_change do |from_state, to_state|
      state_histories.create!(from_state: from_state, to_state: to_state, user: current_user)
      pause_users_other_tasks if to_state.to_s == 'running'
    end

    on_enter_state :running do
      self.started_at = Time.now.utc
    end

    on_exit_state :running do
      running_time = (Time.now.utc - started_at).round
      time_logs.create!(task: self, user: current_user, seconds: running_time)
    end

To change the name of the state column:

    def state_column
      'something_other_than_state'
    end


Contributing to micro\_state\_machine
-----------------------------------

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
---------

Copyright (c) 2014 Steven Soroka. See LICENSE.txt for
further details.

