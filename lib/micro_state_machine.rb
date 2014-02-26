require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/class/attribute'

module MicroStateMachine
  class InvalidState < StandardError
    def initialize(old_state, new_state)
      super("Cannot transition from #{old_state} to #{new_state}")
    end
  end

  def self.included(klass)
    klass.class_attribute :_on_enter_state, :_on_exit_state, :_initial_state, :_after_state_change, :_states
    klass.send(:extend, ClassMethods)
    if klass.respond_to?(:after_initialize)
      klass.instance_eval do
        after_initialize(:set_initial_state)
      end
    end
  end

  module ClassMethods
    # override this to change the default state column name
    def state_column
      'state'
    end

    # used to define the possible states the "machine" could be in.
    # defines convenience {state}! and {state}? methods
    # worth noting that transition_from_{from_state}_to_{state} could be used to implement guards.
    def state(state, options = {})
      self._initial_state ||= state
      self._after_state_change ||= []
      self._on_enter_state ||= HashWithIndifferentAccess.new
      self._on_exit_state ||= HashWithIndifferentAccess.new
      self._states ||= {}
      _states[state] = options
      from = options[:from] || _states.keys

      from.each do |from_state|
        define_method("#{state}!") do
          transition_to(state)
        end

        define_method("#{state}?") do
          is?(state)
        end

        define_method("transition_from_#{from_state}_to_#{state}") do
          on_exit_state = self.class._on_exit_state
          on_enter_state = self.class._on_enter_state
          if on_exit_state[from_state]
            on_exit_state[from_state].each do |blk|
              instance_eval &blk
            end
          end
          send("#{state_column}=", state)
          if on_enter_state[state]
            on_enter_state[state].each do |blk|
              instance_eval &blk
            end
          end
        end
      end
    end

    def on_enter_state(state, &block)
      h = _on_enter_state
      h[state] ||= []
      h[state].push block
      self._on_enter_state = h
    end

    def on_exit_state(state, &block)
      h = _on_exit_state
      h[state] ||= []
      h[state].push block
      self._on_exit_state = h
    end

    def after_state_change(*args, &block)
      _after_state_change.push block
    end
  end

  # Instance Methods

  def state_column
    self.class.state_column
  end

  def get_state
    send(state_column)
  end

  def set_initial_state
    current_value = send(state_column)
    if current_value.nil?
      send("#{state_column}=", self.class._initial_state)
    end
  end

  def is?(state)
    get_state.to_s == state.to_s
  end

  def can_transition_to?(new_state)
    states = self.class._states
    options = HashWithIndifferentAccess.new(states)[new_state]
    options.blank? || options[:from].include?(get_state)
  end

  def transition_to(new_state)
    old_state = get_state
    transition_method_name = "transition_from_#{old_state}_to_#{new_state}"
    raise InvalidState.new(old_state, new_state) unless respond_to?(transition_method_name)
    send(transition_method_name)
    self.class._after_state_change.each do |blk|
      instance_exec(old_state, new_state, &blk)
    end
    self
  end
end