class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.string :content
      t.references :spree_user, null: false, foreign_key: true
      t.integer :role, default: 0

      t.timestamps
    end
  end
end
