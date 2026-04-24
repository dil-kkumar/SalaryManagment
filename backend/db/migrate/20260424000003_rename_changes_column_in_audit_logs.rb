class RenameChangesColumnInAuditLogs < ActiveRecord::Migration[7.1]
  def change
    rename_column :audit_logs, :changes, :changed_data
  end
end
