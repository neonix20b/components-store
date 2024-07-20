desc "Set telegram webhooks"
task webhooks: [:environment] do
    routes = Rails.application.routes.url_helpers
    url = routes.telegram_webhook_url(host: "https://#{Spree::Store.default.url}")
    Telegram.bot.set_webhook(url: url, drop_pending_updates: true)
    
end