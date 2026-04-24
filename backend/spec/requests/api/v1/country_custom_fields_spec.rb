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

    it 'sanitizes text inputs before creating a field definition' do
      post base_url, params: {
        country_custom_field: {
          country: ' <b>India</b> ',
          label: ' <script>PAN Number</script> ',
          placeholder: ' <i>ABCDE1234F</i> ',
          field_type: 'text',
          required: true
        }
      }

      expect(response).to have_http_status(:created)
      expect(json['country']).to eq('India')
      expect(json['label']).to eq('PAN Number')
      expect(json['field_key']).to eq('pan_number')
      expect(json['placeholder']).to eq('ABCDE1234F')
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

  describe 'Mass-assignment protection' do
    context 'POST /api/v1/country_custom_fields' do
      let(:valid_params) do
        {
          country_custom_field: {
            country: 'India',
            label: 'PAN Number',
            field_type: 'text',
            placeholder: 'ABCDE1234F',
            required: true
          }
        }
      end

      it 'ignores id parameter and generates a new id' do
        params = valid_params.deep_dup
        params[:country_custom_field][:id] = 9999

        post base_url, params: params

        expect(response).to have_http_status(:created)
        expect(json['id']).not_to eq(9999)
        expect(CountryCustomField.last.id).not_to eq(9999)
      end

      it 'ignores created_at and updated_at parameters' do
        future_time = 2.years.from_now.iso8601

        params = valid_params.deep_dup
        params[:country_custom_field][:created_at] = future_time
        params[:country_custom_field][:updated_at] = future_time

        post base_url, params: params

        expect(response).to have_http_status(:created)
        created_field = CountryCustomField.last
        expect(created_field.created_at.year).to eq(Time.zone.now.year)
        expect(created_field.updated_at.year).to eq(Time.zone.now.year)
      end

      it 'rejects unknown attributes gracefully' do
        params = valid_params.deep_dup
        params[:country_custom_field][:admin_only] = true
        params[:country_custom_field][:internal_notes] = 'Secret'

        post base_url, params: params

        expect(response).to have_http_status(:created)
        created_field = CountryCustomField.last
        expect(created_field.respond_to?(:admin_only)).to be false
        expect(created_field.respond_to?(:internal_notes)).to be false
      end
    end

    context 'PUT /api/v1/country_custom_fields/:id' do
      let(:field) { create(:country_custom_field) }
      let(:original_id) { field.id }
      let(:original_created_at) { field.created_at }

      it 'ignores id parameter in update' do
        put "#{base_url}/#{field.id}", params: {
          country_custom_field: { id: 9999, placeholder: 'Updated' }
        }

        expect(response).to have_http_status(:ok)
        expect(field.reload.id).to eq(original_id)
      end

      it 'ignores created_at parameter in update' do
        past_time = 5.years.ago.iso8601

        put "#{base_url}/#{field.id}", params: {
          country_custom_field: { created_at: past_time, placeholder: 'Updated' }
        }

        expect(response).to have_http_status(:ok)
        expect(field.reload.created_at).to eq(original_created_at)
      end

      it 'rejects unknown attributes during update' do
        put "#{base_url}/#{field.id}", params: {
          country_custom_field: { internal_notes: 'Secret', placeholder: 'Updated' }
        }

        expect(response).to have_http_status(:ok)
        expect(field.reload.respond_to?(:internal_notes)).to be false
      end
    end
  end
end