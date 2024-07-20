class AddStoreToEmails < ActiveRecord::Migration[7.1]
  def change
    #add_reference(:stores, :email, null: false, foreign_key: true)
    add_column :emails, :store_id, :integer, default: 1, null: false
    add_index :emails, :store_id
  end
end
