desc "Print reminder about eating more fruit."

namespace :feeds do
  task yandex: :environment do
    YandexMarketFeed.generate
  end

  task google: :environment do
    GoogleMerchantFeed.generate
  end
end