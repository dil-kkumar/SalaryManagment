import type { Metadata } from 'next';
import './globals.css';
import { Providers } from '@/components/providers';
import Navbar from '@/components/Navbar';

export const metadata: Metadata = {
  title: 'Salary Management',
  description: 'HR Salary Management Tool',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>
          <Navbar />
          <main className="max-w-screen-xl mx-auto px-4 py-6">{children}</main>
        </Providers>
      </body>
    </html>
  );
}
