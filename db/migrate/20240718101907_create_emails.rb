class CreateEmails < ActiveRecord::Migration[7.1]
  def change
    create_table :emails do |t|
      t.string :body
      t.string :title
      t.references :spree_order, null: false, foreign_key: true
      t.integer :direction, default: 0
      t.string :from
      t.string :to

      t.timestamps
    end
  end
end
