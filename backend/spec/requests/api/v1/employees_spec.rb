# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Api::V1::Employees', type: :request do
  let(:base_url) { '/api/v1/employees' }
  let(:json)     { JSON.parse(response.body) }

  # ---------- GET /api/v1/employees ----------
  describe 'GET /api/v1/employees' do
    before { create_list(:employee, 5) }

    it 'returns 200 with paginated results' do
      get base_url
      expect(response).to have_http_status(:ok)
      expect(json['items'].size).to eq(5)
      expect(json['total']).to eq(5)
      expect(json['page']).to eq(1)
    end

    it 'includes full_name in each item' do
      get base_url
      expect(json['items'].first).to include('full_name')
    end

    context 'pagination' do
      it 'respects page_size parameter' do
        get base_url, params: { page_size: 2 }
        expect(json['items'].size).to eq(2)
        expect(json['total_pages']).to eq(3)
      end

      it 'returns correct page' do
        get base_url, params: { page: 2, page_size: 3 }
        expect(json['items'].size).to eq(2)
        expect(json['page']).to eq(2)
      end
    end

    context 'filtering' do
      before do
        create(:employee, country: 'UK')
        create(:employee, department: 'Finance')
        create(:employee, :inactive)
      end

      it 'filters by country' do
        get base_url, params: { country: 'UK' }
        expect(json['items'].all? { |e| e['country'] == 'UK' }).to be true
      end

      it 'filters by department' do
        get base_url, params: { department: 'Finance' }
        expect(json['items'].all? { |e| e['department'] == 'Finance' }).to be true
      end

      it 'filters by status' do
        get base_url, params: { status: 'inactive' }
        expect(json['items'].all? { |e| e['status'] == 'inactive' }).to be true
      end
    end

    context 'search' do
      before { create(:employee, first_name: 'Zelda', last_name: 'Unique') }

      it 'finds employee by name fragment' do
        get base_url, params: { search: 'Zelda' }
        expect(json['total']).to eq(1)
        expect(json['items'].first['first_name']).to eq('Zelda')
      end
    end

    context 'sorting' do
      it 'sorts by salary descending' do
        create(:employee, salary: 120_000)
        create(:employee, salary: 50_000)
        get base_url, params: { sort: 'salary', direction: 'desc' }
        salaries = json['items'].map { |e| e['salary'].to_f }
        expect(salaries).to eq(salaries.sort.reverse)
      end
    end
  end

  # ---------- GET /api/v1/employees/:id ----------
  describe 'GET /api/v1/employees/:id' do
    let(:employee) { create(:employee) }

    it 'returns the employee' do
      get "#{base_url}/#{employee.id}"
      expect(response).to have_http_status(:ok)
      expect(json['id']).to eq(employee.id)
      expect(json['full_name']).to eq(employee.full_name)
    end

    it 'returns 404 for unknown id' do
      get "#{base_url}/99999"
      expect(response).to have_http_status(:not_found)
    end
  end

  # ---------- POST /api/v1/employees ----------
  describe 'POST /api/v1/employees' do
    let(:valid_params) do
      {
        employee: {
          first_name: 'Jane', last_name: 'Doe', email: 'jane.doe@example.com',
          job_title: 'Software Engineer', department: 'Engineering', country: 'USA',
          salary: 95_000, employment_type: 'full-time',
          hire_date: '2023-03-15', status: 'active'
        }
      }
    end

    it 'creates and returns the employee' do
      expect { post base_url, params: valid_params }.to change(Employee, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(json['email']).to eq('jane.doe@example.com')
    end

    it 'returns 422 with validation errors on invalid params' do
      post base_url, params: { employee: { first_name: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['errors']).to be_present
    end

    it 'returns 422 on duplicate email' do
      create(:employee, email: 'jane.doe@example.com')
      post base_url, params: valid_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ---------- PUT /api/v1/employees/:id ----------
  describe 'PUT /api/v1/employees/:id' do
    let(:employee) { create(:employee, salary: 70_000) }

    it 'updates the employee' do
      put "#{base_url}/#{employee.id}", params: { employee: { salary: 90_000 } }
      expect(response).to have_http_status(:ok)
      expect(json['salary'].to_f).to eq(90_000)
      expect(employee.reload.salary).to eq(90_000)
    end

    it 'returns 404 for unknown id' do
      put "#{base_url}/99999", params: { employee: { salary: 90_000 } }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 422 on invalid update' do
      put "#{base_url}/#{employee.id}", params: { employee: { salary: -1 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ---------- DELETE /api/v1/employees/:id ----------
  describe 'DELETE /api/v1/employees/:id' do
    let!(:employee) { create(:employee) }

    it 'deletes the employee and returns 204' do
      expect { delete "#{base_url}/#{employee.id}" }.to change(Employee, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for unknown id' do
      delete "#{base_url}/99999"
      expect(response).to have_http_status(:not_found)
    end
  end
end
