class Spree::MessagesController < Spree::StoreController
  #load_and_authorize_resource class: Spree::Address
  skip_before_action :verify_authenticity_token, only: :router
  
  def email
    if current_spree_user.admin?
      mail = ActionMailer::Base.mail(
        from: params[:from],
        to: params[:email],
        subject: params[:subject],
        body: params[:body],
        domain: params[:from].split("@").last
      )
      (1..5).each do |i|
        f = "file_#{i}".to_sym
        if params[f].present?
          uploaded_io = params[f]
          mail.attachments[uploaded_io.original_filename] = uploaded_io.read
        end
      end

      order = Spree::Order.find(params[:order_id])
      order.emails.create!(from: params[:from], to: params[:email], subject: params[:subject], body: params[:body], read: true, direction: :out)

      mail.deliver_now
      redirect_back(fallback_location: root_path, notice: "Сообщение отправлено #{mail.message_id}")
    end
  end

  def router
    if params[:key] == ENV["MAILGUN_KEY"]
      from = params[:sender]
      subject = params[:subject]
      body = params["body-plain"]

      Telegram.bot.send_message(chat_id: ENV["AIBOT_CHAT"], text: from)
      Telegram.bot.send_message(chat_id: ENV["AIBOT_CHAT"], text: subject)
      Telegram.bot.send_message(chat_id: ENV["AIBOT_CHAT"], text: body)

      order = Spree::Order.find_by_number(subject[/\b(\w\d{8,})\b/,1])
      order = Spree::Order.find_by_number(body[/\b(\w\d{8,})\b/,1]) if order.nil?
      unless order.nil?
        config = Spree::Store.default.configs.find_by(name: "telegram")
        config.payload["order"] = order.number
		    config.save!
        order.emails.create!(from: from, to: params[:recipient], subject: subject, body: body, direction: :in)
      end
    end
    render plain: 'ok'
  end

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
