class EmailNullOrder < ActiveRecord::Migration[7.1]
  def change
    change_column_null :emails, :spree_order_id, true
  end
end
