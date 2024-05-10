class GoogleMerchantFeed
  #prepend Spree::ServiceModule::Base

  def self.generate()
    puts "Generate Merchant Feed"
    I18n.locale = :ru
    store = Spree::Store.default
    xml = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.rss('xmlns:g' => 'http://base.google.com/ns/1.0', version: '2.0') do
        xml.channel do
          xml.title store.name
          xml.link "https://#{store.url}"
          xml.description store.meta_description
          products = Spree::Product.all.available.not_discontinued.distinct.order(:id).includes(
                    :taxons, 
                    :translations,
                    master: [:prices, 
                        { images: { attachment_attachment: :blob } }]
                        )
            products.each do |product|
              next if product.master_images.blank?
                xml.item do
                  xml['g'].send("id", product.id)
                  xml['g'].send("title", product.name)
                  xml['g'].send("description", product.meta_description)
                  xml['g'].send("link", Spree::Core::Engine.routes.url_helpers.product_url(product, host: store.url, protocol: "https"))
                  xml['g'].send("image_link", "https://s3.eu-central-1.amazonaws.com/s3-components.oxteam.me/#{product.master_images.first.attachment_attachment.blob.key}")
                  xml['g'].send("availability", "in_stock")
                  xml['g'].send("availability_date", product.available_on.strftime('%FT%H:%MZ'))
                  xml['g'].send("price", "#{product.master.price.to_i} RUB")
                  xml['g'].send("brand", product.taxons.map{|t| t.meta_title}.join(", "))
                  xml['g'].send("condition", "new")
                  xml['g'].send("adult", "no")
                  xml['g'].send("is_bundle", "no")
                  xml['g'].send("age_group", "adult")
                end
            end
        end
      end
    end
    #puts xml.to_xml
    Zlib::GzipWriter.open('public/merchant_feed.xml.gz') do |gz|
      gz.write xml.to_xml
    end
  end
end
