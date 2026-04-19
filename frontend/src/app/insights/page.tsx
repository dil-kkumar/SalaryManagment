import SummaryCards from '@/components/insights/SummaryCards';
import SalaryByCountryChart from '@/components/insights/SalaryByCountryChart';
import SalaryDistributionChart from '@/components/insights/SalaryDistributionChart';
import DepartmentTable from '@/components/insights/DepartmentTable';
import TopEarnersList from '@/components/insights/TopEarnersList';
import TitleSalaryTable from '@/components/insights/TitleSalaryTable';

export default function InsightsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Salary Insights</h1>
        <p className="text-sm text-gray-500 mt-0.5">Aggregated analytics across your organization</p>
      </div>

      {/* KPI cards */}
      <SummaryCards />

      {/* Charts row */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
        <SalaryByCountryChart />
        <SalaryDistributionChart />
      </div>

      {/* Title salary + top earners */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
        <div className="xl:col-span-2">
          <TitleSalaryTable />
        </div>
        <TopEarnersList />
      </div>

      {/* Department breakdown */}
      <DepartmentTable />
    </div>
  );
}
