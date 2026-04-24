class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_logs do |t|
      t.string :auditable_type, null: false
      t.integer :auditable_id, null: false
      t.string :action, null: false, comment: 'create, update, delete'
      t.text :changes, comment: 'JSON-serialized before/after values'
      t.string :user_ip
      t.string :user_agent
      t.string :user_identifier, comment: 'email or ID of user who made the change'

      t.timestamps
    end

    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end
