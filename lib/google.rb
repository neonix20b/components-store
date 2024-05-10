class Google
	def self.askSearch data:, period: nil
		xml = xmlStock query: data, engine: "google", period: period, region: 9047022
		result = xmlToResult xml: xml, fields: %w[title passages]
	end

	private

	def self.xmlStock query:, groupby: 10, region: 9047022, period: nil, engine: "google", category: nil
		url = "https://xmlstock.com/#{engine}/xml/?user=#{ENV["XMLSTOCK_USER"]}&key=#{ENV["XMLSTOCK_KEY"]}&query=#{CGI.escape(query)}"
		url += "&groupby=#{groupby}" if groupby.present?
		url += "&tbs=qdr:#{period}" if period.present?
		url += "&lr=#{region}" if region.present?
		url += "&tbm=#{category}" if category.present?
		Nokogiri::XML URI.open(url)
	end

	def self.xmlToResult xml:, root: "doc", fields: [], strict: true
		xml.css(root).map do |item|
			arr = fields.map{ |key| "[#{key}] #{item.at(key).text}" unless item.at(key).nil? }.compact
			if arr.size != fields.size and strict
				nil
			else
				arr.join("\n")
			end
		end.compact
	end
end