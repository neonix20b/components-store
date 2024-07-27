class Ai::Iterator < Ai::StateTools
  extend Ai::ToolDefinition
  attr_accessor :worker, :role, :messages, :context, :result, :tools, :queue, :monologue

  define_function :innerMonologue, description: "Используй внутренний монолог для планирования ответа и проговаривания основных тезисов" do
    property :speach, type: "string", description: "Текст", required: true
  end

  define_function :outerVoice, description: "Сообщить пользователю необходимую информацию без ожидания ответа" do
    property :text, type: "string", description: "Текст", required: true
  end

  define_function :actionRequest, description: "Задать уточняющий вопрос или попросить о действии с получением ответа от пользователя" do
    property :action, type: "string", description: "Текст", required: true
  end

  def initialize(worker:, role: nil, tools: [])
    puts "call: #{__method__}"
    @worker = worker
    @messages = []
    @tools = [self] + tools
    @role = role
    @context = nil
    @result = nil
    @queue = []
    @monologue = []

    @monologue << "Всегда выполняй следующие шаги, чтобы ответить на вопросы пользователей."
    @monologue << "Шаг 1. Сначала разработай собственное решение проблемы. Не полагайтесь на решение пользователя, так как оно может быть неверным. Заключи все свои наработки для этого шага в функцию innerMonologue."
    @monologue << "Шаг 2. Соотнеси свое решение с поставленной задачей, улучши его и начиний вызывать все необходимые функции в нужной последовательности шаг за шагом."
    @monologue << "Шаг 2.1. Во время работы взаимодействуй с пользователем с помощью функций outerVoice и actionRequest."
    @monologue << "Шаг 3. Когда решение будет готово, сообщи о нем с помощью функции actionRequest."

    # @tools = Ai::Tool.constants.map(&Ai::Tool.method(:const_get)).select { |c| c.is_a? Class }.map{|c|c.new}
    super()
  end

  def innerMonologue speach:
    puts Rainbow("monologue: #{speach}").yellow
    @queue << {role: :assistant, content: speach}
    return nil
  end

  def outerVoice text:
    puts Rainbow("voice: #{text}").green
    @queue << {role: :assistant, content: text}
    # external callback for assistant
    return nil
  end

  def actionRequest action:
    puts Rainbow("action: #{action}").red
    @result = action
    @messages << {role: :assistant, content: action}
    complete! 
    return nil
  end

  def init
    puts "call: #{__method__} state: #{state_name}"
    @worker.append(role: :system, content: @role) if @role.present?
    @worker.append(role: :system, content: @monologue.join("\n"))
    @worker.append(messages: @context) if !@context.nil? and @context.any?
    @worker.append(messages: @messages)
    @worker.tools = @tools.map { |tool| tool.class.function_schemas.to_openai_format }.flatten if @tools.any?
    request!
  end

  def nextIteration
    puts "call: #{__method__} state: #{state_name}"
    @worker.append(messages: @queue)
    @messages += @queue
    @queue = []
    request!
  end

  def externalRequest
    puts "call: #{__method__} state: #{state_name}"
    begin
      @worker.request!()
    rescue SystemStackError => e
      puts e.inspect
      puts e.backtrace.join("\n")
    end
    ticker()
  end

  def ticker
    puts "call: #{__method__} state: #{state_name}"
    while !@worker.completed? do 
      sleep(60) 
    end
    analyze!
  end

  def processResult
    puts "call: #{__method__} state: #{state_name}"
    @result = @worker.result || @worker.errors
    if @worker.external_call.present?
      @queue << {role: :assistant, content: @worker.function_call.to_s}
      tool = @tools.select{|t| t.class.name == @worker.external_call[:class] && t.respond_to?(@worker.external_call[:name]) }.first
      out = tool.send(@worker.external_call[:name], **@worker.external_call[:args])
      if can_iterate?
        @queue << {role: :system, content: out.to_s} if out.present?
        iterate!
      end
    elsif @result.present?
      complete!
    end
  end

  def completeIteration
    @worker.finish()
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

# r = Ai::Iterator.new(worker: Ai::Request.new)
# r.setTask("сколько будет 2+2?")
# r.execute
# r.result


# @worker.append(role: "user", content: "сколько будет 2+2?")
# @worker.request!
# @worker.completed?
# @worker.result
# @worker.finish
# 
# r = Ai::Iterator.new(worker: Ai::Request.new)
# r.role = "ты программный агент внутри моего компьютера"
# r.tools = [Ai::Tool::Eval.new]
# r.setTask("покажи мне файлы на диске, используй код на ruby")
# r.execute