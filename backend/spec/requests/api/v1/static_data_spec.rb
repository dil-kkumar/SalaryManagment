# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::StaticData', type: :request do
  describe 'GET /api/v1/static_data' do
    let(:json) { JSON.parse(response.body) }

    before do
      create(:employee, country: 'India', department: 'Engineering')
      create(:employee, country: 'USA', department: 'Finance')
      create(:employee, country: 'India', department: 'Finance')
    end

    it 'returns countries, job_titles, and departments' do
      get '/api/v1/static_data'

      expect(response).to have_http_status(:ok)
      expect(json.keys).to contain_exactly('countries', 'job_titles', 'departments')
      expect(json['countries']).to eq(%w[India USA])
      expect(json['departments']).to eq(%w[Engineering Finance])
      expect(json['job_titles']).to eq(Employee::JOB_TITLES)
    end
  end
end
