class Email < Spree::Base
  include Spree::SingleStoreResource
  if defined?(Spree::Webhooks::HasWebhooks)
    include Spree::Webhooks::HasWebhooks
  end
  default_scope { order(created_at: :asc) }
  self.whitelisted_ransackable_attributes = %w[subject body]

  belongs_to :order, class_name: 'Spree::Order', foreign_key: :spree_order_id
  enum :direction, { out: 0, in: 10 }
end
