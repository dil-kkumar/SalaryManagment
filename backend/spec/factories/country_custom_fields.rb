FactoryBot.define do
  factory :country_custom_field do
    country { 'India' }
    sequence(:field_key) { |n| "field_#{n}" }
    sequence(:label) { |n| "Field #{n}" }
    field_type { 'text' }
    placeholder { 'Enter a value' }
    required { false }
  end
end