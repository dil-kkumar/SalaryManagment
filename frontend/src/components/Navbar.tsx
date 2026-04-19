'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Users, BarChart2 } from 'lucide-react';
import { clsx } from 'clsx';

export default function Navbar() {
  const pathname = usePathname();

  const links = [
    { href: '/', label: 'Employees', icon: Users },
    { href: '/insights', label: 'Insights', icon: BarChart2 },
  ];

  return (
    <header className="bg-white border-b border-gray-200 sticky top-0 z-30">
      <div className="max-w-screen-xl mx-auto px-4 flex items-center h-14 gap-6">
        <span className="font-bold text-blue-600 text-base tracking-tight select-none">
          💼 SalaryMgr
        </span>
        <nav className="flex gap-1">
          {links.map(({ href, label, icon: Icon }) => (
            <Link
              key={href}
              href={href}
              className={clsx(
                'flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
                pathname === href
                  ? 'bg-blue-50 text-blue-700'
                  : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
              )}
            >
              <Icon size={15} />
              {label}
            </Link>
          ))}
        </nav>
      </div>
    </header>
  );
}
