// ─── Employee ────────────────────────────────────────────────────────────────
export type EmploymentType = 'full-time' | 'part-time' | 'contractor';
export type EmployeeStatus = 'active' | 'inactive';

export interface Employee {
  id: number;
  first_name: string;
  last_name: string;
  full_name: string;
  email: string;
  job_title: string;
  department: string;
  country: string;
  salary: number;
  employment_type: EmploymentType;
  hire_date: string;
  status: EmployeeStatus;
  created_at: string;
  updated_at: string;
}

export interface EmployeeListResponse {
  items: Employee[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

export interface EmployeeFormData {
  first_name: string;
  last_name: string;
  email: string;
  job_title: string;
  department: string;
  country: string;
  salary: number;
  employment_type: EmploymentType;
  hire_date: string;
  status: EmployeeStatus;
}

export interface StaticDataResponse {
  countries: string[];
  job_titles: string[];
  departments: string[];
}

// ─── Insights ────────────────────────────────────────────────────────────────
export interface InsightsSummary {
  total_employees: number;
  active_employees: number;
  total_countries: number;
  total_departments: number;
  overall_avg_salary: number;
  overall_min_salary: number;
  overall_max_salary: number;
  countries: string[];
  departments: string[];
  job_titles: string[];
}

export interface CountrySalaryStats {
  country: string;
  employee_count: number;
  min_salary: number;
  max_salary: number;
  avg_salary: number;
}

export interface TitleSalaryStats {
  job_title: string;
  country: string;
  employee_count: number;
  avg_salary: number;
  min_salary: number;
  max_salary: number;
}

export interface DepartmentStats {
  department: string;
  employee_count: number;
  avg_salary: number;
  active_count: number;
  inactive_count: number;
}

export interface DepartmentEmployeeCount {
  department: string;
  employee_count: number;
}

export interface TopEarner {
  id: number;
  full_name: string;
  job_title: string;
  department: string;
  country: string;
  salary: number;
}

export interface SalaryBand {
  band_label: string;
  lower_bound: number;
  upper_bound: number | null;
  count: number;
}

// ─── Generic API error ───────────────────────────────────────────────────────
export interface ApiError {
  error?: string;
  errors?: string[];
}
