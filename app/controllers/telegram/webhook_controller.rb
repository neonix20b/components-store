class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    text = message['text']
    @bot_name ||= Telegram.bot.get_me["result"]["username"]
    if text.include?(@bot_name)
      text = text.delete_prefix("@").delete_prefix(@bot_name).strip
      reply_with :message, text: text
    end
  end

  def start!(word = nil, *other_words)
    respond_with :message, text: "Привет!"
  end
end