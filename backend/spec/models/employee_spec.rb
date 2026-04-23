# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Employee, type: :model do
  subject(:employee) { build(:employee) }

  # ---------- validations ----------
  describe 'validations' do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to validate_presence_of(:job_title) }
    it { is_expected.to validate_presence_of(:department) }
    it { is_expected.to validate_presence_of(:country) }
    it { is_expected.to validate_presence_of(:salary) }
    it { is_expected.to validate_presence_of(:hire_date) }

    it { is_expected.to validate_inclusion_of(:job_title).in_array(Employee::JOB_TITLES) }
    it { is_expected.to validate_inclusion_of(:employment_type).in_array(Employee::EMPLOYMENT_TYPES) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Employee::STATUSES) }

    it 'is invalid with a non-positive salary' do
      employee.salary = 0
      expect(employee).not_to be_valid
      expect(employee.errors[:salary]).to be_present
    end

    it 'is invalid with a malformed email' do
      employee.email = 'not-an-email'
      expect(employee).not_to be_valid
    end

    it 'is invalid with a job title not in the configured list' do
      employee.job_title = 'Unlisted Title'
      expect(employee).not_to be_valid
      expect(employee.errors[:job_title]).to be_present
    end

    it 'is valid with all required attributes' do
      expect(employee).to be_valid
    end
  end

  # ---------- instance methods ----------
  describe '#full_name' do
    it 'concatenates first and last name' do
      employee.first_name = 'Alice'
      employee.last_name  = 'Smith'
      expect(employee.full_name).to eq('Alice Smith')
    end
  end

  # ---------- constants ----------
  describe 'EMPLOYMENT_TYPES' do
    it 'includes full-time, part-time and contractor' do
      expect(Employee::EMPLOYMENT_TYPES).to contain_exactly('full-time', 'part-time', 'contractor')
    end
  end

  describe 'STATUSES' do
    it 'includes active and inactive' do
      expect(Employee::STATUSES).to contain_exactly('active', 'inactive')
    end
  end

  describe 'country custom field validation' do
    before do
      create(:country_custom_field,
             country: 'India',
             field_key: 'pan_number',
             label: 'PAN Number',
             field_type: 'text',
             required: true)
    end

    it 'accepts valid custom fields for the selected country' do
      employee.country = 'India'
      employee.custom_fields = { pan_number: 'ABCDE1234F' }

      expect(employee).to be_valid
    end

    it 'rejects unknown custom field keys' do
      employee.country = 'India'
      employee.custom_fields = { visa_status: 'H1B' }

      expect(employee).not_to be_valid
      expect(employee.errors[:custom_fields]).to include("contains unknown field 'visa_status' for India")
    end

    it 'rejects missing required custom field values' do
      employee.country = 'India'
      employee.custom_fields = {}

      expect(employee).not_to be_valid
      expect(employee.errors[:custom_fields]).to include('PAN Number is required')
    end
  end
end
