class Message < ApplicationRecord
  #belongs_to :spree_user, class_name: 'Spree::User'
  belongs_to :customer, class_name: 'Spree::User', foreign_key: :spree_user_id
  enum :role, { system: 0, assistant: 10, user: 20 }

  #after_create_commit :broadcast_create
  #after_update_commit :broadcast_update

  def broadcast_update
    broadcast_replace_later_to(
      dom_id(self),
      partial: 'assistant/message',
      locals: { message: self, scroll_to: true }
    )
  end

  def broadcast_create
    broadcast_append_later_to(
      "#{dom_id(self.user)}_messages",
      partial: "assistant/message",
      locals: { message: self, scroll_to: true}
    )
  end
end
