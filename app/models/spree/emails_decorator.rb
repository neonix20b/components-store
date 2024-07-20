module Spree
  module EmailsDecorator
    def self.prepended(base)
      column = "#{base.model_name.singular}_id"
      if Email.column_names.include?(column)
        base.has_many :emails, foreign_key: column
      else
        base.has_many :emails, foreign_key: column.delete_prefix("spree_")
      end
    end
  end
end

::Spree::Order.prepend(Spree::EmailsDecorator)
::Spree::Store.prepend(Spree::EmailsDecorator)