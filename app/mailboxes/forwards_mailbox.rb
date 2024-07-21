class ForwardsMailbox < ApplicationMailbox
  def process
    puts "processing email: #{mail.inspect}"
    # puts params.inspect
    from = mail.recipients.first
    to = mail.to.first
    subject = mail.subject
    body = mail.body.decoded

    # Telegram.bot.send_message(chat_id: ENV["AIBOT_CHAT"], text: from)
    # Telegram.bot.send_message(chat_id: ENV["AIBOT_CHAT"], text: subject)
    # Telegram.bot.send_message(chat_id: ENV["AIBOT_CHAT"], text: params["stripped-text"])

    order = Spree::Order.find_by_number(subject[/\b(\w\d{8,})\b/,1])
    order = Spree::Order.find_by_number(body[/\b(\w\d{8,})\b/,1]) if order.nil?
    unless order.nil?
      # config = Spree::Store.default.configs.find_by(name: "telegram")
      # config.payload["order"] = order.number
      # config.save!
      m = order.emails.create!(from: from, to: to, subject: subject, body: body, direction: :in)
      if mail.attachments.present?
        mail.attachments.each do |attachment|
          # io = URI.open(url, http_basic_authentication: ["api", ENV["MAILGUN_KEY"]])
          m.files.attach(io: StringIO.new(attachment.decoded), filename: attachment.filename, content_type: attachment.content_type)
        end
      end
    end
  end
end
