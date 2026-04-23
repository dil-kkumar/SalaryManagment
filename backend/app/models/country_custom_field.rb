# frozen_string_literal: true

class CountryCustomField < ApplicationRecord
  FIELD_TYPES = %w[text number date].freeze

  before_validation :normalize_attributes

  validates :country, presence: true, length: { maximum: 100 }
  validates :field_key, presence: true, length: { maximum: 100 },
                        format: { with: /\A[a-z0-9_]+\z/, message: 'only allows lowercase letters, numbers, and underscores' },
                        uniqueness: { scope: :country }
  validates :label, presence: true, length: { maximum: 100 }
  validates :field_type, inclusion: { in: FIELD_TYPES }
  validates :placeholder, length: { maximum: 255 }, allow_blank: true

  scope :for_country, ->(country) { where(country: country.to_s.strip) }
  scope :ordered, -> { order(:country, :label) }

  private

  def normalize_attributes
    self.country = country.to_s.strip
    self.label = label.to_s.strip
    self.field_key = if field_key.present?
      field_key.to_s.strip.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/\A_+|_+\z/, '')
    else
      label.to_s.strip.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/\A_+|_+\z/, '')
    end
    self.placeholder = placeholder.to_s.strip.presence
  end
end