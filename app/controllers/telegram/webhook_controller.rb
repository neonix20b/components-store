class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    text = message['text']
    unless text.blank?
      @bot_name ||= Telegram.bot.get_me["result"]["username"]
      order_number = text[/\b(\w\d{8,})\b/,1]
      if order_number.present?
        config.payload["order"] = order_number
		    config.save!
      end
      if text.include?(@bot_name) || text.start_with?("@")
        text = text.delete_prefix("@").delete_prefix(@bot_name).strip
        reply_with :message, text: text
      end
    end
  end

  def start!(word = nil, *other_words)
    respond_with :message, text: "Привет!"
  end

  def order!(word = nil, *other_words)
    order = Spree::Order.find_by_number(config.payload["order"])
    respond_with :message, text: order.to_yaml
  end

  private
  def config
    Spree::Store.default.configs.find_by(name: "telegram")
  end
end