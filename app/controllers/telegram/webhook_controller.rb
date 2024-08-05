class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    text = message['text']
    return if text.blank?

    @bot_name ||= Telegram.bot.get_me['result']['username']
    order_number = text[/\b(\w\d{8,})\b/, 1]
    if order_number.present?
      config = get_config
      config.payload['order'] = order_number
      config.save!
    end
    return unless text.include?(@bot_name) || text.start_with?('@')

    text = text.delete_prefix('@').delete_prefix(@bot_name).strip
    reply_with :message, text:
  end

  def start!(_word = nil, *_other_words)
    respond_with :message, text: 'Привет!'
  end

  def order!(_word = nil, *_other_words)
    order = Spree::Order.find_by(number: get_config.payload['order'])
    if order.nil?
      respond_with :message, text: 'Нет активного заказа'
    else
      respond_with :message,
                   text: "<pre><code class='language-json'>#{JSON.pretty_generate(JSON.parse(order.to_json))}</code></pre>", parse_mode: :HTML
    end
  end

  def reset!(_word = nil, *_other_words)
    config = get_config
    config.payload['order'] = nil
    config.save!
    respond_with :message, text: 'Давайте начнем с чистого листа'
  end

  private

  def get_config
    Spree::Store.default.configs.find_by(name: 'telegram')
  end
end
