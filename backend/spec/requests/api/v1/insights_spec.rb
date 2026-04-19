# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Api::V1::Insights', type: :request do
  let(:json) { JSON.parse(response.body) }

  before do
    create(:employee, country: 'USA', department: 'Engineering', job_title: 'Software Engineer',
           salary: 100_000, status: 'active')
    create(:employee, country: 'USA', department: 'Engineering', job_title: 'Software Engineer',
           salary: 120_000, status: 'active')
    create(:employee, country: 'UK',  department: 'Product', job_title: 'Product Manager',
           salary: 90_000,  status: 'active')
    create(:employee, country: 'UK',  department: 'Product', job_title: 'Product Manager',
           salary: 80_000,  status: 'inactive')
    create(:employee, country: 'USA', department: 'Finance', job_title: 'Financial Analyst',
           salary: 70_000,  status: 'active')
  end

  # ---------- summary ----------
  describe 'GET /api/v1/insights/summary' do
    it 'returns 200 with org KPIs' do
      get '/api/v1/insights/summary'
      expect(response).to have_http_status(:ok)
    end

    it 'returns correct total and active counts' do
      get '/api/v1/insights/summary'
      expect(json['total_employees']).to eq(5)
      expect(json['active_employees']).to eq(4)
    end

    it 'returns distinct country and department counts' do
      get '/api/v1/insights/summary'
      expect(json['total_countries']).to eq(2)
      expect(json['total_departments']).to eq(3)
    end

    it 'includes filter metadata arrays' do
      get '/api/v1/insights/summary'
      expect(json['countries']).to contain_exactly('USA', 'UK')
      expect(json['departments']).to contain_exactly('Engineering', 'Finance', 'Product')
    end
  end

  # ---------- salary_stats ----------
  describe 'GET /api/v1/insights/salary_stats' do
    it 'returns salary stats per country' do
      get '/api/v1/insights/salary_stats'
      expect(response).to have_http_status(:ok)
      usa = json.find { |r| r['country'] == 'USA' }
      expect(usa).to be_present
      expect(usa['min_salary'].to_f).to eq(70_000)
      expect(usa['max_salary'].to_f).to eq(120_000)
      expect(usa['employee_count']).to eq(3)
    end

    it 'filters by country when param provided' do
      get '/api/v1/insights/salary_stats', params: { country: 'UK' }
      expect(json.size).to eq(1)
      expect(json.first['country']).to eq('UK')
    end
  end

  # ---------- title_salary ----------
  describe 'GET /api/v1/insights/title_salary' do
    it 'returns avg salary per title + country' do
      get '/api/v1/insights/title_salary'
      expect(response).to have_http_status(:ok)
      row = json.find { |r| r['job_title'] == 'Software Engineer' && r['country'] == 'USA' }
      expect(row).to be_present
      expect(row['avg_salary'].to_f).to eq(110_000)
    end

    it 'filters by country' do
      get '/api/v1/insights/title_salary', params: { country: 'UK' }
      expect(json.all? { |r| r['country'] == 'UK' }).to be true
    end

    it 'filters by job_title' do
      get '/api/v1/insights/title_salary', params: { job_title: 'Product Manager' }
      expect(json.all? { |r| r['job_title'] == 'Product Manager' }).to be true
    end
  end

  # ---------- department_stats ----------
  describe 'GET /api/v1/insights/department_stats' do
    it 'returns stats per department' do
      get '/api/v1/insights/department_stats'
      expect(response).to have_http_status(:ok)
      eng = json.find { |r| r['department'] == 'Engineering' }
      expect(eng['employee_count']).to eq(2)
      expect(eng['active_count']).to eq(2)
      expect(eng['inactive_count']).to eq(0)
    end

    it 'counts inactive employees correctly' do
      get '/api/v1/insights/department_stats'
      product = json.find { |r| r['department'] == 'Product' }
      expect(product['inactive_count']).to eq(1)
    end
  end

  # ---------- top_earners ----------
  describe 'GET /api/v1/insights/top_earners' do
    it 'returns employees ordered by salary descending' do
      get '/api/v1/insights/top_earners', params: { limit: 3 }
      expect(response).to have_http_status(:ok)
      salaries = json.map { |e| e['salary'].to_f }
      expect(salaries).to eq(salaries.sort.reverse)
      expect(json.size).to eq(3)
    end

    it 'clamps limit to 100' do
      get '/api/v1/insights/top_earners', params: { limit: 9999 }
      expect(response).to have_http_status(:ok)
    end

    it 'filters by country' do
      get '/api/v1/insights/top_earners', params: { country: 'UK' }
      expect(json.all? { |e| e['country'] == 'UK' }).to be true
    end
  end

  # ---------- salary_distribution ----------
  describe 'GET /api/v1/insights/salary_distribution' do
    it 'returns bands with correct counts' do
      get '/api/v1/insights/salary_distribution'
      expect(response).to have_http_status(:ok)
      bands = json.index_by { |b| b['band_label'] }

      # 70k falls in $60k–$80k band
      expect(bands['$60k – $80k']['count']).to eq(1)
      # 80k/90k fall in $80k–$100k band
      expect(bands['$80k – $100k']['count']).to eq(2)
      # 100k/120k fall in $100k–$150k band
      expect(bands['$100k – $150k']['count']).to eq(2)
    end

    it 'returns all 7 bands' do
      get '/api/v1/insights/salary_distribution'
      expect(json.size).to eq(7)
    end
  end
end
