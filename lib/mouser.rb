class Mouser
	HEAERS = { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

	# def loadFolder path: "tmp/mouser"
	# 	# ActiveRecord::Base.logger.level = 1
	# 	#executor = Concurrent::ThreadPoolExecutor.new(max_threads: 10)
	# 	Dir["#{path}/*.csv"].map do |file|
	# 		#executor.post{ loadFile(file) }
	# 		loadFile(file)
	# 	end
	# 	#executor.shutdown
	# end
	
	# def loadFile path
	# 	I18n.locale = :ru
	# 	csv = SmarterCSV.process(path)
	# 	arr = []
	# 	csv.each do |item|
	# 		# findOrCreateProduct part_number: item[:mfr_part_number], availability: item[:availability], price: item[:pricing], product_number: item[:mouser_part_number], source: "mouser"
	# 		puts item[:mfr_part_number]
	# 		product = Spree::Product.find_by(meta_title: item[:mfr_part_number])
	# 		unless product.nil?
	# 			product.set_property("mouser", item[:mouser_part_number])
	# 			#product.product_properties.each {|prop| prop.show_property=false;prop.save!}
	# 		else
	# 			arr += [item[:mfr_part_number]]
	# 		end
	# 	end
	# 	puts arr
	# 	arr
	# end

	def self.dataFor mouserPartNumber: ""
		url = "https://api.mouser.com/api/v1/search/partnumber?apiKey=#{ENV["MOUSER_KEY"]}"
		result = HTTParty.post(url, 
					    body: { :SearchByPartRequest => {
									    	"mouserPartNumber" => mouserPartNumber,
							    			"partSearchOptions" => "Exact"
									    	}
		             			}.to_json,
		    			headers: HEAERS )
		result = result.dig("SearchResults", "Parts", 0)
		unless result.nil?
			hashFromResult(result)
		else
			nil
		end
	end

	def self.searchDataFor part_number: "", mfr: ""
		url = "https://api.mouser.com/api/v2/search/keywordandmanufacturer?apiKey=#{ENV["MOUSER_KEY"]}"
		result = HTTParty.post(url, 
					    body: { :SearchByKeywordMfrNameRequest => {
					    					"manufacturerName" => mfr,
									    	"keyword" => part_number,
							    			"records" => 1,
										    "pageNumber" => 0
									    	}
		             			}.to_json,
		    			headers: HEAERS )
		# puts result
		hashFromResult(result["SearchResults"]["Parts"].first)
	end

	def self.searchProducts keyword: "", mfr: "", page: 0, &block
		url = "https://api.mouser.com/api/v2/search/keywordandmanufacturer?apiKey=#{ENV["MOUSER_KEY"]}"
		result = HTTParty.post(url, 
					    body: { :SearchByKeywordMfrNameRequest => {
					    					"manufacturerName" => mfr,
									    	"keyword" => keyword,
							    			"records" => 50,
										    "pageNumber" => page,
										    "searchOptions" => "InStock"
									    	}
		             			}.to_json,
		    			headers: HEAERS )
		result["SearchResults"]["Parts"].each do |result|
			yield hashFromResult(h)
		end
	end

	def self.hashFromResult result
		return nil if result.nil?
		h = {
				description: "Category: #{result["Category"]} (#{result["Manufacturer"]})\nDescription: #{result["Description"]}",
				datasheet: result["DataSheetUrl"],
				image: (result["ImagePath"]||"").sub(/(images)(?!.*images)/, 'lrg'),
				mouser: result["MouserPartNumber"],
				qty: result["Availability"].to_i,
				part_number: result["ManufacturerPartNumber"]
			}
		h[:price] = result["PriceBreaks"].last["Price"].remove("$").to_f unless result["PriceBreaks"].blank?
		h
	end
end