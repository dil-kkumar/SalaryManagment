'use client';

import { useMutation, useQueryClient } from '@tanstack/react-query';
import { AlertTriangle } from 'lucide-react';
import { employeeApi } from '@/lib/api';

interface Props {
  employeeId: number;
  employeeName: string;
  onClose: () => void;
}

export default function DeleteConfirmDialog({ employeeId, employeeName, onClose }: Props) {
  const qc = useQueryClient();

  const mutation = useMutation({
    mutationFn: () => employeeApi.delete(employeeId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['employees'] });
      onClose();
    },
  });

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} aria-hidden />
      <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-sm mx-4 p-6">
        <div className="flex items-start gap-3">
          <div className="flex-shrink-0 rounded-full bg-red-100 p-2">
            <AlertTriangle size={20} className="text-red-600" />
          </div>
          <div>
            <h2 className="text-base font-semibold text-gray-900">Delete Employee</h2>
            <p className="mt-1 text-sm text-gray-500">
              Are you sure you want to delete{' '}
              <span className="font-medium text-gray-800">{employeeName}</span>? This action cannot
              be undone.
            </p>
          </div>
        </div>

        {mutation.isError && (
          <p className="mt-3 text-sm text-red-600">{(mutation.error as Error).message}</p>
        )}

        <div className="mt-5 flex justify-end gap-2">
          <button className="btn-secondary" onClick={onClose} disabled={mutation.isPending}>
            Cancel
          </button>
          <button
            className="btn-danger"
            onClick={() => mutation.mutate()}
            disabled={mutation.isPending}
          >
            {mutation.isPending ? 'Deleting…' : 'Delete'}
          </button>
        </div>
      </div>
    </div>
  );
}
