# frozen_string_literal: true

class Mouser
  HEADERS = { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

  def self.dataFor(mouserPartNumber: '')
    url = "https://api.mouser.com/api/v1/search/partnumber?apiKey=#{ENV['MOUSER_KEY']}"
    result = HTTParty.post(url,
                           body: { SearchByPartRequest: {
                             'mouserPartNumber' => mouserPartNumber,
                             'partSearchOptions' => 'Exact'
                           } }.to_json,
                           headers: HEADERS)
    result = result.dig('SearchResults', 'Parts', 0)
    if result.nil?
      nil
    else
      hashFromResult(result)
    end
  end

  def self.searchDataFor(part_number: '', mfr: '')
    url = "https://api.mouser.com/api/v2/search/keywordandmanufacturer?apiKey=#{ENV['MOUSER_KEY']}"
    result = HTTParty.post(url,
                           body: { SearchByKeywordMfrNameRequest: {
                             'manufacturerName' => mfr,
                             'keyword' => part_number,
                             'records' => 1,
                             'pageNumber' => 0
                           } }.to_json,
                           headers: HEADERS)
    # puts result
    if result['SearchResults'].nil?
      nil
    else
      hashFromResult(result['SearchResults']['Parts'].first)
    end
  end

  def self.searchProducts(keyword: '', mfr: '', page: 0, &block)
    url = "https://api.mouser.com/api/v2/search/keywordandmanufacturer?apiKey=#{ENV['MOUSER_KEY']}"
    result = HTTParty.post(url,
                           body: { SearchByKeywordMfrNameRequest: {
                             'manufacturerName' => mfr,
                             'keyword' => keyword,
                             'records' => 50,
                             'pageNumber' => page,
                             'searchOptions' => 'InStock'
                           } }.to_json,
                           headers: HEADERS)
    result['SearchResults']['Parts'].each do |result|
      yield hashFromResult(h)
    end
  end

  def self.hashFromResult(result)
    return nil if result.nil?

    h = {
      description: "Category: #{result['Category']} (#{result['Manufacturer']})\nDescription: #{result['Description']}",
      datasheet: result['DataSheetUrl'],
      image: (result['ImagePath'] || '').sub(/(images)(?!.*images)/, 'lrg'),
      mouser: result['MouserPartNumber'],
      qty: result['Availability'].to_i,
      part_number: result['ManufacturerPartNumber']
    }
    h[:price] = result['PriceBreaks'].last['Price'].remove('$').to_f if result['PriceBreaks'].present?
    h
  end
end
