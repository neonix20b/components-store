module ApplicationHelper
	def og_meta_data_tags_better
      og_meta_data.map do |property, content|
      	result = content
      	result = strip_tags(content) if content.is_a? String
        tag('meta', property: property, content: result) unless property.nil? || content.nil?
      end.join("\n")
    end
end
