class AddCustomFieldsToEmployees < ActiveRecord::Migration[7.1]
  def change
    add_column :employees, :custom_fields, :text, null: false, default: '{}'
  end
end