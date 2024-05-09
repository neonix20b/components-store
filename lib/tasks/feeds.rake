desc "Print reminder about eating more fruit."

task feeds: :environment do
  YandexMarketFeed.generate
  GoogleMerchantFeed.generate
end