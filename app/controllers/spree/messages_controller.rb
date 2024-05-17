class Spree::MessagesController < Spree::StoreController
  #load_and_authorize_resource class: Spree::Address

  def create
    spree_current_user.messages.destroy_all
    @sys ||= Spree::Store.default.configs.find_by(name: "ai").payload["sys_messages"]
    @message_user = spree_current_user.messages.create(message_params.merge(role: "user"))
    @message = spree_current_user.messages.create(role: "assistant", content: "")
    Thread.new { 
      ActiveRecord::Base.connection_pool.with_connection do
        @client ||= OpenAI::Client.new
        @client.chat(
            parameters: {
                model: "gpt-4o", # Required.
                messages: @sys+[{ role: "user", content: @message_user.content} ], # Required.
                temperature: 0.7,
                stream: proc do |chunk, _bytesize|
                    chunk = chunk.dig("choices", 0, "delta", "content")
                    @message.content += chunk
                    @message.save!
                end
            })
        #@message.broadcast_create 
      end
    }
    redirect_to account_path, notice: "Message was successfully created."
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
