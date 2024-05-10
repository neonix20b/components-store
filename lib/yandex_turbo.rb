class YandexTurbo
  #prepend Spree::ServiceModule::Base

  def self.generate(page: 0, items_per_page: 1000)
    puts "Yandex Turbo"
    I18n.locale = :ru
    store = Spree::Store.default
    xml = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.rss('xmlns:yandex' => 'http://news.yandex.ru', 
              'xmlns:media' => "http://search.yahoo.com/mrss/", 
              'xmlns:turbo' => "http://turbo.yandex.ru",
              version: '2.0') do
        xml.channel do
          xml.title store.name
          xml.link "https://#{store.url}"
          xml.description store.meta_description
          xml.language "ru"
          products = Spree::Product.all.available.not_discontinued.distinct.order(:id).includes(
                    :taxons, 
                    :translations,
                    master: [:prices, 
                        { images: { attachment_attachment: :blob } }]
                        ).limit(items_per_page).offset(page*items_per_page)
            products.each do |product|
              next if product.master_images.blank?
                xml.item(turbo: "true") do
                  xml['turbo'].send("extendedHtml", true)
                  xml.link Spree::Core::Engine.routes.url_helpers.product_url(product, host: store.url, protocol: "https")
                  xml['turbo'].send("source", Spree::Core::Engine.routes.url_helpers.product_url(product, host: store.url, protocol: "https"))
                  xml['turbo'].send("topic", product.name)
                  xml.pubDate product.created_at.rfc2822
                  xml.author "Умные компоненты 2.0"
                  xml['turbo'].send("content") do
                    xml.cdata "<header>
                                  <h1>#{product.name} от #{product.taxons.map{|t| t.meta_title}.join(", ")}</h1>
                                  <figure>
                                      <img src='https://s3.eu-central-1.amazonaws.com/s3-components.oxteam.me/#{product.master_images.first.attachment_attachment.blob.key}'/>
                                  </figure>
                                  <h2>#{product.meta_description}</h2>
                                  <menu>
                                      <a href='https://#{store.url}'>Главная</a>
                                  </menu>
                              </header>\n"+product.description
                  end
                end
            end
        end
      end
    end
    #puts xml.to_xml
    user_id = request("/user")["user_id"]
    host_id = "https:smart-components.pro:443"
    upload_address = request("/user/#{user_id}/hosts/#{host_id}/turbo/uploadAddress?mode=PRODUCTION")["upload_address"].delete_prefix("https://api.webmaster.yandex.net/v4")
    task_id = request(upload_address, data: xml.to_xml)["task_id"]
    #request("/user/#{user_id}/hosts/#{host_id}/turbo/tasks/#{task_id}")
    puts task_id
    task_id
  end

  def self.request url, data: nil
    token = ENV["YANDEX_TURBO"]
    resp = nil
    if data.nil?
      resp = HTTParty.get("https://api.webmaster.yandex.net/v4#{url}", headers: {"Authorization" => "OAuth #{token}"})
    else
      resp = HTTParty.post("https://api.webmaster.yandex.net/v4#{url}", headers: {"Authorization" => "OAuth #{token}", "Content-Type" => "application/rss+xml"}, body: data)
    end
    puts resp
    resp
  end
end
