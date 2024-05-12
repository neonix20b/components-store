class CreateConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :configs do |t|
      t.references :configurable, polymorphic: true, null: false
      t.string :name
      t.jsonb :payload, null: false

      t.timestamps
    end
  end
end
