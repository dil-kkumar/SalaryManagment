'use client';

import { z } from 'zod';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { X } from 'lucide-react';
import { employeeApi } from '@/lib/api';
import type { Employee, EmployeeFormData } from '@/types';

const schema = z.object({
  first_name:      z.string().min(1, 'Required').max(100),
  last_name:       z.string().min(1, 'Required').max(100),
  email:           z.string().email('Invalid email'),
  job_title:       z.string().min(1, 'Required').max(100),
  department:      z.string().min(1, 'Required').max(100),
  country:         z.string().min(1, 'Required').max(100),
  salary:          z.coerce.number().positive('Must be > 0'),
  employment_type: z.enum(['full-time', 'part-time', 'contractor']),
  hire_date:       z.string().min(1, 'Required'),
  status:          z.enum(['active', 'inactive']),
});

type FormValues = z.infer<typeof schema>;

interface Props {
  employee?: Employee;
  onClose: () => void;
}

export default function EmployeeModal({ employee, onClose }: Props) {
  const qc = useQueryClient();
  const isEdit = !!employee;

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: employee
      ? {
          ...employee,
          salary: employee.salary,
          hire_date: employee.hire_date?.slice(0, 10),
        }
      : {
          employment_type: 'full-time',
          status: 'active',
        },
  });

  const mutation = useMutation({
    mutationFn: (data: EmployeeFormData) =>
      isEdit ? employeeApi.update(employee!.id, data) : employeeApi.create(data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['employees'] });
      onClose();
    },
  });

  const onSubmit = (data: FormValues) => mutation.mutate(data as EmployeeFormData);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden
      />

      {/* Dialog */}
      <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-xl mx-4 max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h2 className="text-base font-semibold">
            {isEdit ? 'Edit Employee' : 'Add Employee'}
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <X size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="px-6 py-5 space-y-4">
          {mutation.isError && (
            <p className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-md px-3 py-2">
              {(mutation.error as Error).message}
            </p>
          )}

          <div className="grid grid-cols-2 gap-4">
            <Field label="First Name" error={errors.first_name?.message}>
              <input className="input" {...register('first_name')} />
            </Field>
            <Field label="Last Name" error={errors.last_name?.message}>
              <input className="input" {...register('last_name')} />
            </Field>
          </div>

          <Field label="Email" error={errors.email?.message}>
            <input className="input" type="email" {...register('email')} />
          </Field>

          <div className="grid grid-cols-2 gap-4">
            <Field label="Job Title" error={errors.job_title?.message}>
              <input className="input" {...register('job_title')} />
            </Field>
            <Field label="Department" error={errors.department?.message}>
              <input className="input" {...register('department')} />
            </Field>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Field label="Country" error={errors.country?.message}>
              <input className="input" {...register('country')} />
            </Field>
            <Field label="Annual Salary (USD)" error={errors.salary?.message}>
              <input className="input" type="number" step="0.01" min="1" {...register('salary')} />
            </Field>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Field label="Employment Type" error={errors.employment_type?.message}>
              <select className="input" {...register('employment_type')}>
                <option value="full-time">Full-time</option>
                <option value="part-time">Part-time</option>
                <option value="contractor">Contractor</option>
              </select>
            </Field>
            <Field label="Status" error={errors.status?.message}>
              <select className="input" {...register('status')}>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </Field>
          </div>

          <Field label="Hire Date" error={errors.hire_date?.message}>
            <input className="input" type="date" {...register('hire_date')} />
          </Field>

          <div className="flex justify-end gap-2 pt-2 border-t border-gray-100">
            <button type="button" className="btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn-primary" disabled={isSubmitting || mutation.isPending}>
              {mutation.isPending ? 'Saving…' : isEdit ? 'Save Changes' : 'Add Employee'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function Field({
  label,
  error,
  children,
}: {
  label: string;
  error?: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label className="label">{label}</label>
      {children}
      {error && <p className="mt-1 text-xs text-red-600">{error}</p>}
    </div>
  );
}
