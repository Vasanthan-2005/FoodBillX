import { formatCurrency, formatDate } from './formatters';

export const exportToCSV = (data, filename = 'reports_export.csv') => {
  if (!data || !data.length) return;
  const headers = Object.keys(data[0]);
  const csvContent = [
    headers.join(','),
    ...data.map((row) =>
      headers
        .map((header) => {
          const val = row[header];
          return typeof val === 'string' ? `"${val.replace(/"/g, '""')}"` : val;
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
};

export const exportOrdersToCSV = (orders) => {
  const formatted = orders.map((o) => ({
    'Bill No': o.orderNumber,
    'Customer Name': o.customerName,
    'Phone': o.customerPhone || 'N/A',
    'Payment Method': o.paymentMethod.toUpperCase(),
    'Subtotal (₹)': o.subtotal,
    'Discount (₹)': o.discountAmount,
    'GST Tax (₹)': o.gstAmount,
    'Grand Total (₹)': o.grandTotal,
    'Status': o.orderStatus.toUpperCase(),
    'Date & Time': formatDate(o.createdAt),
  }));
  exportToCSV(formatted, `FoodBillX_Orders_${new Date().toISOString().split('T')[0]}.csv`);
};

export const exportTopItemsToCSV = (items) => {
  const formatted = items.map((i) => ({
    'Dish Name': i.name,
    'Category': i.category,
    'Quantity Sold': i.qtySold,
    'Total Revenue (₹)': i.revenue,
    'Est Profit (₹)': i.profit,
  }));
  exportToCSV(formatted, `FoodBillX_TopItems_${new Date().toISOString().split('T')[0]}.csv`);
};

export const printReportPage = () => {
  window.print();
};
