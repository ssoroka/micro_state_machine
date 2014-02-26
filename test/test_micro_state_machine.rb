require 'helper'
require 'micro_state_machine'

class TestModel
  attr_accessor :state

  include MicroStateMachine

  def initialize
    set_initial_state
  end
end

class TestKanbanTask < TestModel
  state 'new'
  state 'wip', from: %w(new)
  state 'review', from: %w(new wip)
  state 'accepted', from: %w(review)
  state 'archived', from: %w(accepted)
end

describe MicroStateMachine do
  it "state defaults to first state" do
    TestKanbanTask.new.state.must_equal 'new'
  end

  it 'allows overriding the state column in the class definition' do
    override_test_class = Class.new(TestKanbanTask) do
      def state_column
        :foo_state
      end
      def foo_state
        'review'
      end
    end
    assert !override_test_class.new.new?
    assert override_test_class.new.review?
  end

  it 'allows overriding the state column on the instance' do
    task = TestKanbanTask.new
    # alter the meta class to include "fish" column
    task.define_singleton_method :fish_state do
      'wip'
    end

    # define a method on the instance
    task.define_singleton_method :state_column do
      'fish_state'
    end

    task.get_state.must_equal 'wip'
    assert task.wip?
  end

  it 'fires on_enter_state and on_exit_state hooks on changing state' do
    enter_hit = false
    exit_hit = false
    hook_class = Class.new(TestKanbanTask) do
      on_enter_state :wip do
        enter_hit = true
      end
      on_exit_state :wip do
        exit_hit = true
      end
    end

    assert !enter_hit
    assert !exit_hit

    obj = hook_class.new
    obj.get_state.must_equal 'new'

    obj.wip!
    assert enter_hit
    assert !exit_hit

    obj.review!
    assert exit_hit
  end

  it 'fires after_state_change hooks after changing state' do
    from_state = nil
    to_state = nil

    hook_class = Class.new(TestKanbanTask) do
      after_state_change do |_from_state, _to_state|
        from_state = _from_state
        to_state = _to_state
      end
    end

    obj = hook_class.new
    obj.get_state.must_equal 'new'

    obj.wip!
    from_state.must_equal 'new'
    to_state.must_equal 'wip'

    obj.review!
    from_state.must_equal 'wip'
    to_state.must_equal 'review'

    assert_raises MicroStateMachine::InvalidState do
      obj.wip!
    end

    # make sure it's unchanged:
    from_state.must_equal 'wip'
    to_state.must_equal 'review'
  end

  it 'throws an InvalidState error when transitioning to an invalid state' do
    assert_raises MicroStateMachine::InvalidState do
      TestKanbanTask.new.accepted!
    end
  end

  it 'can transition through all states' do
    task = TestKanbanTask.new
    task.wip!
    assert task.wip?

    task.review!
    assert task.review?

    task.accepted!
    assert task.accepted?

    task.archived!
    assert task.archived?
    assert task.is?(:archived)
    assert task.is?('archived')
  end
end