'use client';

import { useQuery } from '@tanstack/react-query';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts';
import { insightsApi } from '@/lib/api';

export default function SalaryDistributionChart() {
  const { data = [], isLoading } = useQuery({
    queryKey: ['salary-distribution'],
    queryFn: insightsApi.salaryDistribution,
  });

  return (
    <div className="card">
      <h3 className="text-sm font-semibold text-gray-700 mb-4">Salary Distribution</h3>
      {isLoading ? (
        <div className="h-56 flex items-center justify-center text-gray-400 text-sm">Loading…</div>
      ) : (
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={data} margin={{ top: 4, right: 8, left: 0, bottom: 4 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis dataKey="band_label" tick={{ fontSize: 11 }} />
            <YAxis tick={{ fontSize: 11 }} />
            <Tooltip
              formatter={(val: number) => [`${val.toLocaleString()} employees`, 'Count']}
              contentStyle={{ fontSize: 12 }}
            />
            <Bar dataKey="count" fill="#6366f1" radius={[3, 3, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}
