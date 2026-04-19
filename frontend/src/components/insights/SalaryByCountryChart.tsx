'use client';

import { useQuery } from '@tanstack/react-query';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from 'recharts';
import { insightsApi } from '@/lib/api';

const fmt = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });

export default function SalaryByCountryChart() {
  const { data = [], isLoading } = useQuery({
    queryKey: ['salary-stats'],
    queryFn: () => insightsApi.salaryStats(),
  });

  // Show top 12 countries by avg salary
  const chartData = data.slice(0, 12).map((r) => ({
    country: r.country,
    'Min Salary':  r.min_salary,
    'Avg Salary':  r.avg_salary,
    'Max Salary':  r.max_salary,
    headcount:     r.employee_count,
  }));

  return (
    <div className="card">
      <h3 className="text-sm font-semibold text-gray-700 mb-4">Salary by Country (Top 12 by Avg)</h3>
      {isLoading ? (
        <div className="h-56 flex items-center justify-center text-gray-400 text-sm">Loading…</div>
      ) : (
        <ResponsiveContainer width="100%" height={280}>
          <BarChart data={chartData} margin={{ top: 4, right: 8, left: 0, bottom: 40 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis
              dataKey="country"
              tick={{ fontSize: 11 }}
              angle={-35}
              textAnchor="end"
              interval={0}
            />
            <YAxis tickFormatter={(v) => `$${(v / 1000).toFixed(0)}k`} tick={{ fontSize: 11 }} />
            <Tooltip
              formatter={(val: number) => fmt.format(val)}
              contentStyle={{ fontSize: 12 }}
            />
            <Legend wrapperStyle={{ fontSize: 12, paddingTop: 8 }} />
            <Bar dataKey="Min Salary"  fill="#93c5fd" radius={[3, 3, 0, 0]} />
            <Bar dataKey="Avg Salary"  fill="#3b82f6" radius={[3, 3, 0, 0]} />
            <Bar dataKey="Max Salary"  fill="#1d4ed8" radius={[3, 3, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}
