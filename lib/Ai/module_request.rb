module Ai::ModuleRequest
  attr_accessor :result, :client, :messages, :model, :max_tokens, :custom_id, :temperature, :tools
  DEFAULT_MODEL = "gpt-4o-mini"
  DEFAULT_MAX_TOKEN = 4096
  DEFAULT_TEMPERATURE = 0.7

  def initialize(model: DEFAULT_MODEL, max_tokens: DEFAULT_MAX_TOKEN, temperature: DEFAULT_TEMPERATURE)
    @max_tokens = max_tokens
    @custom_id = SecureRandom.uuid
    @model = model
    @temperature = temperature
    @messages = []
    cleanup()
  end

  def cleanup
    @client ||= OpenAI::Client.new
    @result = nil
    @messages = []
  end

  def append role:, content:
    @messages << {role: role, content: content}
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
end