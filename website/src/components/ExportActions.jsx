import React from 'react';
import { Download, Printer, FileText, FileSpreadsheet } from 'lucide-react';
import { exportOrdersToCSV, exportTopItemsToCSV, printReportPage } from '../utils/exportHelpers';

export const ExportActions = ({ analytics = {} }) => {
  const { recentOrders = [], topSellingItems = [] } = analytics;

  return (
    <section className="max-w-7xl mx-auto px-4 md:px-8 mb-12">
      <div className="glass-card p-6 rounded-3xl flex flex-col sm:flex-row items-center justify-between gap-4 border border-slate-800">
        <div>
          <h3 className="text-base font-bold text-white flex items-center gap-2">
            <Download className="w-5 h-5 text-[#FF5722]" />
            <span>Export & Print Business Reports</span>
          </h3>
          <p className="text-xs text-slate-400 mt-0.5">Download offline copies of your order logs and dish analytics</p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <button
            onClick={() => exportOrdersToCSV(recentOrders)}
            className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 text-xs font-bold flex items-center gap-2 transition-all"
          >
            <FileSpreadsheet className="w-4 h-4 text-emerald-400" />
            <span>Export Orders CSV</span>
          </button>

          <button
            onClick={() => exportTopItemsToCSV(topSellingItems)}
            className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 text-xs font-bold flex items-center gap-2 transition-all"
          >
            <FileText className="w-4 h-4 text-blue-400" />
            <span>Export Top Dishes CSV</span>
          </button>

          <button
            onClick={printReportPage}
            className="px-5 py-2.5 rounded-xl bg-[#FF5722] hover:bg-[#F4511E] text-white shadow-lg shadow-[#FF5722]/30 text-xs font-bold flex items-center gap-2 transition-all"
          >
            <Printer className="w-4 h-4" />
            <span>Print Report</span>
          </button>
        </div>
      </div>
    </section>
  );
};
