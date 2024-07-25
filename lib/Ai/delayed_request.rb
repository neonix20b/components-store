class Ai::DelayedRequest < Ai::StateBatch
  include Ai::ModuleRequest

  def initialize(batch_id: nil, model: DEFAULT_MODEL, max_tokens: DEFAULT_MAX_TOKEN, temperature: DEFAULT_TEMPERATURE)
    initialize(model: model, max_tokens: max_tokens, temperature: temperature)
    @custom_id = batch_id.present? ? nil : SecureRandom.uuid
    super(batch_id: batch_id)
  end
  def postBatch
    response = @client.batches.create(
                          parameters: {
                              input_file_id: @file_id,
                              endpoint: "/v1/chat/completions",
                              completion_window: "24h"
                            }
                          )
    @batch_id = response["id"]
  end

  def cancelBatch

  end

  def cleanStorage
    if @batch_id.present?
      batch = @client.batches.retrieve(id: @batch_id)
      if !batch["output_file_id"].nil?
        @client.files.delete(id: batch["output_file_id"])
      elsif !batch["error_file_id"].nil?
        puts @client.files.content(id: batch["error_file_id"])
        @client.files.delete(id: batch["error_file_id"])
      end
      @client.files.delete(id: batch["input_file_id"])
      @client.files.delete(id: @file_id) if @file_id.present? && @file_id != batch["input_file_id"]
    elsif @file_id.present?
      @client.files.delete(id: @file_id)
    end
  end

  def finish
    cleanStorage()
    @custom_id = SecureRandom.uuid
    end_batch!
  end

  def uploadToStorage
    item = {
      "custom_id": @custom_id, 
      "method": "POST", 
      "url": "/v1/chat/completions", 
      "body": params
    }

    file = Tempfile.new(["batch_#{@custom_id}", ".jsonl"])
    file.write item.to_json
    file.close
    begin
      response = @client.files.upload(parameters: { file: file.path, purpose: "batch"} )
      @file_id = response["id"]
      process_batch!
    rescue OpenAI::Error => e
      puts e.inspect
      fail_batch!
    end
    file.unlink
  end

  def request!
    prepare_batch! if @messages.any?
  end

  def completed?
    return false if @batch_id.nil?
    batch = @client.batches.retrieve(id: @batch_id)
    return false if batch["status"] != "completed"

    if !batch["output_file_id"].nil?
			output = @client.files.content(id: batch["output_file_id"])
			output.each do |line|
				@custom_id = line["custom_id"]
				@result = line.dig("response", "body", "choices", 0, "message", "content")
        complite_batch!
			end
		elsif !batch["error_file_id"].nil?
			@result = @client.files.content(id: batch["error_file_id"])
      fail_batch!
		end
    return true
  end
end

# r = Ai::DelayedRequest.new
# r.append(role: "user", content: "привет, как тебя зовут?")
# r.request!
# r.completed?
# r.result
# r.finish