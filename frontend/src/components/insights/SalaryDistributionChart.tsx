'use client';

import { useQuery } from '@tanstack/react-query';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts';
import { insightsApi } from '@/lib/api';

const fmt = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });

export default function SalaryDistributionChart() {
  const { data = [], isLoading } = useQuery({
    queryKey: ['salary-distribution'],
    queryFn: insightsApi.salaryDistribution,
  });

  const chartData = data.map((band) => ({
    ...band,
    display_label: band.band_label,
  }));

  return (
    <div className="card">
      <h3 className="text-sm font-semibold text-gray-700 mb-4">Salary Distribution</h3>
      {isLoading ? (
        <div className="h-56 flex items-center justify-center text-gray-400 text-sm">Loading…</div>
      ) : (
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={chartData} margin={{ top: 4, right: 8, left: 0, bottom: 40 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis
              dataKey="display_label"
              tick={{ fontSize: 10 }}
              angle={-25}
              textAnchor="end"
              interval={0}
            />
            <YAxis tick={{ fontSize: 11 }} />
            <Tooltip
              content={({ active, payload }) => {
                if (active && payload?.[0]?.payload) {
                  const band = payload[0].payload;
                  return (
                    <div className="bg-white p-2 border border-gray-200 rounded shadow-sm text-xs">
                      <p className="font-semibold text-gray-700">{band.band_label}</p>
                      <p className="text-gray-600">{band.count.toLocaleString()} employees</p>
                      <p className="text-gray-500 text-xs mt-1">
                        {fmt.format(band.lower_bound)} - {fmt.format(band.upper_bound)}
                      </p>
                    </div>
                  );
                }
                return null;
              }}
            />
            <Bar dataKey="count" fill="#6366f1" radius={[3, 3, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}
