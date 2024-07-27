class Ai::StateTools
  include Ai::StateHelper

  state_machine :state, initial: :idle do
    before_transition from: any, do: :log_me
    
    after_transition on: :iterate, do: :nextIteration
    after_transition on: :request, do: :externalRequest
    after_transition on: :prepare, do: :init
    after_transition on: :analyze, do: :processResult
    after_transition on: :complete, do: :completeIteration

    event :prepare do
      transition :idle => :prepared
    end

    event :request do
      transition :prepared => :requested
    end

    event :analyze do
      transition :requested => :analyzed
    end

    event :complete do
      transition :analyzed => :finished
    end

    event :iterate do
      transition :analyzed => :prepared
    end

    event :end do
      transition :finished => :idle
    end
    
    state :idle
    state :prepared
    state :requested
    state :analyzed
    state :finished
  end

end