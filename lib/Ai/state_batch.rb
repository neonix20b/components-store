class Ai::StateBatch
  attr_accessor :file_id, :batch_id

  state_machine :batch_state, initial: ->(t){t.batch_id.present? ? :requested : :idle}, namespace: :batch do
    before_transition from: any, do: :log_me

    after_transition on: :end, do: :cleanup
    before_transition on: :process, do: :postBatch
    after_transition on: :cancel, do: [:cancelBatch, :cleanStorage]
    after_transition on: :prepare, do: :uploadToStorage

    event :end do
      transition [:finished, :canceled] => :idle
    end

    event :prepare do
      transition :idle => :prepared
    end

    event :process do
      transition :prepared => :requested
    end

    event :complete do
      transition :requested => :finished
    end

    event :cancel do
      transition [:requested, :failed, :prepared] => :canceled
    end

    event :fail do
      transition [:requested, :prepared] => :failed
    end

    state :requested do
      def ticker
        puts "TICKER"
      end
    end
    state :idle
    state :prepared
    state :canceled
    state :finished
    state :failed
  end

  def log_me(transition)
    puts "`#{transition.event}` was called to transition from #{transition.from} to #{transition.to}"
  end

  def cleanup
    @file_id = nil
    @batch_id = nil
  end

  def initialize(batch_id: nil)
    cleanup()
    @batch_id = batch_id
    super()
  end
end