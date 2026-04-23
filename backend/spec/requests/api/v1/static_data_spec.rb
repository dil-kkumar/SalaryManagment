# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::StaticData', type: :request do
  describe 'GET /api/v1/static_data' do
    let(:json) { JSON.parse(response.body) }

    before do
      create(:employee, country: 'India', department: 'Engineering')
      create(:employee, country: 'USA', department: 'Finance')
      create(:employee, country: 'India', department: 'Finance')
      create(:country_custom_field,
             country: 'India',
             field_key: 'pan_number',
             label: 'PAN Number',
             field_type: 'text',
             placeholder: 'ABCDE1234F',
             required: true)
    end

    it 'returns countries, job_titles, departments, and country custom fields' do
      get '/api/v1/static_data'

      expect(response).to have_http_status(:ok)
      expect(json.keys).to contain_exactly('countries', 'job_titles', 'departments', 'country_custom_fields')
      expect(json['countries']).to eq(%w[India USA])
      expect(json['departments']).to eq(%w[Engineering Finance])
      expect(json['job_titles']).to eq(Employee::JOB_TITLES)
      expect(json['country_custom_fields']).to eq(
        'India' => [
          {
            'id' => CountryCustomField.last.id,
            'country' => 'India',
            'field_key' => 'pan_number',
            'label' => 'PAN Number',
            'field_type' => 'text',
            'placeholder' => 'ABCDE1234F',
            'required' => true
          }
        ]
      )
    end
  end
end
