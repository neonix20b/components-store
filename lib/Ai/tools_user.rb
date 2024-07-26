class Ai::ToolsUser < Ai::StateTools
  attr_accessor :worker, :role, :messages, :context, :result, :tools

  def initialize(worker:)
    puts "call: #{__method__}"
    @worker = worker
    @messages = []
    @role = nil
    @context = nil
    @result = nil
    super()
  end

  def init
    puts "call: #{__method__} state: #{state_name}"
    @worker.append(role: :system, content: @role) if @role.present?
    @worker.append(messages: @context) if !@context.nil? and @context.any?
    @worker.append(messages: @messages)
    request!
  end

  def iterate
    puts "call: #{__method__} state: #{state_name}"
    @worker.append(role: :assistant, content: @worker.result)
    request!
  end

  def externalRequest
    puts "call: #{__method__} state: #{state_name}"
    @worker.request!
    ticker()
  end

  def ticker
    puts "call: #{__method__} state: #{state_name}"
    while !@worker.completed? do 
      sleep(10) 
    end
    analyze!
  end

  def processResult
    puts "call: #{__method__} state: #{state_name}"
    if @worker.result.present? || @worker.errors.present?
      @result = @worker.result || @worker.errors
      @worker.finish()
      complete!
    end
    # iterate!
  end
  
  def setTask task
    @messages << {role: :user, content: task}
  end

  def appendContext text, role: :system
    @context << {role: role, content: text}
  end

  def execute
    puts "call: #{__method__} state: #{state_name}"
    prepare! if valid?
  end

  def cancel
    puts "call: #{__method__} state: #{state_name}"
    @worker.cancel if @worker.respond_to?(:cancel)
  end

  def valid?
    @messages.any?
  end

end

# r = Ai::ToolsUser.new(worker: Ai::Request.new)
# r.setTask("сколько будет 2+2?")
# r.execute
# r.result


# @worker.append(role: "user", content: "сколько будет 2+2?")
# @worker.request!
# @worker.completed?
# @worker.result
# @worker.finish