'use client';

import { useState, useCallback } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  useReactTable,
  getCoreRowModel,
  flexRender,
  createColumnHelper,
  type SortingState,
} from '@tanstack/react-table';
import {
  Plus, Search, ChevronUp, ChevronDown, ChevronsUpDown,
  ChevronLeft, ChevronRight, Pencil, Trash2,
} from 'lucide-react';
import { employeeApi, insightsApi } from '@/lib/api';
import type { Employee } from '@/types';
import EmployeeModal from './EmployeeModal';
import DeleteConfirmDialog from './DeleteConfirmDialog';

const fmt = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });
const col = createColumnHelper<Employee>();

export default function EmployeeTable() {
  // ── filter / pagination state ──────────────────────────────────────────────
  const [page, setPage]               = useState(1);
  const [pageSize]                    = useState(20);
  const [search, setSearch]           = useState('');
  const [debouncedSearch, setDebounced] = useState('');
  const [country, setCountry]         = useState('');
  const [department, setDepartment]   = useState('');
  const [status, setStatus]           = useState('');
  const [sorting, setSorting]         = useState<SortingState>([]);

  // ── modal state ────────────────────────────────────────────────────────────
  const [addOpen, setAddOpen]         = useState(false);
  const [editTarget, setEditTarget]   = useState<Employee | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Employee | null>(null);

  // ── debounce search ────────────────────────────────────────────────────────
  const handleSearch = useCallback((val: string) => {
    setSearch(val);
    clearTimeout((handleSearch as any)._t);
    (handleSearch as any)._t = setTimeout(() => {
      setDebounced(val);
      setPage(1);
    }, 300);
  }, []);

  const sortCol = sorting[0]?.id;
  const sortDir = sorting[0] ? (sorting[0].desc ? 'desc' : 'asc') : undefined;

  // ── data fetch ─────────────────────────────────────────────────────────────
  const { data, isFetching } = useQuery({
    queryKey: ['employees', page, pageSize, debouncedSearch, country, department, status, sortCol, sortDir],
    queryFn: () =>
      employeeApi.list({ page, page_size: pageSize, search: debouncedSearch, country, department, status, sort: sortCol, direction: sortDir }),
    placeholderData: (prev) => prev,
  });

  const { data: meta } = useQuery({
    queryKey: ['insights-summary'],
    queryFn: insightsApi.summary,
    staleTime: 60_000,
  });

  // ── columns ────────────────────────────────────────────────────────────────
  const columns = [
    col.accessor('full_name', {
      header: 'Name',
      enableSorting: false,
      cell: (info) => <span className="font-medium text-gray-900">{info.getValue()}</span>,
    }),
    col.accessor('email', { header: 'Email', enableSorting: true }),
    col.accessor('job_title', { header: 'Job Title', enableSorting: true }),
    col.accessor('department', { header: 'Department', enableSorting: true }),
    col.accessor('country', { header: 'Country', enableSorting: true }),
    col.accessor('salary', {
      header: 'Salary',
      enableSorting: true,
      cell: (info) => fmt.format(info.getValue()),
    }),
    col.accessor('employment_type', {
      header: 'Type',
      enableSorting: false,
      cell: (info) => {
        const v = info.getValue();
        const cls = v === 'full-time' ? 'badge-green' : v === 'contractor' ? 'badge-yellow' : 'badge-blue';
        return <span className={cls}>{v}</span>;
      },
    }),
    col.accessor('status', {
      header: 'Status',
      enableSorting: false,
      cell: (info) => (
        <span className={info.getValue() === 'active' ? 'badge-green' : 'badge-gray'}>
          {info.getValue()}
        </span>
      ),
    }),
    col.accessor('hire_date', { header: 'Hire Date', enableSorting: true }),
    col.display({
      id: 'actions',
      header: '',
      cell: ({ row }) => (
        <div className="flex gap-1 justify-end">
          <button
            className="p-1.5 rounded hover:bg-blue-50 text-blue-600"
            onClick={() => setEditTarget(row.original)}
            title="Edit"
          >
            <Pencil size={14} />
          </button>
          <button
            className="p-1.5 rounded hover:bg-red-50 text-red-600"
            onClick={() => setDeleteTarget(row.original)}
            title="Delete"
          >
            <Trash2 size={14} />
          </button>
        </div>
      ),
    }),
  ];

  const table = useReactTable({
    data: data?.items ?? [],
    columns,
    state: { sorting },
    onSortingChange: (updater) => {
      setSorting(updater);
      setPage(1);
    },
    getCoreRowModel: getCoreRowModel(),
    manualSorting: true,
    manualPagination: true,
    pageCount: data?.total_pages ?? 1,
  });

  const totalPages = data?.total_pages ?? 1;

  return (
    <div className="space-y-4">
      {/* ── Toolbar ── */}
      <div className="flex flex-wrap items-center gap-2">
        {/* Search */}
        <div className="relative flex-1 min-w-48 max-w-xs">
          <Search size={14} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            className="input pl-8"
            placeholder="Search name or email…"
            value={search}
            onChange={(e) => handleSearch(e.target.value)}
          />
        </div>

        {/* Filters */}
        <select
          className="input w-auto min-w-32"
          value={country}
          onChange={(e) => { setCountry(e.target.value); setPage(1); }}
        >
          <option value="">All Countries</option>
          {meta?.countries?.map((c) => <option key={c} value={c}>{c}</option>)}
        </select>

        <select
          className="input w-auto min-w-36"
          value={department}
          onChange={(e) => { setDepartment(e.target.value); setPage(1); }}
        >
          <option value="">All Departments</option>
          {meta?.departments?.map((d) => <option key={d} value={d}>{d}</option>)}
        </select>

        <select
          className="input w-auto min-w-28"
          value={status}
          onChange={(e) => { setStatus(e.target.value); setPage(1); }}
        >
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>

        <div className="ml-auto">
          <button className="btn-primary" onClick={() => setAddOpen(true)}>
            <Plus size={14} /> Add Employee
          </button>
        </div>
      </div>

      {/* ── Table ── */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              {table.getHeaderGroups().map((hg) => (
                <tr key={hg.id}>
                  {hg.headers.map((header) => (
                    <th
                      key={header.id}
                      className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap select-none"
                      onClick={header.column.getCanSort() ? header.column.getToggleSortingHandler() : undefined}
                      style={{ cursor: header.column.getCanSort() ? 'pointer' : 'default' }}
                    >
                      <span className="inline-flex items-center gap-1">
                        {flexRender(header.column.columnDef.header, header.getContext())}
                        {header.column.getCanSort() && (
                          header.column.getIsSorted() === 'asc' ? <ChevronUp size={12} /> :
                          header.column.getIsSorted() === 'desc' ? <ChevronDown size={12} /> :
                          <ChevronsUpDown size={12} className="text-gray-300" />
                        )}
                      </span>
                    </th>
                  ))}
                </tr>
              ))}
            </thead>
            <tbody className="divide-y divide-gray-100">
              {isFetching && !data ? (
                <tr>
                  <td colSpan={columns.length} className="px-4 py-8 text-center text-gray-400 text-sm">
                    Loading…
                  </td>
                </tr>
              ) : table.getRowModel().rows.length === 0 ? (
                <tr>
                  <td colSpan={columns.length} className="px-4 py-8 text-center text-gray-400 text-sm">
                    No employees found.
                  </td>
                </tr>
              ) : (
                table.getRowModel().rows.map((row) => (
                  <tr key={row.id} className="hover:bg-gray-50 transition-colors">
                    {row.getVisibleCells().map((cell) => (
                      <td key={cell.id} className="px-4 py-3 text-gray-700 whitespace-nowrap">
                        {flexRender(cell.column.columnDef.cell, cell.getContext())}
                      </td>
                    ))}
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* ── Pagination ── */}
        <div className="flex items-center justify-between px-4 py-3 border-t border-gray-100 bg-gray-50 text-sm text-gray-600">
          <span>
            {data ? `${data.total.toLocaleString()} total employee${data.total !== 1 ? 's' : ''}` : ''}
          </span>
          <div className="flex items-center gap-1">
            <button
              className="btn-secondary px-2 py-1"
              disabled={page <= 1}
              onClick={() => setPage((p) => p - 1)}
            >
              <ChevronLeft size={14} />
            </button>
            <span className="px-3">
              Page {page} of {totalPages}
            </span>
            <button
              className="btn-secondary px-2 py-1"
              disabled={page >= totalPages}
              onClick={() => setPage((p) => p + 1)}
            >
              <ChevronRight size={14} />
            </button>
          </div>
        </div>
      </div>

      {/* ── Modals ── */}
      {addOpen && <EmployeeModal onClose={() => setAddOpen(false)} />}
      {editTarget && <EmployeeModal employee={editTarget} onClose={() => setEditTarget(null)} />}
      {deleteTarget && (
        <DeleteConfirmDialog
          employeeId={deleteTarget.id}
          employeeName={deleteTarget.full_name}
          onClose={() => setDeleteTarget(null)}
        />
      )}
    </div>
  );
}
