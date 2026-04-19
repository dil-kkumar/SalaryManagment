import type {
  Employee,
  EmployeeFormData,
  EmployeeListResponse,
  InsightsSummary,
  CountrySalaryStats,
  TitleSalaryStats,
  DepartmentStats,
  TopEarner,
  SalaryBand,
} from '@/types';

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001';

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options?.headers },
    ...options,
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    const message =
      (body as { errors?: string[]; error?: string }).errors?.join(', ') ??
      (body as { error?: string }).error ??
      `HTTP ${res.status}`;
    throw new Error(message);
  }

  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

// ─── Employee API ─────────────────────────────────────────────────────────────

export interface ListEmployeesParams {
  page?: number;
  page_size?: number;
  search?: string;
  country?: string;
  department?: string;
  job_title?: string;
  status?: string;
  employment_type?: string;
  sort?: string;
  direction?: 'asc' | 'desc';
}

export const employeeApi = {
  list: (params: ListEmployeesParams = {}) => {
    const qs = new URLSearchParams(
      Object.fromEntries(
        Object.entries(params)
          .filter(([, v]) => v !== undefined && v !== '')
          .map(([k, v]) => [k, String(v)])
      )
    ).toString();
    return request<EmployeeListResponse>(`/api/v1/employees${qs ? `?${qs}` : ''}`);
  },

  get: (id: number) => request<Employee>(`/api/v1/employees/${id}`),

  create: (data: EmployeeFormData) =>
    request<Employee>('/api/v1/employees', {
      method: 'POST',
      body: JSON.stringify({ employee: data }),
    }),

  update: (id: number, data: Partial<EmployeeFormData>) =>
    request<Employee>(`/api/v1/employees/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ employee: data }),
    }),

  delete: (id: number) =>
    request<void>(`/api/v1/employees/${id}`, { method: 'DELETE' }),
};

// ─── Insights API ─────────────────────────────────────────────────────────────

export const insightsApi = {
  summary: () => request<InsightsSummary>('/api/v1/insights/summary'),

  salaryStats: (country?: string) =>
    request<CountrySalaryStats[]>(
      `/api/v1/insights/salary_stats${country ? `?country=${encodeURIComponent(country)}` : ''}`
    ),

  titleSalary: (params: { country?: string; job_title?: string } = {}) => {
    const qs = new URLSearchParams(
      Object.fromEntries(Object.entries(params).filter(([, v]) => v))
    ).toString();
    return request<TitleSalaryStats[]>(`/api/v1/insights/title_salary${qs ? `?${qs}` : ''}`);
  },

  departmentStats: () => request<DepartmentStats[]>('/api/v1/insights/department_stats'),

  topEarners: (limit = 10, country?: string, department?: string) => {
    const params = new URLSearchParams({ limit: String(limit) });
    if (country) params.set('country', country);
    if (department) params.set('department', department);
    return request<TopEarner[]>(`/api/v1/insights/top_earners?${params.toString()}`);
  },

  salaryDistribution: () => request<SalaryBand[]>('/api/v1/insights/salary_distribution'),
};
