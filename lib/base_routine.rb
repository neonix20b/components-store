class BaseRoutine
	# t = Spree::Taxon.find(34)
	MIN_PRICE = 300
	KEYWORDS = ["eval", "board", "kit", "FPGA", "PGA", "DAC", "ADC", "MCU", "PLD", "LDO", "DSP", "CMOS", "COB", "CPLD", "driver", "SoC", "Amplifier", "Logic", "PLL", "IC", "sensor", "PMIC", "Linear", "Interface", "Embedded", "Memory", "MOSFET", "RF"]
	
	def self.loadProductsFor taxon: nil, keywords: KEYWORDS, in_threads: 1
		keywords = taxon.meta_keywords.split(",").map{|i|i.chomp} if keywords.nil?
		mfr_ids = taxon.meta_keywords.split(",").map{|i|i.chomp.to_i}.compact.uniq
		sep = mfr_ids.find_index(0)
		mfr_ids = mfr_ids[0..sep-1] unless sep.nil?

		return nil if mfr_ids.blank?
		digikey = Digikey.new
		digikey.getAccessToken()
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
									if product.description.blank?
										product.description = "#{part_number} от #{taxon.name}"
										product.save!
									end

									if product.taxons.blank?
										taxon.products << product
										taxon.save!
									end

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

	def mmm product
		taxon = product.taxons.first
		product.description = "#{product.name} от #{taxon.name}"
		product.sku.delete_suffix!("-gen6")
		product.sku.delete_suffix!("-gen5")
		product.save!
	end

	def self.findOrCreateProduct part_number: "", availability: 0, price: 0.0, product_number: "", source: ""
		return nil if price.nil?
		product = Spree::Product.find_by(meta_title: part_number)
		if product.nil?
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
		end
		return product
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
		@config ||= Spree::Store.default.configs.find_by(name: "ai").payload
		vendors = product.taxons.pluck(:name)
		ai = [product.property("ai"),product.property("ai2")].compact.join("\n")
		sys_messages = @config["sys_messages"]
		sys_messages.append({role: "assistant", content: ai}) unless ai.blank?
		parameters = []
		google = []
		if product.property("parameters2").nil?
			google = [
				{role: "assistant", content: Google.askSearch(data:"\"#{product.name}\" #{vendors.join(", ")} (specification||datasheet)").join("\n\n")}
			]
		else
			parameters = [{role: "assistant", content: product.property("parameters2")}] 
		end
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
		llm = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI"], default_options:{chat_completion_model_name: 'gpt-4o'})
		description = ""
		if File.exist?("tmp/ai/#{product.id}.md")
			description = File.read("tmp/ai/#{product.id}.md")
		else
			description = llm.chat(messages: sys_messages + parameters + google + user_messages).completion
			File.write("tmp/ai/#{product.id}.md", description)
		end
		#puts "make meta description #{product.name}"
		#if product.meta_description.blank?
			meta_messages = [
				{role: "user", content: @config["description"]}
			]
			meta_description = ""
			if File.exist?("tmp/ai/#{product.id}_meta.md")
				meta_description = File.read("tmp/ai/#{product.id}_meta.md")
			else
				meta_description = llm.chat(messages: sys_messages + user_messages + meta_messages).completion
				File.write("tmp/ai/#{product.id}_meta.md", meta_description)
			end
			product.meta_description = meta_description.remove("\"")
		#end

		#if product.meta_keywords.blank?
			meta_messages = [
				{role: "assistant", content: meta_description },
				{role: "user", content: @config["keywords"]}
			]
			meta_keywords = ""
			if File.exist?("tmp/ai/#{product.id}_keywords.md")
				meta_keywords = File.read("tmp/ai/#{product.id}_keywords.md")
			else
				meta_keywords = llm.chat(messages: sys_messages + user_messages + meta_messages).completion
				File.write("tmp/ai/#{product.id}_keywords.md", meta_keywords)
			end
			product.meta_keywords = meta_keywords.remove("\"")
			product.meta_keywords.delete_prefix!("Купите ")
		#end
		llm = nil

		product.description = markdown.render(description)
		
		product.save!
		variant = product.master
		variant.sku += "-gen7" unless variant.sku.ends_with?("gen7")
		variant.save!
		product.activate!
		File.delete("tmp/ai/#{product.id}.md")
		File.delete("tmp/ai/#{product.id}_meta.md")
		File.delete("tmp/ai/#{product.id}_keywords.md")
	end

	def self.updateAllDescriptions
		# 13237ADC-BDM
		# 119936-HMC686LP4
		I18n.locale = :ru
		prop = Spree::Property.find_by_presentation("ai2")
		parallelBlock(prop.products.where(status: :draft).order(:id).includes(
		            		:taxons, 
		            		:translations,
		            		:master)) do |product|
		    #next if product.images.count == 0
			variant = product.master
			puts "#{product.name}"
			if !variant.sku.ends_with?("gen7")# and product.images.count > 0
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

	def self.updateDescriptionsAsync
		@client ||= OpenAI::Client.new
		ids = Spree::Variant.where("sku ILIKE '%-gen4'").pluck(:product_id)
		products = Spree::Product.where(id: ids).includes(:translations, :taxons, properties: [:translations])
		file_name = "tmp/batch_#{Time.now.to_i}.jsonl"
		File.open(file_name, "w") do |f|
		  products.each { |product| BaseRoutine.batchLinesFor(product).each{|item| f.puts(item.to_json)} }
		end
		response = @client.files.upload(parameters: { file: file_name, purpose: "batch"} )
		file_id = response["id"]
		# @client.files.list
		# @client.files.delete(id: file_id)
		response = @client.batches.create(
		  parameters: {
		    input_file_id: file_id,
		    endpoint: "/v1/chat/completions",
		    completion_window: "24h"
		  }
		)
		#response
		# batch_id = response["id"]
		# batch = client.batches.retrieve(id: batch_id)
		# output_file_id = batch["output_file_id"]
		# output_response = client.files.content(id: output_file_id)
		# error_file_id = batch["error_file_id"]
		# error_response = client.files.content(id: error_file_id)
		response["id"]
	end

	def self.batchLinesFor product
		@config ||= Spree::Store.default.configs.find_by(name: "ai").payload
		vendors = product.taxons.pluck(:name)
		ai = [product.property("ai"),product.property("ai2")].compact.join("\n")
		sys_messages = @config["sys_messages"]
		#sys_messages.append({role: "assistant", content: ai}) unless ai.blank?
		assistant_messages = []
		parameters = []
		google = []
		assistant_messages = [{role: "assistant", content: ai}] unless ai.blank?
		if product.property("parameters2").nil?
			return []
			google = [
				{role: "assistant", content: Google.askSearch(data:"\"#{product.name}\" #{vendors.join(", ")} (specification||datasheet)").join("\n\n")}
			]
		else
			parameters = [{role: "assistant", content: product.property("parameters2")}] 
		end
		product.description = "Напиши описание для #{product.meta_title} от #{vendors.join(", ")}"
		user_messages = [ {role: "user", content: ActionView::Base.full_sanitizer.sanitize(product.description)} ]
		meta_desc_messages = [ {role: "user", content: @config["description"]} ]
		meta_keywords_messages = [ {role: "user", content: @config["keywords"]} ]
		{"description": parameters + google + user_messages, 
			"meta_description": user_messages + meta_desc_messages, 
			"meta_keywords": user_messages + meta_keywords_messages}.map do |field, messages|
			{
				"custom_id": "#{product.class.to_s}-#{field}-#{product.id}", 
				"method": "POST", 
				"url": "/v1/chat/completions", 
				"body": {
					"model": "gpt-4o", 
					"messages": sys_messages + assistant_messages + messages,
					"max_tokens": 4096
				}
			}
		end
	end

	def self.batchProcess id:
		@client ||= OpenAI::Client.new
		@markdown ||= Redcarpet::Markdown.new(renderer, autolink: false, tables: true, lax_spacing: true)
		@client.batches.retrieve(id: id)
		return nil if batch["status"] != "completed"
		
		if !batch["output_file_id"].nil?
			output = @client.files.content(id: batch["output_file_id"])
			output.each do |line|
				(model, field, id) = line["custom_id"].split("-")
				item = model.constantize.find(id.to_i)
				content = line.dig("response", "body", "choices", 0, "message", "content")
				item.send("#{field}=", markdown.render(content))
				llmFixAndSave item
			end
			@client.files.delete(id: batch["output_file_id"])
		elsif !batch["error_file_id"].nil?
			puts @client.files.content(id: batch["error_file_id"])
			@client.files.delete(id: batch["error_file_id"])
		end
		@client.files.delete(id: batch["input_file_id"])

		# r = @client.batches.list
		# r["data"].each do |batch|
		# end
	end

	def self.llmFixAndSave product
		product.meta_description.remove!("\"")
		product.meta_keywords.remove!("\"")
		product.meta_keywords.delete_prefix!("Купите ")
		product.save!
		if !product.meta_description.blank? and !product.meta_keywords.blank? and !product.description.blank?
			variant = product.master
			variant.sku.delete_suffix!("-gen4")
			variant.sku.delete_suffix!("-gen5")
			variant.sku.delete_suffix!("-gen6")
			variant.sku += "-gen7" unless variant.sku.ends_with?("gen7")
			variant.save!
			product.activate!
		end
	end

	def self.parallelBlock arr, in_threads: 1, &block
		Parallel.each(arr, in_threads: in_threads) do |item|
			ActiveRecord::Base.connection_pool.with_connection do
				yield item
			end
		end
	end
end