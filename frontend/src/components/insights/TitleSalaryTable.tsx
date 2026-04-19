'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { insightsApi } from '@/lib/api';

const fmt = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });

export default function TitleSalaryTable() {
  const [country, setCountry] = useState('');

  const { data: meta } = useQuery({
    queryKey: ['insights-summary'],
    queryFn: insightsApi.summary,
    staleTime: 60_000,
  });

  const { data = [], isLoading } = useQuery({
    queryKey: ['title-salary', country],
    queryFn: () => insightsApi.titleSalary({ country: country || undefined }),
  });

  const visible = data.slice(0, 20);

  return (
    <div className="card">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-sm font-semibold text-gray-700">Avg Salary by Job Title &amp; Country</h3>
        <select
          className="input w-auto text-xs py-1"
          value={country}
          onChange={(e) => setCountry(e.target.value)}
        >
          <option value="">All Countries</option>
          {meta?.countries?.map((c) => <option key={c} value={c}>{c}</option>)}
        </select>
      </div>

      {isLoading ? (
        <p className="text-sm text-gray-400">Loading…</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="text-left py-2 pr-4 text-xs font-semibold text-gray-500 uppercase tracking-wide">Job Title</th>
                <th className="text-left py-2 pr-4 text-xs font-semibold text-gray-500 uppercase tracking-wide">Country</th>
                <th className="text-right py-2 pr-4 text-xs font-semibold text-gray-500 uppercase tracking-wide">Avg Salary</th>
                <th className="text-right py-2 pr-4 text-xs font-semibold text-gray-500 uppercase tracking-wide">Min</th>
                <th className="text-right py-2 text-xs font-semibold text-gray-500 uppercase tracking-wide">Max</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {visible.map((row) => (
                <tr key={`${row.job_title}-${row.country}`} className="hover:bg-gray-50">
                  <td className="py-2 pr-4 font-medium text-gray-800">{row.job_title}</td>
                  <td className="py-2 pr-4 text-gray-600">{row.country}</td>
                  <td className="py-2 pr-4 text-right font-semibold text-gray-800">{fmt.format(row.avg_salary)}</td>
                  <td className="py-2 pr-4 text-right text-gray-500">{fmt.format(row.min_salary)}</td>
                  <td className="py-2 text-right text-gray-500">{fmt.format(row.max_salary)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {data.length > 20 && (
            <p className="text-xs text-gray-400 pt-2">Showing 20 of {data.length} combinations</p>
          )}
        </div>
      )}
    </div>
  );
}
