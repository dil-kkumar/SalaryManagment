'use client';

import { useMemo, useState } from 'react';
import { z } from 'zod';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { X } from 'lucide-react';
import { employeeApi, staticDataApi } from '@/lib/api';
import type { CountryCustomFieldDefinition, Employee, EmployeeFormData } from '@/types';

const schema = z.object({
  first_name:      z.string().trim().min(1, 'Required').max(100),
  last_name:       z.string().trim().min(1, 'Required').max(100),
  email:           z.string().trim().min(1, 'Required').email('Invalid email'),
  job_title:       z.string().trim().min(1, 'Required').max(100),
  department:      z.string().trim().min(1, 'Required').max(100),
  country:         z.string().trim().min(1, 'Required').max(100),
  salary:          z.preprocess(
    (value) => (value === '' || value === null || value === undefined ? undefined : Number(value)),
    z.number({ required_error: 'Required', invalid_type_error: 'Required' }).positive('Must be > 0')
  ),
  employment_type: z
    .string()
    .min(1, 'Required')
    .refine((v) => ['full-time', 'part-time', 'contractor'].includes(v), 'Invalid employment type'),
  hire_date:       z.string().min(1, 'Required'),
  status:          z
    .string()
    .min(1, 'Required')
    .refine((v) => ['active', 'inactive'].includes(v), 'Invalid status'),
  custom_fields: z.record(z.string()).optional(),
});

type FormValues = z.infer<typeof schema>;

interface Props {
  employee?: Employee;
  onClose: () => void;
}

export default function EmployeeModal({ employee, onClose }: Props) {
  const qc = useQueryClient();
  const isEdit = !!employee;
  const [submitFeedback, setSubmitFeedback] = useState<{
    type: 'success' | 'error';
    message: string;
  } | null>(null);

  const { data: staticData } = useQuery({
    queryKey: ['static-data'],
    queryFn: staticDataApi.list,
    staleTime: 60_000,
  });

  const withCurrentValue = (list: string[] | undefined, current?: string) => {
    const base = list ?? [];
    if (!current || base.includes(current)) return base;
    return [current, ...base];
  };

  const jobTitleOptions = withCurrentValue(staticData?.job_titles, employee?.job_title);
  const departmentOptions = withCurrentValue(staticData?.departments, employee?.department);
  const countryOptions = withCurrentValue(staticData?.countries, employee?.country);

  const {
    register,
    handleSubmit,
    watch,
    setValue,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: employee
      ? {
          ...employee,
          salary: employee.salary,
          hire_date: employee.hire_date?.slice(0, 10),
          custom_fields: employee.custom_fields ?? {},
        }
      : {
          employment_type: '',
          status: '',
          custom_fields: {},
        },
  });

  const selectedCountry = watch('country');
  const customFieldDefinitions = useMemo<CountryCustomFieldDefinition[]>(() => {
    if (!selectedCountry) return [];
    return staticData?.country_custom_fields?.[selectedCountry] ?? [];
  }, [selectedCountry, staticData]);

  const onCountryChange = (country: string) => {
    setValue('country', country, { shouldDirty: true, shouldValidate: true });
    const definitions = staticData?.country_custom_fields?.[country] ?? [];
    const nextValues: Record<string, string> = {};

    definitions.forEach((definition) => {
      const existing = employee?.custom_fields?.[definition.field_key];
      if (existing) nextValues[definition.field_key] = String(existing);
    });

    setValue('custom_fields', nextValues, { shouldDirty: true, shouldValidate: false });
  };

  const mutation = useMutation({
    mutationFn: (data: EmployeeFormData) =>
      isEdit ? employeeApi.update(employee!.id, data) : employeeApi.create(data),
    onMutate: () => {
      setSubmitFeedback(null);
    },
    onSuccess: () => {
      setSubmitFeedback({
        type: 'success',
        message: isEdit ? 'Employee updated successfully.' : 'Employee added successfully.',
      });
      setTimeout(() => setSubmitFeedback(null), 2200);
      qc.invalidateQueries({ queryKey: ['employees'] });
      setTimeout(onClose, 1200);
    },
    onError: (error: Error) => {
      setSubmitFeedback({
        type: 'error',
        message: error.message || (isEdit ? 'Failed to update employee.' : 'Failed to add employee.'),
      });
      setTimeout(() => setSubmitFeedback(null), 3000);
    },
  });

  const onSubmit = (data: FormValues) => {
    const values = (data.custom_fields ?? {}) as Record<string, string>;
    const requiredMissing = customFieldDefinitions.find((definition) => {
      if (!definition.required) return false;
      return !String(values[definition.field_key] ?? '').trim();
    });

    if (requiredMissing) {
      setSubmitFeedback({
        type: 'error',
        message: `${requiredMissing.label} is required for ${selectedCountry}.`,
      });
      return;
    }

    const payload: EmployeeFormData = {
      ...data,
      custom_fields: values,
    };

    mutation.mutate(payload);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {submitFeedback && (
        <div
          className={`fixed top-6 right-6 z-[60] min-w-72 max-w-sm rounded-lg border px-4 py-3 text-sm shadow-lg transition-all ${
            submitFeedback.type === 'success'
              ? 'bg-green-50 border-green-200 text-green-700'
              : 'bg-red-50 border-red-200 text-red-700'
          }`}
          role="status"
          aria-live="polite"
        >
          {submitFeedback.message}
        </div>
      )}

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

        <form onSubmit={handleSubmit(onSubmit)} noValidate className="px-6 py-5 space-y-4">
          <input type="hidden" {...register('country')} />

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
              {jobTitleOptions.length > 0 ? (
                <select className="input" {...register('job_title')}>
                  <option value="">Select Job Title</option>
                  {jobTitleOptions.map((jobTitle) => (
                    <option key={jobTitle} value={jobTitle}>{jobTitle}</option>
                  ))}
                </select>
              ) : (
                <input className="input" {...register('job_title')} />
              )}
            </Field>
            <Field label="Department" error={errors.department?.message}>
              {departmentOptions.length > 0 ? (
                <select className="input" {...register('department')}>
                  <option value="">Select Department</option>
                  {departmentOptions.map((department) => (
                    <option key={department} value={department}>{department}</option>
                  ))}
                </select>
              ) : (
                <input className="input" {...register('department')} />
              )}
            </Field>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Field label="Country" error={errors.country?.message}>
              {countryOptions.length > 0 ? (
                <select
                  className="input"
                  value={selectedCountry || ''}
                  onChange={(e) => onCountryChange(e.target.value)}
                >
                  <option value="">Select Country</option>
                  {countryOptions.map((country) => (
                    <option key={country} value={country}>{country}</option>
                  ))}
                </select>
              ) : (
                <input
                  className="input"
                  value={selectedCountry || ''}
                  onChange={(e) => onCountryChange(e.target.value)}
                />
              )}
            </Field>
            <Field label="Annual Salary (USD)" error={errors.salary?.message}>
              <input className="input" type="number" step="0.01" min="1" {...register('salary')} />
            </Field>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Field label="Employment Type" error={errors.employment_type?.message}>
              <select className="input" {...register('employment_type')}>
                <option value="">Select Employment Type</option>
                <option value="full-time">Full-time</option>
                <option value="part-time">Part-time</option>
                <option value="contractor">Contractor</option>
              </select>
            </Field>
            <Field label="Status" error={errors.status?.message}>
              <select className="input" {...register('status')}>
                <option value="">Select Status</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </Field>
          </div>

          <Field label="Hire Date" error={errors.hire_date?.message}>
            <input className="input" type="date" {...register('hire_date')} />
          </Field>

          {customFieldDefinitions.length > 0 && (
            <div className="space-y-3 rounded-lg border border-gray-200 bg-gray-50 p-4">
              <h3 className="text-sm font-semibold text-gray-800">Country-specific information</h3>
              <div className="grid grid-cols-2 gap-4">
                {customFieldDefinitions.map((definition) => {
                  const inputType = definition.field_type === 'number' ? 'number' : definition.field_type === 'date' ? 'date' : 'text';
                  return (
                    <div key={definition.id}>
                      <label className="label">
                        {definition.label}
                        {definition.required ? <span className="text-red-600"> *</span> : null}
                      </label>
                      <input
                        className="input"
                        type={inputType}
                        placeholder={definition.placeholder ?? ''}
                        {...register(`custom_fields.${definition.field_key}` as const)}
                      />
                    </div>
                  );
                })}
              </div>
            </div>
          )}

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
      <label className="label">
        {label} <span className="text-red-600">*</span>
      </label>
      {children}
      {error && <p className="mt-1 text-xs text-red-600">{error}</p>}
    </div>
  );
}
