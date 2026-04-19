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
end
