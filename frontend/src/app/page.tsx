import EmployeeTable from '@/components/employees/EmployeeTable';

export default function EmployeesPage() {
  return (
    <div>
      <div className="mb-5">
        <h1 className="text-xl font-bold text-gray-900">Employees</h1>
        <p className="text-sm text-gray-500 mt-0.5">Manage your organization's workforce</p>
      </div>
      <EmployeeTable />
    </div>
  );
}
