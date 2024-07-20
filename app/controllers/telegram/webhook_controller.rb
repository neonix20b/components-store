class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    reply_with :message, text: message['text']
  end

  def start!(word = nil, *other_words)
    respond_with :message, text: "Привет!"
  end
end