# frozen_string_literal: true

class YandexMarketFeed
  include Rails.application.routes.url_helpers

  def self.generate
    puts 'Generate Market Feed'
    # return nil if File.exist?("public/market_feed.yml.gz")
    I18n.locale = :ru
    store = Spree::Store.default
    xml = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.yml_catalog(date: Time.now.strftime('%FT%H:%M')) do
        xml.shop do
          xml.name "#{store.name}"
          xml.company "ООО #{store.name}"
          xml.url "https://#{store.url}"
          xml.platform 'Spree'
          xml.categories do
            Spree::Taxon.all.includes(:translations).each do |t|
              xml.category(id: t.id, parentId: t.parent_id) { xml.text t.name }
            end
          end
          xml.offers do
            Spree::Product.all.available.not_discontinued.distinct.order(:id).includes(
              :taxons,
              :translations,
              master: [:prices,
                       { images: { attachment_attachment: :blob } }]
            ).each do |product|
              next if product.master_images.blank?

              xml.offer(id: product.id) do
                xml.name product.name
                xml.vendor product.taxons.map(&:meta_title).join(', ')
                xml.vendorCode product.name
                xml.url Spree::Core::Engine.routes.url_helpers.product_url product, host: store.url,
                                                                                    protocol: 'https'
                xml.price product.master.price.to_i
                xml.currencyId 'RUR'
                xml.categoryId product.taxons.first.id
                xml.picture "https://cdn.#{store.url}/#{product.master_images.first.attachment_attachment.blob.key}"
                xml.description do
                  xml.cdata product.meta_description
                end
                xml.sales_notes 'Необходима предоплата.'
                xml.manufacturer_warranty 'true'
                # xml.available "true"
                xml.pickup 'true'
              end
            end
          end
        end
      end
    end.to_xml
    Zlib::GzipWriter.open('public/market_feed.yml.gz') do |gz|
      gz.write xml
    end
  end
end
