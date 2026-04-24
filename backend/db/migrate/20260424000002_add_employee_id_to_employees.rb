# frozen_string_literal: true

class AddEmployeeIdToEmployees < ActiveRecord::Migration[7.1]
  def up
    add_column :employees, :employee_id, :string, limit: 20

    # Backfill existing rows: EMP + zero-padded database id (6 digits minimum)
    execute <<~SQL
      UPDATE employees SET employee_id = 'EMP' || printf('%06d', id) WHERE employee_id IS NULL
    SQL

    change_column_null :employees, :employee_id, false
    add_index :employees, :employee_id, unique: true
  end

  def down
    remove_index :employees, :employee_id
    remove_column :employees, :employee_id
  end
end
