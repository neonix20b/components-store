class Digikey
	@@access_token = nil
	@@expires_in = nil
	@@semaphore = nil

	CACHE_DIR = "tmp/search/digikey"

	def dataFor part_number: ""
		resp = HTTParty.post("https://api.digikey.com/products/v4/search/keyword",
			headers: accessHeaders, 
			body: {"Keywords" => part_number, "Limit" => 1, "Offset" => 0}.to_json
			)

		rateLimit(resp) if resp["status"] == 429
		return nil if resp["status"] == 404
		return nil if resp["status"] == 500
		return nil if resp["Products"].empty?

		result = resp["Products"].first
		
		hashFromResult result
	end

	def accessHeaders 
		access_token = getAccessToken()
		{
			"Content-Type" => "application/json", 
			"Accept" => "application/json",
			"Authorization"=>"Bearer #{access_token}", 
			"X-DIGIKEY-Client-Id" => ENV["DIGIKEY_ID"], 
			"X-DIGIKEY-Locale-Language" => "en", 
			"X-DIGIKEY-Locale-Currency" => "USD"
		}
	end

	def searchProducts keyword: "", mfr_ids: [], offset: 0, &block
		return nil unless File.exist?(CACHE_DIR)
		cache = "#{CACHE_DIR}/#{keyword}_#{mfr_ids.join("-")}_#{offset}.json"
		resp = nil
		unless File.exist?(cache)
			resp = HTTParty.post("https://api.digikey.com/products/v4/search/keyword",
				headers: accessHeaders, 
				body: {
					"Keywords" => keyword, "Limit" => 50, "Offset" => offset,
					"FilterOptionsRequest": {
					    "ManufacturerFilter": mfr_ids.map{|i| {"Id"=>i.to_s} },
					    "SearchOptions": [ "InStock", "HasDatasheet" ] #"HasProductPhoto"
					},
					"SortOptions" => {
					    "Field" => "Price",
					    "SortOrder"=> "Descending"
					  }
					}.to_json
				)

			rateLimit(resp) if resp["status"] == 429
			return nil if resp["status"] == 404
			return nil if resp["status"] == 500

			FileUtils.mkpath(CACHE_DIR) unless File.exist?(CACHE_DIR)
			File.write(cache, resp.body)
		else
			puts "Get from cache"
			resp = JSON.parse File.read(cache)
		end

		return nil if resp["Products"].empty?

		resp["Products"].each do |result|
			yield hashFromResult(result) unless result.blank?
		end
	end

	def getAccessToken
		sleep(10) unless @@semaphore.nil?
		rate_test = config.payload["rate_limit"].to_i
		rateLimit({}, time: Time.at(rate_test)) if rate_test - Time.now.to_i > 0
		
		refresh_token = config.payload["refresh_token"] 
		#puts("https://api.digikey.com/v1/oauth2/authorize?response_type=code&client_id=#{ENV["DIGIKEY_ID"]}&redirect_uri=#{CGI.escape "https://127.0.0.1:8443/digikey/"}")
		# resp = HTTParty.post("https://api.digikey.com/v1/oauth2/token", body: {code: code, client_id: ENV["DIGIKEY_ID"], client_secret: ENV["DIGIKEY_SECRET"], grant_type: "authorization_code", redirect_uri: "https://127.0.0.1:8443/digikey/"})
		if @@access_token.nil? or (@@expires_in.to_i - Time.now.to_i < 0)
			@@semaphore = Time.now
			resp = HTTParty.post("https://api.digikey.com/v1/oauth2/token", 
				body: {
					client_id: ENV["DIGIKEY_ID"], 
					client_secret: ENV["DIGIKEY_SECRET"], 
					grant_type: "refresh_token", 
					refresh_token: refresh_token
				})
			puts resp
			@@expires_in = Time.now + resp["expires_in"].seconds - 60.seconds
			@@access_token = resp["access_token"]
			refresh_token = resp["refresh_token"]
			config.payload["refresh_token"] = refresh_token
			config.save!
			@@semaphore = nil
		end
		return @@access_token
	end

	private

	def hashFromResult result
		result.extend Hashie::Extensions::DeepFind
		
		parameters = []
		parameters = result["Parameters"].map{|pt| "#{pt["ParameterText"]}: #{pt["ValueText"]}"} if result.has_key?("Parameters")

		description = result["Description"].map{|k,v| "#{k}: #{v}"}
		description += ["Status: #{result["ProductStatus"]["Status"]}"]
		description += ["Category: #{result.deep_find_all("Name").uniq.filter{|r| r.size>5}.join("; ")}"]

		h = {
				description2: description.join("\n"),
				datasheet2: fixUrl(result["DatasheetUrl"]),
				parameters2: parameters.join("\n"),
				image: fixUrl(result["PhotoUrl"]),
				price: result["UnitPrice"],
				digikey: result.deep_find("DigiKeyProductNumber"),
				qty: result["QuantityAvailable"],
				part_number: result["ManufacturerProductNumber"]
			}
	end

	def fixUrl url
		return nil if url.blank?
		url = url.gsub("^","%5E").gsub(" ", "%20")
		if url.start_with?("//")
			"https:#{url}"
		else
			url
		end
	end

	def config
		@config ||= Spree::Store.default.configs.find_by(name: "digikey")
	end

	def rateLimit resp, time: nil
		t = time
		delta = 0
		if time.nil?
			t = Time.now + resp.headers["retry-after"].to_i
			delta = resp.headers["retry-after"]
			config.payload["rate_limit"] = t.to_i
			config.save!
		end
		raise "[#{delta}] Digikey: Daily Ratelimit exceeded (#{t})"
	end
end