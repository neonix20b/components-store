class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    text = message['text']
    unless text.blank?
      @bot_name ||= Telegram.bot.get_me["result"]["username"]
      order_number = text[/\b(\w\d{8,})\b/,1]
      if order_number.present?
        config = get_config
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
    order = Spree::Order.find_by_number(get_config.payload["order"])
    respond_with :message, text: "<pre><code class='language-json'>#{JSON.pretty_generate(JSON.parse(order.to_json))}</code></pre>", parse_mode: :HTML
  end

  def reset!(word = nil, *other_words)
    config = get_config
    config.payload["order"] = nil
    config.save!
    respond_with :message, text: "Давайте начнем с чистого листа"
  end

  private
  def get_config
    Spree::Store.default.configs.find_by(name: "telegram")
  end
end