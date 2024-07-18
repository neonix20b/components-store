class Email < ApplicationRecord
  belongs_to :order, class_name: 'Spree::Order', foreign_key: :spree_order_id
  enum :direction, { out: 0, in: 10 }
end
