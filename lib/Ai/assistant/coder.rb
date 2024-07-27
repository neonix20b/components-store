class Ai::Assistant::Coder
  attr_accessor :iterator
  def initialize delayed: false, model: "gpt-4o-mini"
    worker = delayed ? Ai::DelayedRequest.new : Ai::Request.new
    worker.model = model
    # @prompts = YAML.load(File.read("ru.prompts.yml"))
    @iterator = Ai::Iterator.new(worker: worker)
    @iterator.role = "ты программный агент внутри моего компьютера"
    @iterator.tools = [Ai::Tool::Eval.new]
    @iterator.setTask("покажи мне файлы на диске, используй код на ruby")
    @iterator.execute() 
  end
end