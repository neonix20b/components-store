desc "Print reminder about eating more fruit."

task yandex: :environment do
  YandexMarketFeed.generate
end