'use client';

import { useQuery } from '@tanstack/react-query';
import { Users, Globe, Building2, TrendingUp } from 'lucide-react';
import { insightsApi } from '@/lib/api';

const fmt = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });

export default function SummaryCards() {
  const { data, isLoading } = useQuery({
    queryKey: ['insights-summary'],
    queryFn: insightsApi.summary,
  });

  const cards = [
    {
      label: 'Total Employees',
      value: data?.total_employees?.toLocaleString(),
      sub: `${data?.active_employees?.toLocaleString() ?? '–'} active`,
      icon: Users,
      color: 'text-blue-600 bg-blue-50',
    },
    {
      label: 'Countries',
      value: data?.total_countries,
      sub: 'Global presence',
      icon: Globe,
      color: 'text-green-600 bg-green-50',
    },
    {
      label: 'Departments',
      value: data?.total_departments,
      sub: 'Teams',
      icon: Building2,
      color: 'text-purple-600 bg-purple-50',
    },
    {
      label: 'Avg Salary',
      value: data?.overall_avg_salary != null ? fmt.format(data.overall_avg_salary) : '–',
      sub: data
        ? `${fmt.format(data.overall_min_salary)} – ${fmt.format(data.overall_max_salary)}`
        : '–',
      icon: TrendingUp,
      color: 'text-orange-600 bg-orange-50',
    },
  ];

  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
      {cards.map(({ label, value, sub, icon: Icon, color }) => (
        <div key={label} className="card flex items-start gap-3">
          <div className={`rounded-lg p-2 ${color}`}>
            <Icon size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 font-medium">{label}</p>
            <p className="text-xl font-bold text-gray-900 leading-tight">
              {isLoading ? '…' : (value ?? '–')}
            </p>
            <p className="text-xs text-gray-400 mt-0.5">{isLoading ? '' : sub}</p>
          </div>
        </div>
      ))}
    </div>
  );
}
