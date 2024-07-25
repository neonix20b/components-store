class Ai::Request
  include Ai::ModuleRequest

  def finish
    @custom_id = SecureRandom.uuid
    cleanup()
  end

  def request!
    begin
      response = @client.chat(parameters: params)
      @result = response.dig("choices", 0, "message", "content")
    rescue OpenAI::Error => e
      puts e.inspect
    end
  end

  def completed?
    @result.present?
  end
end

# r = Ai::Request.new
# r.append(role: "user", content: "привет, как тебя зовут?")
# r.request!
# r.completed?
# r.result
# r.finish