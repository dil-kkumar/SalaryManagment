'use client';

import { useState, useCallback, useRef } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  useReactTable,
  getCoreRowModel,
  flexRender,
  createColumnHelper,
  type SortingState,
  type ColumnSizingState,
} from '@tanstack/react-table';
import {
  Plus, Search, ChevronUp, ChevronDown, ChevronsUpDown,
  ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, Pencil, Trash2, Download, Upload,
} from 'lucide-react';

// ── Tooltip Component ──
function Tooltip({ text, children }: { text: string; children: React.ReactNode }) {
  const [show, setShow] = useState(false);
  return (
    <div className="relative inline-block">
      <div
        onMouseEnter={() => setShow(true)}
        onMouseLeave={() => setShow(false)}
      >
        {children}
      </div>
      {show && (
        <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-gray-900 text-white text-xs rounded whitespace-nowrap z-10 pointer-events-none">
          {text}
        </div>
      )}
    </div>
  );
}
import { employeeApi, insightsApi, API_BASE } from '@/lib/api';
import type { Employee } from '@/types';
import EmployeeModal from './EmployeeModal';
import DeleteConfirmDialog from './DeleteConfirmDialog';
import CountryCustomFieldsManager from './CountryCustomFieldsManager';

const fmt = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });
const col = createColumnHelper<Employee>();

export default function EmployeeTable() {
  // ── filter / pagination state ──────────────────────────────────────────────
  const [page, setPage]               = useState(1);
  const [pageSize, setPageSize]       = useState(20);
  const [search, setSearch]           = useState('');
  const [debouncedSearch, setDebounced] = useState('');
  const [country, setCountry]         = useState('');
  const [department, setDepartment]   = useState('');
  const [status, setStatus]           = useState('');
  const [sorting, setSorting]         = useState<SortingState>([]);
  const [columnSizing, setColumnSizing] = useState<ColumnSizingState>({});

  // ── import/export state ────────────────────────────────────────────────────
  const [isImporting, setIsImporting] = useState(false);
  const [importMessage, setImportMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [isExporting, setIsExporting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // ── modal state ────────────────────────────────────────────────────────────
  const [addOpen, setAddOpen]         = useState(false);
  const [fieldsManagerOpen, setFieldsManagerOpen] = useState(false);
  const [editTarget, setEditTarget]   = useState<Employee | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Employee | null>(null);

  // ── import handler ─────────────────────────────────────────────────────────
  const handleImport = useCallback(async (file: File) => {
    setIsImporting(true);
    setImportMessage(null);

    const formData = new FormData();
    formData.append('file', file);

    try {
      const response = await fetch(`${API_BASE}/api/v1/employees/import`, {
        method: 'POST',
        body: formData,
      });

      const data = await response.json();

      if (data.success && data.success.length > 0) {
        setImportMessage({
          type: 'success',
          text: `Successfully imported ${data.success.length} employee${data.success.length !== 1 ? 's' : ''}`,
        });
        setPage(1);
        // Refetch the employee list
        window.location.reload();
      } else if (data.errors && data.errors.length > 0) {
        setImportMessage({
          type: 'error',
          text: `Import failed: ${data.errors[0]}`,
        });
      }
    } catch (err) {
      setImportMessage({
        type: 'error',
        text: 'Failed to import file. Please try again.',
      });
    } finally {
      setIsImporting(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  }, []);

  const handleExport = useCallback(async (format: 'csv' | 'xlsx') => {
    setIsExporting(true);

    const queryParams = new URLSearchParams({
      format,
      ...(search && { search: debouncedSearch }),
      ...(country && { country }),
      ...(department && { department }),
      ...(status && { status }),
    });

    try {
      const response = await fetch(`${API_BASE}/api/v1/employees/export?${queryParams}`, {
        method: 'GET',
      });

      if (!response.ok) throw new Error('Export failed');

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `employees_${new Date().toISOString().slice(0, 10)}.${format}`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
    } catch (err) {
      setImportMessage({
        type: 'error',
        text: `Failed to export as ${format.toUpperCase()}`,
      });
    } finally {
      setIsExporting(false);
    }
  }, [debouncedSearch, country, department, status]);

  const handleDownloadImportTemplate = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE}/api/v1/employees/import_template`, {
        method: 'GET',
      });

      if (!response.ok) throw new Error('Download failed');

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = 'employees_import_template.csv';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
    } catch (err) {
      setImportMessage({
        type: 'error',
        text: 'Failed to download import template. Please try again.',
      });
    }
  }, []);

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
    col.accessor('employee_id', {
      header: 'Employee ID',
      size: 120,
      enableSorting: true,
      cell: (info) => <span className="font-mono text-xs text-blue-700 font-semibold">{info.getValue()}</span>,
    }),
    col.accessor('full_name', {
      header: 'Name',
      size: 140,
      enableSorting: false,
      cell: (info) => <span className="font-medium text-gray-900">{info.getValue()}</span>,
    }),
    col.accessor('email', { header: 'Email', size: 180, enableSorting: true }),
    col.accessor('job_title', { header: 'Job Title', size: 160, enableSorting: true }),
    col.accessor('department', { header: 'Department', size: 120, enableSorting: true }),
    col.accessor('country', { header: 'Country', size: 100, enableSorting: true }),
    col.accessor('salary', {
      header: 'Salary',
      size: 110,
      enableSorting: true,
      cell: (info) => fmt.format(info.getValue()),
    }),
    col.accessor('employment_type', {
      header: 'Type',
      size: 90,
      enableSorting: false,
      cell: (info) => {
        const v = info.getValue();
        const cls = v === 'full-time' ? 'badge-green' : v === 'contractor' ? 'badge-yellow' : 'badge-blue';
        return <span className={cls}>{v}</span>;
      },
    }),
    col.accessor('status', {
      header: 'Status',
      size: 85,
      enableSorting: false,
      cell: (info) => (
        <span className={info.getValue() === 'active' ? 'badge-green' : 'badge-gray'}>
          {info.getValue()}
        </span>
      ),
    }),
    col.accessor('hire_date', { header: 'Hire Date', size: 100, enableSorting: true }),
    col.display({
      id: 'actions',
      header: '',
      size: 60,
      cell: ({ row }) => (
        <div className="flex gap-1 justify-end">
          <Tooltip text="Edit">
            <button
              className="p-1.5 rounded hover:bg-blue-50 text-blue-600 transition-colors"
              onClick={() => setEditTarget(row.original)}
            >
              <Pencil size={14} />
            </button>
          </Tooltip>
          <Tooltip text="Delete">
            <button
              className="p-1.5 rounded hover:bg-red-50 text-red-600 transition-colors"
              onClick={() => setDeleteTarget(row.original)}
            >
              <Trash2 size={14} />
            </button>
          </Tooltip>
        </div>
      ),
    }),
  ];

  const table = useReactTable({
    data: data?.items ?? [],
    columns,
    state: { sorting, columnSizing },
    onSortingChange: (updater) => {
      setSorting(updater);
      setPage(1);
    },
    onColumnSizingChange: setColumnSizing,
    getCoreRowModel: getCoreRowModel(),
    manualSorting: true,
    manualPagination: true,
    pageCount: data?.total_pages ?? 1,
    columnResizeMode: 'onChange',
  });

  const totalPages = Math.max(data?.total_pages ?? 1, 1);

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
          <div className="flex items-center gap-2">
            <Tooltip text="Import employees from CSV">
              <button
                className="btn-secondary"
                onClick={() => fileInputRef.current?.click()}
                disabled={isImporting}
              >
                <Upload size={14} /> Import
              </button>
            </Tooltip>
            <Tooltip text="Download CSV sample template">
              <button
                className="btn-secondary"
                onClick={handleDownloadImportTemplate}
                disabled={isImporting || isExporting}
              >
                <Download size={14} /> Sample CSV
              </button>
            </Tooltip>
            <input
              ref={fileInputRef}
              type="file"
              accept=".csv"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) handleImport(file);
              }}
              disabled={isImporting}
            />
            <Tooltip text="Export as CSV">
              <button
                className="btn-secondary"
                onClick={() => handleExport('csv')}
                disabled={isExporting}
              >
                <Download size={14} /> CSV
              </button>
            </Tooltip>
            <Tooltip text="Export as Excel">
              <button
                className="btn-secondary"
                onClick={() => handleExport('xlsx')}
                disabled={isExporting}
              >
                <Download size={14} /> Excel
              </button>
            </Tooltip>
            <button className="btn-secondary" onClick={() => setFieldsManagerOpen(true)}>
              Manage Country Fields
            </button>
            <button className="btn-primary" onClick={() => setAddOpen(true)}>
              <Plus size={14} /> Add Employee
            </button>
          </div>
        </div>
      </div>

      {/* ── Table ── */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm" style={{ width: table.getTotalSize() }}>
            <thead className="bg-gray-50 border-b border-gray-200">
              {table.getHeaderGroups().map((hg) => (
                <tr key={hg.id}>
                  {hg.headers.map((header) => (
                    <th
                      key={header.id}
                      className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide select-none relative bg-gray-50"
                      style={{ width: header.getSize() }}
                      onClick={header.column.getCanSort() ? header.column.getToggleSortingHandler() : undefined}
                    >
                      <div className={header.column.getCanSort() ? 'cursor-pointer' : ''}>
                        <span className="inline-flex items-center gap-1 whitespace-nowrap">
                          {flexRender(header.column.columnDef.header, header.getContext())}
                          {header.column.getCanSort() && (
                            header.column.getIsSorted() === 'asc' ? <ChevronUp size={12} /> :
                            header.column.getIsSorted() === 'desc' ? <ChevronDown size={12} /> :
                            <ChevronsUpDown size={12} className="text-gray-300" />
                          )}
                        </span>
                      </div>
                      {header.getContext().header.column.columnDef.size !== undefined && (
                        <div
                          onMouseDown={header.getResizeHandler()}
                          onTouchStart={header.getResizeHandler()}
                          className={`absolute right-0 top-0 h-full w-1 select-none touch-none bg-blue-400 cursor-col-resize opacity-0 hover:opacity-100 transition-opacity ${
                            header.column.getIsResizing() ? 'opacity-100' : ''
                          }`}
                          style={{ userSelect: 'none' }}
                        />
                      )}
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
                      <td key={cell.id} className="px-4 py-3 text-gray-700" style={{ width: cell.column.getSize() }}>
                        <div className={cell.column.id === 'actions' ? '' : 'break-words'}>
                          {flexRender(cell.column.columnDef.cell, cell.getContext())}
                        </div>
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
          <div className="flex items-center gap-3">
            <span>
              {data ? `${data.total.toLocaleString()} total employee${data.total !== 1 ? 's' : ''}` : ''}
            </span>
            <label className="flex items-center gap-2">
              <span className="text-gray-500">Rows:</span>
              <select
                className="input w-auto min-w-20 py-1 px-2"
                value={pageSize}
                onChange={(e) => {
                  setPageSize(Number(e.target.value));
                  setPage(1);
                }}
              >
                {[10, 20, 50, 100].map((size) => (
                  <option key={size} value={size}>{size}</option>
                ))}
              </select>
            </label>
          </div>
          <div className="flex items-center gap-1">
            <button
              className="btn-secondary px-2 py-1"
              disabled={page <= 1}
              onClick={() => setPage(1)}
              title="First page"
            >
              <ChevronsLeft size={14} />
            </button>
            <button
              className="btn-secondary px-2 py-1"
              disabled={page <= 1}
              onClick={() => setPage((p) => p - 1)}
              title="Previous page"
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
              title="Next page"
            >
              <ChevronRight size={14} />
            </button>
            <button
              className="btn-secondary px-2 py-1"
              disabled={page >= totalPages}
              onClick={() => setPage(totalPages)}
              title="Last page"
            >
              <ChevronsRight size={14} />
            </button>
          </div>
        </div>
      </div>

      {/* ── Modals ── */}
      {importMessage && (
        <div className={`fixed top-4 right-4 px-4 py-3 rounded-lg text-white z-50 ${
          importMessage.type === 'success' ? 'bg-green-500' : 'bg-red-500'
        }`}>
          {importMessage.text}
        </div>
      )}
      {addOpen && <EmployeeModal onClose={() => setAddOpen(false)} />}
      {fieldsManagerOpen && <CountryCustomFieldsManager onClose={() => setFieldsManagerOpen(false)} />}
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
