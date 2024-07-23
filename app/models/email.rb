class Email < Spree::Base
  include Spree::SingleStoreResource
  if defined?(Spree::Webhooks::HasWebhooks)
    include Spree::Webhooks::HasWebhooks
  end
  default_scope { order(created_at: :desc) }
  self.whitelisted_ransackable_attributes = %w[subject body from to direction read]

  belongs_to :order, class_name: 'Spree::Order', foreign_key: :spree_order_id, optional: true
  belongs_to :store, class_name: 'Spree::Store', foreign_key: :store_id
  has_many_attached :files, dependent: :purge
  enum :direction, { out: 0, in: 10 }

  def body_responce
    lines = self.body.split("\n")
    lines.each do |l| 
      l.strip!
      if l.start_with?(">")
        l.prepend(">")
      else
        l.prepend("> ")
      end
    end
    lines.join("\n")
  end
end
