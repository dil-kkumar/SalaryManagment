# frozen_string_literal: true

class InputSanitizer
  class << self
    def text(value, max_length: nil, downcase: false)
      return if value.nil?

      sanitized = ActionController::Base.helpers.strip_tags(value.to_s)
      sanitized = sanitized.gsub(/[[:space:]]+/, ' ').strip
      sanitized = sanitized.first(max_length) if max_length
      sanitized = sanitized.downcase if downcase
      sanitized.presence
    end

    def custom_field_value(value)
      case value
      when String
        text(value, max_length: 255)
      else
        value
      end
    end
  end
end