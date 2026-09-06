import React, { useState } from 'react';
import { Download, Printer, FileText, FileSpreadsheet, Database, CheckCircle2 } from 'lucide-react';
import { exportOrdersToCSV, exportTopItemsToCSV, printReportPage } from '../utils/exportHelpers';
import { reportsService } from '../services/reportsService';

export const ExportActions = ({ analytics = {}, syncStatus }) => {
  const { recentOrders = [], topSellingItems = [] } = analytics;
  const [isExportingMongo, setIsExportingMongo] = useState(false);
  const [mongoMessage, setMongoMessage] = useState(null);

  const handleExportMongo = async () => {
    try {
      setIsExportingMongo(true);
      setMongoMessage(null);
      const data = await reportsService.exportMongoDBBackup();
      const total = data?.summary?.totalRecords ?? 'all';
      setMongoMessage(`✓ Exported ${total} documents from MongoDB!`);
      setTimeout(() => setMongoMessage(null), 5000);
    } catch (err) {
      setMongoMessage(`Export failed: ${err.message}`);
      setTimeout(() => setMongoMessage(null), 5000);
    } finally {
      setIsExportingMongo(false);
    }
  };

  return (
    <section className="max-w-7xl mx-auto px-4 md:px-8 mb-12">
      <div className="glass-card p-6 rounded-3xl flex flex-col gap-4 border border-slate-800">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h3 className="text-base font-bold text-white flex items-center gap-2">
              <Download className="w-5 h-5 text-[#FF5722]" />
              <span>Export & Print Business Reports</span>
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">
              Download offline copies of your order logs, dish analytics, or a full MongoDB cloud database backup
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* MongoDB Full Backup Export */}
            <button
              onClick={handleExportMongo}
              disabled={isExportingMongo}
              className="px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white shadow-lg shadow-emerald-600/20 text-xs font-bold flex items-center gap-2 transition-all disabled:opacity-50"
              title="Download full JSON dump of all collections in MongoDB"
            >
              <Database className={`w-4 h-4 ${isExportingMongo ? 'animate-bounce' : ''}`} />
              <span>{isExportingMongo ? 'Exporting MongoDB...' : 'Export Full MongoDB (JSON)'}</span>
            </button>

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

        {mongoMessage && (
          <div className="px-4 py-2 rounded-xl bg-emerald-500/15 border border-emerald-500/30 text-emerald-300 text-xs font-semibold flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
            <span>{mongoMessage}</span>
          </div>
        )}
      </div>
    </section>
  );
};
