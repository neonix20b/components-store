module ApplicationHelper
	def og_meta_data_tags_better
      og_meta_data.map do |property, content|
        tag('meta', property: property, content: strip_tags(content)) unless property.nil? || content.nil?
      end.join("\n")
    end
end
