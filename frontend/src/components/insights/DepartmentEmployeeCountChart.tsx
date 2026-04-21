'use client';

import { useQuery } from '@tanstack/react-query';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts';
import { insightsApi } from '@/lib/api';

export default function DepartmentEmployeeCountChart() {
  const { data = [], isLoading } = useQuery({
    queryKey: ['department-employee-counts'],
    queryFn: insightsApi.departmentEmployeeCounts,
  });

  const chartData = data.map((r) => ({
    department: r.department,
    count: r.employee_count,
  }));

  return (
    <div className="card">
      <h3 className="text-sm font-semibold text-gray-700 mb-4">Department Headcount</h3>
      {isLoading ? (
        <div className="h-56 flex items-center justify-center text-gray-400 text-sm">Loading…</div>
      ) : (
        <ResponsiveContainer width="100%" height={280}>
          <BarChart data={chartData} margin={{ top: 4, right: 8, left: 0, bottom: 40 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis
              dataKey="department"
              tick={{ fontSize: 11 }}
              angle={-35}
              textAnchor="end"
              interval={0}
            />
            <YAxis tick={{ fontSize: 11 }} />
            <Tooltip contentStyle={{ fontSize: 12 }} />
            <Bar dataKey="count" fill="#10b981" radius={[3, 3, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}
