class Ai::ModuleRequest
  attr_accessor :result, :client, :messages, :model, :max_tokens, :custom_id, :temperature, :tools, :errors
  attr_accessor :function_call, :external_call
  DEFAULT_MODEL = "gpt-4o-mini"
  DEFAULT_MAX_TOKEN = 4096
  DEFAULT_TEMPERATURE = 0.7

  def initializeRequests(model: DEFAULT_MODEL, max_tokens: DEFAULT_MAX_TOKEN, temperature: DEFAULT_TEMPERATURE)
    puts "call: ModuleRequest::#{__method__}"
    @max_tokens = max_tokens
    @custom_id = SecureRandom.uuid
    @model = model
    @temperature = temperature
    @client = nil
    
    cleanup()
  end

  def cleanup
    puts "call: ModuleRequest::#{__method__}"
    @client ||= OpenAI::Client.new
    @result = nil
    @errors = nil
    @messages = []
  end

  def append role: nil, content: nil, messages: nil
    @messages << {role: role, content: content} if role.present? or content.present?
    @messages += messages if messages.present?
  end

  def params
    parameters = {
        model: @model,
        messages: @messages,
        temperature: @temperature,
        max_tokens: @max_tokens
      }
    parameters[:functions] = @tools if @tools.present?
    parameters
  end

  def not_found_is_ok &block
    begin
      yield
    rescue Faraday::ResourceNotFound => e
      nil
    end
  end

  def parseChoices(response)
    @result = response.dig("choices", 0, "message", "content")
    @function_call = response.dig("choices", 0, "message", "function_call")
    if @function_call.present?
      args = JSON.parse(@function_call["arguments"], { symbolize_names: true } )
      @external_call = {
        class: @function_call["name"].split("__").first.gsub("_", "/").camelize,
        name: @function_call["name"].split("__").last.camelize(:lower),
        args: args
      }
    else
      @external_call = nil
      @errors = nil
    end
    # Assistant.send(function_name, **args)
  end
end