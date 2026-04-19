class CreateEmployees < ActiveRecord::Migration[7.1]
  def change
    create_table :employees do |t|
      t.string  :first_name,      null: false
      t.string  :last_name,       null: false
      t.string  :email,           null: false
      t.string  :job_title,       null: false
      t.string  :department,      null: false
      t.string  :country,         null: false
      t.decimal :salary,          null: false, precision: 12, scale: 2
      t.string  :employment_type, null: false, default: 'full-time'
      t.date    :hire_date,       null: false
      t.string  :status,          null: false, default: 'active'

      t.timestamps
    end

    add_index :employees, :email,                   unique: true
    add_index :employees, :country
    add_index :employees, :department
    add_index :employees, :job_title
    add_index :employees, %i[country job_title],    name: 'ix_employees_country_job_title'
    add_index :employees, :status
  end
end
