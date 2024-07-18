module Spree
  module EmailsDecorator
    def self.prepended(base)
      base.has_many :emails, foreign_key: :spree_order_id
    end
  end
end

::Spree::Order.prepend(Spree::EmailsDecorator)
