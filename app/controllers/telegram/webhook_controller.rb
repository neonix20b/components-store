class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    reply_with :message, text: message['text']
  end
end