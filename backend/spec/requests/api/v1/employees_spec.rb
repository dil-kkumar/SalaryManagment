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

      it 'falls back to a safe default order for invalid sort input' do
        create(:employee, last_name: 'Aardvark', email: 'aardvark@example.com')

        get base_url, params: { sort: 'salary DESC; DROP TABLE employees; --', direction: 'desc' }

        expect(response).to have_http_status(:ok)
        expect(json['items'].first['last_name']).to eq('Aardvark')
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
          hire_date: '2023-03-15', status: 'active', custom_fields: {}
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

    it 'persists country-specific custom fields' do
      create(:country_custom_field,
             country: 'India',
             field_key: 'pan_number',
             label: 'PAN Number',
             field_type: 'text',
             required: true)

      params = valid_params.deep_dup
      params[:employee][:country] = 'India'
      params[:employee][:email] = 'india.employee@example.com'
      params[:employee][:custom_fields] = { pan_number: 'ABCDE1234F' }

      post base_url, params: params

      expect(response).to have_http_status(:created)
      expect(json['custom_fields']).to eq({ 'pan_number' => 'ABCDE1234F' })
    end

    it 'sanitizes employee string inputs before persisting' do
      create(:country_custom_field,
             country: 'USA',
             field_key: 'work_mode',
             label: 'Work Mode',
             field_type: 'text')

      params = valid_params.deep_dup
      params[:employee].merge!(
        first_name: '  <b>Jane</b>  ',
        last_name: "\n Doe ",
        email: '  Jane.Doe@Example.com ',
        job_title: ' <i>Software Engineer</i> ',
        department: ' <script>Engineering</script> ',
        country: ' USA ',
        custom_fields: { work_mode: ' <strong>Remote</strong> ' }
      )

      post base_url, params: params

      expect(response).to have_http_status(:created)
      expect(json['first_name']).to eq('Jane')
      expect(json['last_name']).to eq('Doe')
      expect(json['email']).to eq('jane.doe@example.com')
      expect(json['job_title']).to eq('Software Engineer')
      expect(json['department']).to eq('Engineering')
      expect(json['country']).to eq('USA')
      expect(json['custom_fields']).to eq({ 'work_mode' => 'Remote' })
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

    it 'updates employee custom fields' do
      create(:country_custom_field,
             country: 'USA',
             field_key: 'ssn_last4',
             label: 'SSN Last 4',
             field_type: 'number')

      put "#{base_url}/#{employee.id}", params: { employee: { custom_fields: { ssn_last4: '1234' } } }

      expect(response).to have_http_status(:ok)
      expect(json['custom_fields']).to eq({ 'ssn_last4' => '1234' })
      expect(employee.reload.custom_fields).to eq({ 'ssn_last4' => '1234' })
    end
  end

  # ---------- Mass-Assignment Protection ----------
  describe 'Mass-assignment protection' do
    let(:valid_params) do
      {
        employee: {
          first_name: 'John', last_name: 'Doe', email: 'john.doe@example.com',
          job_title: 'Software Engineer', department: 'Engineering', country: 'USA',
          salary: 95_000, employment_type: 'full-time',
          hire_date: '2023-03-15', status: 'active', custom_fields: {}
        }
      }
    end

    context 'POST /api/v1/employees' do
      it 'ignores id parameter and generates a new id' do
        params = valid_params.deep_dup
        params[:employee][:id] = 9999

        post base_url, params: params

        expect(response).to have_http_status(:created)
        expect(json['id']).not_to eq(9999)
        expect(Employee.last.id).not_to eq(9999)
      end

      it 'ignores created_at and updated_at parameters' do
        future_time = 2.years.from_now.iso8601

        params = valid_params.deep_dup
        params[:employee][:created_at] = future_time
        params[:employee][:updated_at] = future_time

        post base_url, params: params

        expect(response).to have_http_status(:created)
        created_employee = Employee.last
        expect(created_employee.created_at.year).to eq(Time.zone.now.year)
        expect(created_employee.updated_at.year).to eq(Time.zone.now.year)
      end

      it 'rejects unknown attributes gracefully' do
        params = valid_params.deep_dup
        params[:employee][:internal_notes] = 'Secret info'
        params[:employee][:admin_flag] = true

        post base_url, params: params

        expect(response).to have_http_status(:created)
        created_employee = Employee.last
        expect(created_employee.respond_to?(:internal_notes)).to be false
        expect(created_employee.respond_to?(:admin_flag)).to be false
      end
    end

    context 'PUT /api/v1/employees/:id' do
      let(:employee) { create(:employee) }
      let(:original_id) { employee.id }
      let(:original_created_at) { employee.created_at }

      it 'ignores id parameter in update' do
        put "#{base_url}/#{employee.id}", params: { employee: { id: 9999, salary: 100_000 } }

        expect(response).to have_http_status(:ok)
        expect(employee.reload.id).to eq(original_id)
      end

      it 'ignores created_at parameter in update' do
        past_time = 5.years.ago.iso8601

        put "#{base_url}/#{employee.id}", params: { employee: { created_at: past_time, salary: 100_000 } }

        expect(response).to have_http_status(:ok)
        expect(employee.reload.created_at).to eq(original_created_at)
      end

      it 'rejects unknown attributes during update' do
        put "#{base_url}/#{employee.id}", params: { employee: { internal_notes: 'Updated secret', salary: 100_000 } }

        expect(response).to have_http_status(:ok)
        expect(employee.reload.respond_to?(:internal_notes)).to be false
      end
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
