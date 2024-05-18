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
                messages: @sys+[
                  {role: "assistant", content: Google.askSearch(data: @message_user.content).join("\n\n")},
                  { role: "user", content: @message_user.content} 
                ], # Required.
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
    redirect_to account_path, notice: "Задан новый вопрос"
  end

  def destroy
    spree_current_user.messages.destroy_all
    redirect_to account_path, notice: "Все сообщения были удалены."
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
