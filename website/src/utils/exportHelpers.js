import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import { formatCurrency, formatDate, formatNumber } from './formatters';

export const exportToCSV = (data, filename = 'reports_export.csv') => {
  if (!data || !data.length) return;
  const headers = Object.keys(data[0]);
  const csvContent = [
    headers.join(','),
    ...data.map((row) =>
      headers
        .map((header) => {
          const val = row[header];
          return typeof val === 'string' ? `"${val.replace(/"/g, '""')}"` : val ?? '';
        })
        .join(',')
    ),
  ].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
};

export const exportOrdersToCSV = (orders = []) => {
  const formatted = orders.map((o) => ({
    'Bill No': o.orderNumber,
    'Customer Name': o.customerName || 'Walk-in Customer',
    Phone: o.customerPhone || 'N/A',
    'Payment Method': (o.paymentMethod || 'cash').toUpperCase(),
    'Subtotal (INR)': o.subtotal || 0,
    'Discount (INR)': o.discountAmount || 0,
    'Service Charge (INR)': o.serviceChargeAmount || 0,
    'Grand Total (INR)': o.grandTotal || 0,
    Status: (o.orderStatus || 'completed').toUpperCase(),
    'Date & Time': formatDate(o.createdAt),
  }));
  exportToCSV(formatted, `HMB_Orders_${new Date().toISOString().split('T')[0]}.csv`);
};

export const exportOrdersToExcel = (orders = []) => {
  const rows = orders.map((o) => ({
    'Bill No': o.orderNumber,
    'Date & Time': formatDate(o.createdAt),
    'Customer Name': o.customerName || 'Walk-in Customer',
    Phone: o.customerPhone || '',
    'Payment Method': (o.paymentMethod || 'cash').toUpperCase(),
    Items: (o.items || []).map((i) => `${i.name} x${i.quantity}`).join('; '),
    'Subtotal (Rs)': o.subtotal || 0,
    'Discount (Rs)': o.discountAmount || 0,
    'Service Charge (Rs)': o.serviceChargeAmount || 0,
    'Grand Total (Rs)': o.grandTotal || 0,
    Status: (o.orderStatus || 'completed').toUpperCase(),
  }));
  const wb = XLSX.utils.book_new();
  const ws = XLSX.utils.json_to_sheet(rows);
  XLSX.utils.book_append_sheet(wb, ws, 'Orders');
  XLSX.writeFile(wb, `HMB_Orders_${new Date().toISOString().split('T')[0]}.xlsx`);
};

export const exportCustomersToExcel = (customers = []) => {
  const rows = customers.map((c) => ({
    'Customer Name': c.name || '',
    Phone: c.phone || '',
    'Loyalty Card': c.loyaltyCardNumber || '',
    'Total Visits': c.totalVisits || 0,
    'Total Spent (Rs)': c.totalSpent || 0,
    'Loyalty Points': c.loyaltyPoints || 0,
    Address: c.address || '',
    Notes: c.notes || '',
  }));
  const wb = XLSX.utils.book_new();
  const ws = XLSX.utils.json_to_sheet(rows);
  XLSX.utils.book_append_sheet(wb, ws, 'Customers');
  XLSX.writeFile(wb, `HMB_Customers_${new Date().toISOString().split('T')[0]}.xlsx`);
};

export const exportTopItemsToCSV = (items = []) => {
  const formatted = items.map((i) => ({
    'Dish Name': i.name,
    'Quantity Sold': i.qtySold,
    'Total Revenue (INR)': i.revenue,
  }));
  exportToCSV(formatted, `HMB_TopDishes_${new Date().toISOString().split('T')[0]}.csv`);
};

export const exportBusinessReportPDF = ({
  analytics = {},
  settings = {},
  periodLabel = 'Selected Period',
}) => {
  const doc = new jsPDF({ orientation: 'portrait', unit: 'pt', format: 'a4' });
  const pageWidth = doc.internal.pageSize.getWidth();
  const kpis = analytics.kpis || {};
  const businessName = settings?.businessName || 'HMB Bills';

  // Header Banner
  doc.setFillColor(12, 14, 22);
  doc.rect(0, 0, pageWidth, 88, 'F');
  doc.setTextColor(255, 109, 0);
  doc.setFontSize(20);
  doc.text(`${businessName} — Business Report`, 36, 40);
  doc.setTextColor(200, 210, 225);
  doc.setFontSize(10);
  doc.text(`Period: ${periodLabel}   |   Generated: ${new Date().toLocaleString('en-IN')}`, 36, 64);

  // KPI Summary Boxes
  const kpiCards = [
    ['Revenue', formatCurrency(kpis.revenue)],
    ['Orders', formatNumber(kpis.ordersCount)],
    ['Avg Bill Value', formatCurrency(kpis.aov)],
    ['Customers', formatNumber(kpis.totalCustomers)],
  ];
  let y = 112;
  const cardW = (pageWidth - 72 - 24) / 4;
  kpiCards.forEach(([label, val], idx) => {
    const x = 36 + idx * (cardW + 8);
    doc.setFillColor(244, 246, 250);
    doc.roundedRect(x, y, cardW, 56, 6, 6, 'F');
    doc.setTextColor(100, 116, 139);
    doc.setFontSize(9);
    doc.text(label, x + 10, y + 20);
    doc.setTextColor(15, 23, 42);
    doc.setFontSize(13);
    doc.text(val.replace('₹', 'Rs.'), x + 10, y + 42);
  });

  // Payment Channels
  y = 194;
  doc.setTextColor(15, 23, 42);
  doc.setFontSize(13);
  doc.text('Payment Channels', 36, y);
  y += 16;
  const pay = analytics.paymentBreakdown || {};
  const payRows = [
    ['Cash', pay.cash || 0],
    ['UPI', pay.upi || 0],
    ['Card', pay.card || 0],
    ['Wallet', pay.wallet || 0],
  ];
  doc.setFontSize(10);
  payRows.forEach(([name, val]) => {
    doc.setTextColor(51, 65, 85);
    doc.text(name, 40, y);
    doc.text(formatCurrency(val).replace('₹', 'Rs.'), 200, y);
    y += 16;
  });

  // Top Selling Dishes
  y += 12;
  doc.setTextColor(15, 23, 42);
  doc.setFontSize(13);
  doc.text('Top Selling Dishes', 36, y);
  y += 18;
  doc.setFontSize(9.5);
  const items = (analytics.topSellingItems || []).slice(0, 12);
  if (items.length === 0) {
    doc.setTextColor(100, 116, 139);
    doc.text('No dish sales recorded for this period.', 40, y);
  } else {
    items.forEach((item, idx) => {
      if (y > 760) return;
      doc.setTextColor(30, 41, 59);
      doc.text(`${idx + 1}. ${item.name}`, 40, y);
      doc.text(`${formatNumber(item.qtySold)} qty`, 340, y);
      doc.text(formatCurrency(item.revenue).replace('₹', 'Rs.'), 450, y);
      y += 16;
    });
  }

  doc.save(`HMB_Report_${new Date().toISOString().split('T')[0]}.pdf`);
};

export const exportFullBackupExcel = ({ customers = [], orders = [], settings = null }) => {
  const wb = XLSX.utils.book_new();
  const orderRows = orders.map((o) => ({
    'Bill No': o.orderNumber,
    Date: formatDate(o.createdAt),
    'Customer Name': o.customerName || 'Walk-in Customer',
    Phone: o.customerPhone || '',
    'Payment Method': (o.paymentMethod || 'cash').toUpperCase(),
    Items: (o.items || []).map((i) => `${i.name} x${i.quantity}`).join('; '),
    'Subtotal (Rs)': o.subtotal || 0,
    'Discount (Rs)': o.discountAmount || 0,
    'Service Charge (Rs)': o.serviceChargeAmount || 0,
    'Grand Total (Rs)': o.grandTotal || 0,
    Status: (o.orderStatus || 'completed').toUpperCase(),
  }));
  const custRows = customers.map((c) => ({
    'Customer Name': c.name || '',
    Phone: c.phone || '',
    'Loyalty Card': c.loyaltyCardNumber || '',
    'Total Visits': c.totalVisits || 0,
    'Total Spent (Rs)': c.totalSpent || 0,
    'Loyalty Points': c.loyaltyPoints || 0,
    Address: c.address || '',
    Notes: c.notes || '',
  }));
  const settingsRows = settings
    ? [
        { Key: 'Business Name', Value: settings.businessName || '' },
        { Key: 'Phone', Value: settings.phone || '' },
        { Key: 'Address', Value: settings.address || '' },
        { Key: 'Currency', Value: settings.currency || '₹' },
        { Key: 'Invoice Prefix', Value: settings.invoicePrefix || 'B' },
        { Key: 'Service Charge %', Value: settings.serviceChargePercentage || 0 },
        { Key: 'Loyalty Target Visits', Value: settings.loyaltyTargetVisits || 6 },
        { Key: 'Loyalty Reward', Value: settings.loyaltyRewardDescription || '' },
      ]
    : [];

  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(orderRows), 'Orders');
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(custRows), 'Customers');
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(settingsRows), 'Settings');
  XLSX.writeFile(wb, `HMB_Full_Cloud_Backup_${new Date().toISOString().split('T')[0]}.xlsx`);
};

export const printReportPage = () => {
  window.print();
};
