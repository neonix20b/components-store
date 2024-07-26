class Ai::ToolsUser < Ai::StateTools
  attr_accessor :worker, :role, :messages, :context, :result, :tools, :queue

  def initialize(worker:, role: nil, tools: [])
    puts "call: #{__method__}"
    @worker = worker
    @messages = []
    @tools = tools
    @role = role
    @context = nil
    @result = nil
    @queue = []

    # @tools = Ai::Tool.constants.map(&Ai::Tool.method(:const_get)).select { |c| c.is_a? Class }.map{|c|c.new}
    super()
  end

  def init
    puts "call: #{__method__} state: #{state_name}"
    @worker.append(role: :system, content: @role) if @role.present?
    @worker.append(messages: @context) if !@context.nil? and @context.any?
    @worker.append(messages: @messages)
    @worker.tools = @tools.map { |tool| tool.class.function_schemas.to_openai_format }.flatten if @tools.any?
    request!
  end

  def nextIteration
    puts "call: #{__method__} state: #{state_name}"
    @worker.append(messages: @queue)
    @queue = []
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
    @result = @worker.result || @worker.errors
    if @worker.external_call.present?
      out = @tools.first.send(@worker.external_call[:name], **@worker.external_call[:args])
      @queue << {role: :assistant, content: @worker.function_call.to_s}
      @queue << {role: :system, content: out.to_s}
      iterate!
    else
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
# 
# r = Ai::ToolsUser.new(worker: Ai::Request.new)
# r.role = "ты программный агент внутри моего компьютера"
# r.tools = [Ai::Tool::Eval.new]
# r.setTask("покажи мне файлы на диске, используй код на ruby")
# r.execute