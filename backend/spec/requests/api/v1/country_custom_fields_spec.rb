# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::CountryCustomFields', type: :request do
  let(:base_url) { '/api/v1/country_custom_fields' }
  let(:json) { JSON.parse(response.body) }

  describe 'GET /api/v1/country_custom_fields' do
    it 'returns all configured country custom fields' do
      create(:country_custom_field, country: 'India', field_key: 'pan_number', label: 'PAN Number')
      create(:country_custom_field, country: 'USA', field_key: 'ssn_last4', label: 'SSN Last 4', field_type: 'number')

      get base_url

      expect(response).to have_http_status(:ok)
      expect(json.map { |field| field['field_key'] }).to eq(%w[pan_number ssn_last4])
    end
  end

  describe 'POST /api/v1/country_custom_fields' do
    it 'creates a country-specific field definition' do
      expect do
        post base_url, params: {
          country_custom_field: {
            country: 'India',
            label: 'PAN Number',
            field_type: 'text',
            placeholder: 'ABCDE1234F',
            required: true
          }
        }
      end.to change(CountryCustomField, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json['field_key']).to eq('pan_number')
      expect(json['country']).to eq('India')
    end
  end

  describe 'PUT /api/v1/country_custom_fields/:id' do
    let!(:field) { create(:country_custom_field, country: 'USA', field_key: 'ssn_last4', label: 'SSN Last 4', field_type: 'number') }

    it 'updates a field definition' do
      put "#{base_url}/#{field.id}", params: {
        country_custom_field: {
          placeholder: 'Last 4 digits',
          required: true
        }
      }

      expect(response).to have_http_status(:ok)
      expect(json['placeholder']).to eq('Last 4 digits')
      expect(json['required']).to be(true)
    end
  end

  describe 'DELETE /api/v1/country_custom_fields/:id' do
    let!(:field) { create(:country_custom_field) }

    it 'deletes a field definition' do
      expect { delete "#{base_url}/#{field.id}" }.to change(CountryCustomField, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end