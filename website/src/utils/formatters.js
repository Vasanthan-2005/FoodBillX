export const formatCurrency = (amount, decimals = 0) => {
  const num = Number(amount) || 0;
  const isNegative = num < 0;
  const formatted = new Intl.NumberFormat('en-IN', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(Math.abs(num));
  return `${isNegative ? '-' : ''}₹ ${formatted}`;
};

export const formatCompactCurrency = (amount) => {
  const num = Number(amount) || 0;
  const abs = Math.abs(num);
  const sign = num < 0 ? '-' : '';
  if (abs >= 10000000) {
    return `${sign}₹ ${(abs / 10000000).toFixed(2).replace(/\.00$/, '')} Cr`;
  }
  if (abs >= 100000) {
    return `${sign}₹ ${(abs / 100000).toFixed(2).replace(/\.00$/, '')} L`;
  }
  if (abs >= 1000) {
    return `${sign}₹ ${(abs / 1000).toFixed(1).replace(/\.0$/, '')} K`;
  }
  return `${sign}₹ ${Math.round(abs)}`;
};

export const formatNumber = (num) => {
  return new Intl.NumberFormat('en-IN').format(Number(num) || 0);
};

export const formatDate = (dateInput) => {
  if (!dateInput) return '';
  const date = new Date(dateInput);
  if (Number.isNaN(date.getTime())) return '';
  return date.toLocaleString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  });
};

export const formatShortDate = (dateInput) => {
  if (!dateInput) return '';
  const date = new Date(dateInput);
  if (Number.isNaN(date.getTime())) return '';
  return date.toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
  });
};
