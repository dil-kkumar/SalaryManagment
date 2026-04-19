'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { insightsApi } from '@/lib/api';

const fmt = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });

export default function TopEarnersList() {
  const [limit, setLimit] = useState(10);

  const { data = [], isLoading } = useQuery({
    queryKey: ['top-earners', limit],
    queryFn: () => insightsApi.topEarners(limit),
  });

  return (
    <div className="card">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-sm font-semibold text-gray-700">Top Earners</h3>
        <select
          className="input w-auto text-xs py-1"
          value={limit}
          onChange={(e) => setLimit(Number(e.target.value))}
        >
          {[5, 10, 20].map((n) => (
            <option key={n} value={n}>Top {n}</option>
          ))}
        </select>
      </div>

      {isLoading ? (
        <p className="text-sm text-gray-400">Loading…</p>
      ) : (
        <ol className="space-y-2">
          {data.map((e, i) => (
            <li key={e.id} className="flex items-center gap-3">
              <span className="text-xs font-bold text-gray-400 w-5 text-right shrink-0">
                {i + 1}
              </span>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-800 truncate">{e.full_name}</p>
                <p className="text-xs text-gray-400 truncate">
                  {e.job_title} · {e.department} · {e.country}
                </p>
              </div>
              <span className="text-sm font-semibold text-green-700 shrink-0">
                {fmt.format(e.salary)}
              </span>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}
