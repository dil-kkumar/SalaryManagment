class CreateCountryCustomFields < ActiveRecord::Migration[7.1]
  def change
    create_table :country_custom_fields do |t|
      t.string :country, null: false
      t.string :field_key, null: false
      t.string :label, null: false
      t.string :field_type, null: false
      t.string :placeholder
      t.boolean :required, null: false, default: false

      t.timestamps
    end

    add_index :country_custom_fields, [:country, :field_key], unique: true
    add_index :country_custom_fields, :country
  end
end