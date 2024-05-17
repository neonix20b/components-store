module Spree
  module MessagesDecorator
    def self.prepended(base)
      base.has_many :messages, foreign_key: :spree_user_id
    end
  end
end

::Spree::User.prepend(Spree::MessagesDecorator)
