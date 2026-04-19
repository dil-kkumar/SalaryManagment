'use client';

import { useQuery } from '@tanstack/react-query';
import { insightsApi } from '@/lib/api';

const fmt = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });

export default function DepartmentTable() {
  const { data = [], isLoading } = useQuery({
    queryKey: ['department-stats'],
    queryFn: insightsApi.departmentStats,
  });

  return (
    <div className="card">
      <h3 className="text-sm font-semibold text-gray-700 mb-4">Department Breakdown</h3>
      {isLoading ? (
        <p className="text-sm text-gray-400">Loading…</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="text-left py-2 pr-4 text-xs font-semibold text-gray-500 uppercase tracking-wide">Department</th>
                <th className="text-right py-2 pr-4 text-xs font-semibold text-gray-500 uppercase tracking-wide">Headcount</th>
                <th className="text-right py-2 pr-4 text-xs font-semibold text-gray-500 uppercase tracking-wide">Avg Salary</th>
                <th className="text-right py-2 pr-4 text-xs font-semibold text-gray-500 uppercase tracking-wide">Active</th>
                <th className="text-right py-2 text-xs font-semibold text-gray-500 uppercase tracking-wide">Inactive</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {data.map((row) => (
                <tr key={row.department} className="hover:bg-gray-50">
                  <td className="py-2 pr-4 font-medium text-gray-800">{row.department}</td>
                  <td className="py-2 pr-4 text-right text-gray-600">{row.employee_count.toLocaleString()}</td>
                  <td className="py-2 pr-4 text-right text-gray-600">{fmt.format(row.avg_salary)}</td>
                  <td className="py-2 pr-4 text-right">
                    <span className="badge-green">{row.active_count}</span>
                  </td>
                  <td className="py-2 text-right">
                    <span className={row.inactive_count > 0 ? 'badge-gray' : 'text-gray-300 text-xs'}>
                      {row.inactive_count}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
