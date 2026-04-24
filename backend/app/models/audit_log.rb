# frozen_string_literal: true

class AuditLog < ApplicationRecord
  self.table_name = 'audit_logs'

  ACTIONS = {
    create: 'create',
    update: 'update',
    delete: 'delete'
  }.freeze

  validates :auditable_type, :auditable_id, :action, presence: true

  scope :for_model, ->(model_type) { where(auditable_type: model_type) }
  scope :for_action, ->(action) { where(action: action) }
  scope :recent, -> { order(created_at: :desc) }

  def self.log(auditable, action, changes = {}, request_context = {})
    create!(
      auditable_type: auditable.class.name,
      auditable_id: auditable.id,
      action: action,
      changed_data: changes.to_json,
      user_ip: request_context[:ip],
      user_agent: request_context[:user_agent],
      user_identifier: request_context[:user_identifier]
    )
  end

  def changes_data
    @changes_data ||= JSON.parse(changed_data || '{}')
  end
end
