module ApplicationHelper
  def markdown(text)
    return "" if text.blank?
    options = [:hard_wrap, :autolink, :no_intra_emphasis, :fenced_code_blocks, :tables]
    Markdown.new(text, *options).to_html.html_safe
    #Redcarpet::Render::SmartyPants.render(text).html_safe
  end

	def og_meta_data_tags_better
      og_meta_data.map do |property, content|
      	result = content
      	result = strip_tags(content) if content.is_a? String
        tag('meta', property: property, content: result) unless property.nil? || content.nil?
      end.join("\n")
    end
end
