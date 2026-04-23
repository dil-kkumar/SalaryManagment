'use client';

import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Plus, Trash2, X } from 'lucide-react';
import { countryCustomFieldApi, staticDataApi } from '@/lib/api';
import type { CountryCustomFieldType } from '@/types';

interface Props {
  onClose: () => void;
}

type FormState = {
  country: string;
  label: string;
  field_type: CountryCustomFieldType;
  placeholder: string;
  required: boolean;
};

const initialForm: FormState = {
  country: '',
  label: '',
  field_type: 'text',
  placeholder: '',
  required: false,
};

export default function CountryCustomFieldsManager({ onClose }: Props) {
  const qc = useQueryClient();
  const [form, setForm] = useState<FormState>(initialForm);
  const [feedback, setFeedback] = useState<string | null>(null);

  const { data: staticData } = useQuery({
    queryKey: ['static-data'],
    queryFn: staticDataApi.list,
    staleTime: 60_000,
  });

  const createMutation = useMutation({
    mutationFn: countryCustomFieldApi.create,
    onSuccess: () => {
      setFeedback('Field added successfully.');
      setForm(initialForm);
      qc.invalidateQueries({ queryKey: ['static-data'] });
      qc.invalidateQueries({ queryKey: ['country-custom-fields'] });
    },
    onError: (error: Error) => setFeedback(error.message),
  });

  const deleteMutation = useMutation({
    mutationFn: countryCustomFieldApi.delete,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['static-data'] });
      qc.invalidateQueries({ queryKey: ['country-custom-fields'] });
    },
  });

  const handleSubmit = (event: React.FormEvent) => {
    event.preventDefault();
    if (!form.country.trim() || !form.label.trim()) {
      setFeedback('Country and label are required.');
      return;
    }

    createMutation.mutate({
      country: form.country.trim(),
      label: form.label.trim(),
      field_type: form.field_type,
      placeholder: form.placeholder.trim(),
      required: form.required,
    });
  };

  const grouped = staticData?.country_custom_fields ?? {};
  const countries = staticData?.countries ?? [];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} aria-hidden />

      <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-3xl mx-4 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h2 className="text-base font-semibold">Country Custom Fields</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600" aria-label="Close">
            <X size={18} />
          </button>
        </div>

        <div className="px-6 py-5 space-y-6">
          <form onSubmit={handleSubmit} className="space-y-4 rounded-lg border border-gray-200 p-4">
            <h3 className="text-sm font-semibold text-gray-800">Add field definition</h3>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label">Country</label>
                <input
                  className="input"
                  list="country-options"
                  value={form.country}
                  onChange={(e) => setForm((prev) => ({ ...prev, country: e.target.value }))}
                  placeholder="India"
                />
                <datalist id="country-options">
                  {countries.map((country) => (
                    <option key={country} value={country} />
                  ))}
                </datalist>
              </div>

              <div>
                <label className="label">Field Label</label>
                <input
                  className="input"
                  value={form.label}
                  onChange={(e) => setForm((prev) => ({ ...prev, label: e.target.value }))}
                  placeholder="PAN Number"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label">Field Type</label>
                <select
                  className="input"
                  value={form.field_type}
                  onChange={(e) => setForm((prev) => ({ ...prev, field_type: e.target.value as CountryCustomFieldType }))}
                >
                  <option value="text">Text</option>
                  <option value="number">Number</option>
                  <option value="date">Date</option>
                </select>
              </div>

              <div>
                <label className="label">Placeholder</label>
                <input
                  className="input"
                  value={form.placeholder}
                  onChange={(e) => setForm((prev) => ({ ...prev, placeholder: e.target.value }))}
                  placeholder="Enter value"
                />
              </div>
            </div>

            <label className="inline-flex items-center gap-2 text-sm text-gray-700">
              <input
                type="checkbox"
                checked={form.required}
                onChange={(e) => setForm((prev) => ({ ...prev, required: e.target.checked }))}
              />
              Required field
            </label>

            {feedback && <p className="text-sm text-gray-600">{feedback}</p>}

            <button type="submit" className="btn-primary" disabled={createMutation.isPending}>
              <Plus size={14} /> {createMutation.isPending ? 'Adding...' : 'Add Field'}
            </button>
          </form>

          <div className="space-y-4">
            <h3 className="text-sm font-semibold text-gray-800">Configured fields</h3>
            {Object.keys(grouped).length === 0 ? (
              <p className="text-sm text-gray-500">No custom fields configured yet.</p>
            ) : (
              Object.entries(grouped).map(([country, fields]) => (
                <div key={country} className="rounded-lg border border-gray-200 overflow-hidden">
                  <div className="bg-gray-50 px-4 py-2 text-sm font-semibold text-gray-800">{country}</div>
                  <div className="divide-y divide-gray-100">
                    {fields.map((field) => (
                      <div key={field.id} className="flex items-center justify-between gap-3 px-4 py-3">
                        <div>
                          <p className="text-sm font-medium text-gray-800">{field.label}</p>
                          <p className="text-xs text-gray-500">
                            key: {field.field_key} | type: {field.field_type} {field.required ? '| required' : ''}
                          </p>
                        </div>
                        <button
                          className="p-1.5 rounded hover:bg-red-50 text-red-600"
                          onClick={() => deleteMutation.mutate(field.id)}
                          aria-label={`Delete ${field.label}`}
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}