class BaseRoutine
	# t = Spree::Taxon.find(34)
	MIN_PRICE = 300
	KEYWORDS = ["eval", "board", "kit", "FPGA", "PGA", "DAC", "ADC", "MCU", "PLD", "LDO", "DSP", "CMOS", "COB", "CPLD", "driver", "SoC", "Amplifier", "Logic", "PLL", "IC", "sensor", "PMIC", "Linear", "Interface", "Embedded", "Memory"]
	
	def self.loadProductsFor taxon: nil, keywords: KEYWORDS, in_threads: 1
		keywords = taxon.meta_keywords.split(",").map{|i|i.chomp} if keywords.nil?
		mfr_ids = taxon.meta_keywords.split(",").map{|i|i.chomp.to_i}.compact.uniq
		sep = mfr_ids.find_index(0)
		mfr_ids = mfr_ids[0..sep-1] unless sep.nil?

		return nil if mfr_ids.blank?
		digikey = Digikey.new
		digikey.getAccessToken()
		SpreeStarter::Application.config.i18n.default_locale = :ru
		I18n.locale = :ru

		parallelBlock(keywords, in_threads: in_threads) do |keyword|
		#keywords.each do |keyword|
			#ActiveRecord::Base.connection_pool.with_connection do
				puts "Keyword: #{keyword}"
				last_price = MIN_PRICE
				(0..10).each do |page|
					next if last_price < MIN_PRICE
					digikey.searchProducts keyword: keyword, mfr_ids: mfr_ids, offset: page*50 do |h|
						if !h[:price].blank?
							last_price = h[:price].to_i
							if  last_price > MIN_PRICE
								part_number = h[:part_number]
								puts "[#{keyword}/#{page}] #{part_number} $#{last_price}"
								product = findOrCreateProduct part_number: part_number, availability: h[:qty], price: last_price, product_number: h[:digikey], source: "digikey"
								unless product.nil?
									product.description = "#{part_number} от #{taxon.name}"
									product.save!

									taxon.products << product
									taxon.save!

									updateProduct product, h: h

									if h[:image].blank? and product.property("mouser").nil?
										h2 = Mouser.searchDataFor part_number: part_number, mfr: taxon.meta_title
										updateProduct product, h: h2
									end

									product.save!

									# makeDescriptionFor product
								end
							end
						end
					end
				end
			#end
		end
	end

	# def mmm product
	# 	return nil if !product.property("mouser").nil?
	# 	taxon = product.taxons.first
	# 	h2 = Mouser.searchDataFor part_number: product.name, mfr: taxon.meta_title
	# 	BaseRoutine.updateProduct product, h: h2
	# end

	def self.findOrCreateProduct part_number: "", availability: 0, price: 0.0, product_number: "", source: ""
		return nil if price.nil?
		if Spree::Product.find_by(meta_title: part_number).nil?
			puts "make #{part_number}"
			# price = price.gsub(/[="\.]/, "").tr(',', '.').to_f
			return nil if price < 1

			I18n.locale = :ru

			@store ||= Spree::Store.default
			product = @store.products.new(status: :draft, available_on: Time.now, shipping_category_id: 1, promotionable: false)
			product.stores << @store
			product.name = part_number
			product.slug = part_number.downcase
			product.meta_title = part_number
			product.price = price * 140
			product.save!

			variant = product.master
			variant.cost_price = price
			variant.cost_currency = "USD"
			variant.sku = "#{product.slug}-#{source}"
			variant.save!

			stock=variant.stock_items.first_or_create
			stock.count_on_hand = (availability.to_i + 1)*1000
			stock.stock_location_id = 1
			stock.save!

			product.set_property(source, product_number)

			return product
		end
	end

	def self.findOrCreateTaxon(title)
		if Spree::Taxon.where(meta_title: title).any?
		  Spree::Taxon.where(meta_title: title).first
		else
			vendors = Spree::Taxonomy.find(8)
			t=vendors.taxons.new(parent_id: vendors.root_id)
			t.meta_title = title
			t.name = title
			t.save!
			t
		end
	end

	def massUpdate ids
		# Spree::Product.where(id: ids).each do |product|
		# 	vendors = product.taxons.pluck(:meta_title)
		# 	product.description = "#{product.meta_title} от #{vendors.join(', ')}"
		# 	product.save!
		# end
		# Spree::Variant.where("sku ILIKE '%-gen2'").each do |v|
		# 	v.sku.delete_suffix!("-gen2")
		# 	v.sku += "-gen"
		# 	v.save!
		# end
		# Spree::Product.all.each do |product|
		# 	product.price = product.cost_price * k
		# 	product.save!
		# end
	end

	def self.status
		count = Spree::Variant.all.count
		arr = ["","2","4", "5"].map{|i| Spree::Variant.where("sku ILIKE '%-gen#{i}'").count}
		arr.prepend(count - arr.sum)
		arr.map{|a| a}#.map{|i| "#{i.round(2)}%"}
	end

	def self.updateProperties
		I18n.locale = :ru
		# prop = Spree::Property.find_by_presentation("mouser")
		# prop.products.order(:id).each do |product|
		# 	updateProductBlock product: product do
		# 		mouserData(mouserPartNumber: product.property("mouser"))
		# 	end
		# end
		digikey = Digikey.new
		Spree::Product.all.order(:id).each do |product|
			updateProduct product, h: digikey.dataFor(part_number: product.name) if product.property("digikey").nil?
		end
	end

	def self.clean
		#arr = Spree::Product.all.map{ |product| product.images.count > 0 ? nil : product.id }
		#arr.compact!
		ids = Spree::Product.where(status: :draft).map{|product| product.cost_price > MIN_PRICE ? nil : product.id}.compact
		products = Spree::Product.where(id: ids)
		products.each{|product| product.archive!}

		Spree::ProductProperty.where(property_id: [1,3,8,9,10], show_property: true).each do |prop|
		    prop.show_property = false
		    prop.save!
		end
	end

	def self.updateProduct product, h: {}
		# return nil if !product.property("digikey").nil?
		# part_number = product.property("mouser")
		puts "[id=#{product.id}] #{product.name}"
		#puts "[#{product.id}]: <a href=\"https://smart-components.pro/admin/products/#{product.slug}/edit\" target=\"_blank\">#{product.name}</a><br/>"
		#h = yield #mouserData(mouserPartNumber: part_number)
		tmp = "tmp/imgs"
		Dir.mkdir(tmp) unless File.exist?(tmp)
		unless h.nil?
			unless h[:image].blank?
				url = h[:image]
				puts url
				unless product.images.count > 0
					ext = url.split(".").last
					base = product.slug.remove(',', '/', '#')
					filename = "#{tmp}/#{base}.#{ext}"
					code = nil
					File.open(filename, "w") do |file|
						file.binmode
						code = HTTParty.get(url, {
									stream_body: true, 
								    headers: { 
								        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36" 
								    }, }) do |fragment|
							file.write(fragment)
						end
					end
					#file = URI.open(h[:image], 'rb')
					#product.images.create!(attachment: { io: File.open(filename), filename: "#{part_number}.#{ext}" })
					unless code.not_found?
						image = Spree::Image.create!(attachment: { io: open(filename), filename: "#{base}.#{ext}" }, alt: product.name)
						product.images << image
					end
					File.delete(filename)
				end
			end
			product.set_property("DataSheet", h[:datasheet]) unless h[:datasheet].blank?
			product.set_property("ai", h[:description]) unless h[:description].blank?
			product.set_property("DataSheet2", h[:datasheet2]) unless h[:datasheet2].blank?
			product.set_property("ai2", h[:description2]) unless h[:description2].blank?
			product.set_property("digikey", h[:digikey]) unless h[:digikey].blank?
			product.set_property("parameters2", h[:parameters2]) unless h[:parameters2].blank?
		end
	end

	def self.makeDescriptionFor product
		if product.description.size > 200
			return nil
		end
		puts "[#{product.id}] #{product.name} (ai)"

		I18n.locale = :ru
		role = "Твоя роль - эксперт по электрическим схемам, специализирующийся на создании и анализе электрических схем, предоставлении рекомендаций по схемам и использованию компонентов. Поделись лучшими практиками и советами по проектированию и анализу электрических схем, а также по их оптимизации. От тебя требуется: Знание основ электроники и электротехники, включая анализ схем и симуляцию, Умение четко и понятно формулировать технические рекомендации и обучающие материалы."
		materials = "Мы делаем интернет-магазин электронных компонентов. Пользователь будет давать тебе название компонента (Manufacturer Part Number) и название производителя, ты в ответ должен давать описание для сайта: общее описание, преимущества, недостатки, типовое использование, рекомендации по применению, основные технические характеристики, возможные аналоги и тому подобное. Для наглядности используй Markdown."
		vendors = product.taxons.pluck(:name)
		ai = [product.property("ai"),product.property("ai2")].compact.join("\n")
		sys_messages = [
			{role: "system", content: role},
			{role: "system", content: materials}
		]
		sys_messages.append({role: "assistant", content: ai}) unless ai.blank?
		parameters = []
		parameters = [{role: "assistant", content: product.property("parameters2")}] unless product.property("parameters2").nil?
		google = [
			{role: "assistant", content: Google.askSearch(data:"\"#{product.name}\" from #{vendors.join(", ")} (specification||datasheet)").join("\n\n")}
		]
		user_messages = [
			{role: "user", content: ActionView::Base.full_sanitizer.sanitize(product.description)}
		]
		Faraday.default_connection_options = {request: { open_timeout: 600, timeout: 600 }}
		OpenAI.configure do |config|
		    config.access_token = ENV.fetch("OPENAI")
		    config.request_timeout = 600
		end
		renderer = Redcarpet::Render::HTML.new(no_links: true)
		markdown = Redcarpet::Markdown.new(renderer, autolink: false, tables: true, lax_spacing: true)
		#puts "make description #{product.name}"
		llm = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI"], default_options:{chat_completion_model_name: 'gpt-4-turbo'})
		description = ""
		if File.exist?("tmp/ai/#{product.id}.md")
			description = File.read("tmp/ai/#{product.id}.md")
		else
			description = llm.chat(messages: sys_messages + parameters + google + user_messages).completion
			File.write("tmp/ai/#{product.id}.md", description)
		end
		meta_messages = [
			{role: "user", content: "Напиши текст для мета-тега description (до 160 букв)"}
		]
		#puts "make meta description #{product.name}"
		meta_description = ""
		if File.exist?("tmp/ai/#{product.id}_meta.md")
			meta_description = File.read("tmp/ai/#{product.id}_meta.md")
		else
			meta_description = llm.chat(messages: sys_messages + user_messages + meta_messages).completion
			File.write("tmp/ai/#{product.id}_meta.md", meta_description)
		end
		meta_messages = [
			{role: "assistant", content: meta_description },
			{role: "user", content: "Напиши ключевые слова на русском языке для мета-тега keywords (до 160 букв)"}
		]
		meta_keywords = ""
		if File.exist?("tmp/ai/#{product.id}_keywords.md")
			meta_keywords = File.read("tmp/ai/#{product.id}_keywords.md")
		else
			meta_keywords = llm.chat(messages: sys_messages + user_messages + meta_messages).completion
			File.write("tmp/ai/#{product.id}_keywords.md", meta_keywords)
		end
		# puts meta_keywords
		product.description = markdown.render(description)
		product.meta_description = meta_description.remove("\"")
		product.meta_keywords = meta_keywords.remove("\"")
		product.save!
		variant = product.master
		variant.sku += "-gen6" unless variant.sku.ends_with?("gen6")
		variant.save!
		product.activate!
		File.delete("tmp/ai/#{product.id}.md")
		File.delete("tmp/ai/#{product.id}_meta.md")
		File.delete("tmp/ai/#{product.id}_keywords.md")
	end

	def self.updateAllDescriptions
		I18n.locale = :ru
		prop = Spree::Property.find_by_presentation("ai2")
		parallelBlock(prop.products.where(status: :draft).order(:id).includes(
		            		:taxons, 
		            		:translations,
		            		:master)) do |product|
		    #next if product.images.count == 0
			variant = product.master
			puts "#{product.name}"
			if !variant.sku.ends_with?("gen6")# and product.images.count > 0
				# vendors = product.taxons.pluck(:name)
				# variant.sku.delete_suffix!("-gen5")
				# variant.sku.delete_suffix!("-gen4")
				# variant.sku.delete_suffix!("-gen2")
				# variant.sku.delete_suffix!("-gen")
				# variant.save!
				# product.description = "#{product.name} от #{vendors.join(", ")}"
				#puts "I am in thread! #{product.id}"
				begin
					makeDescriptionFor product
					puts "end #{product.name}"
				rescue => error
					puts "[!] ERROR: #{error.message}"
					sleep(60)
				end
			end
		end
	end

	def self.parallelBlock arr, in_threads: 10, &block
		Parallel.each(arr, in_threads: in_threads) do |item|
			ActiveRecord::Base.connection_pool.with_connection do
				yield item
			end
		end
	end
end