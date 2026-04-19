FactoryBot.define do
  factory :employee do
    sequence(:first_name) { |n| "First#{n}" }
    sequence(:last_name)  { |n| "Last#{n}" }
    sequence(:email)      { |n| "user#{n}@example.com" }
    job_title             { 'Software Engineer' }
    department            { 'Engineering' }
    country               { 'USA' }
    salary                { 80_000 }
    employment_type       { 'full-time' }
    hire_date             { Date.new(2020, 6, 1) }
    status                { 'active' }

    trait :inactive do
      status { 'inactive' }
    end

    trait :contractor do
      employment_type { 'contractor' }
    end

    trait :high_earner do
      salary { 200_000 }
    end

    trait :uk do
      country { 'UK' }
    end

    trait :product_manager do
      job_title  { 'Product Manager' }
      department { 'Product' }
    end
  end
end
