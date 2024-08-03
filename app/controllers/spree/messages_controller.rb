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

      message = current_store.emails.new(from: params[:from], to: params[:email], subject: params[:subject], body: params[:body], read: true, direction: :out)
      message.order = Spree::Order.find(params[:order_id]) if params[:order_id].present?
      message.save!
      
      (1..5).each do |i|
        f = "file_#{i}".to_sym
        if params[f].present?
          uploaded_io = params[f]
          mail.attachments[uploaded_io.original_filename] = uploaded_io.read
          uploaded_io.rewind
          message.files.attach(uploaded_io)
        end
      end

      mail.deliver_now
      redirect_back(fallback_location: root_path, notice: "Сообщение отправлено #{mail.message_id}")
    end
  end

  def router
    if params[:key] == ENV["MAILGUN_KEY"] and params["body-mime"].present?
      mail = Mail.new(params["body-mime"])
      from = mail.from.first
      to = mail.recipients.first
      subject = mail.subject
      valid_part = (mail.text_part || mail.html_part || mail)
      charset = valid_part.content_type_parameters['charset']
      body = valid_part.body.decoded.force_encoding(charset).encode('UTF-8')

      begin
        Telegram.bot.send_message(chat_id: ENV["AIBOT_CHAT"], text: from)
        Telegram.bot.send_message(chat_id: ENV["AIBOT_CHAT"], text: subject)
        Telegram.bot.send_message(chat_id: ENV["AIBOT_CHAT"], text: body.truncate(200))
      end

      store = Spree::Store.find_by(url: to.split("@").last)
      store = current_store if store.nil?

      order = Spree::Order.find_by_number(subject[/\b(\w\d{8,})\b/,1])
      order = Spree::Order.find_by_number(body[/\b(\w\d{8,})\b/,1]) if order.nil?

      if order.nil?
        order = Email.where(to: from).or(Email.where(from: from)).order(created_at: :desc).first.try(:order)
      end

      message = store.emails.new(from: from, to: to, subject: subject, body: body, direction: :in)

      unless order.nil?
        config = Spree::Store.default.configs.find_by(name: "telegram")
        config.payload["order"] = order.number
		    config.save!
        message.order = order if order.store == store
      end

      message.save!
      
      if mail.attachments.present?
        mail.attachments.each do |a|
          message.files.attach(io: StringIO.new(a.decoded), filename: a.filename, content_type: a.content_type)
        end
      end
      #end
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
