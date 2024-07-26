class Ai::Request < Ai::ModuleRequest
  alias_method :initialize, :initializeRequests 

  def finish
    @custom_id = SecureRandom.uuid
    cleanup()
  end

  def request!
    begin
      response = @client.chat(parameters: params)
      parseChoices(response)
      #@result = response.dig("choices", 0, "message", "content")
      #puts response.inspect
    rescue OpenAI::Error => e
      puts e.inspect
    end
  end

  def completed?
    @result.present? or @errors.present? or @external_call.present?
  end
end

# r = Ai::Request.new
# r.append(role: "user", content: "привет, как тебя зовут?")
# r.request!
# r.completed?
# r.result
# r.finish