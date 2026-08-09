/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        background: '#0F172A',
        surface: '#1E293B',
        surfaceBorder: 'rgba(255, 255, 255, 0.08)',
        cardBackground: '#1E293B',
        primary: {
          DEFAULT: '#FF5722',
          hover: '#F4511E',
          light: 'rgba(255, 87, 34, 0.15)',
        },
        secondary: {
          DEFAULT: '#10B981',
          light: 'rgba(16, 185, 129, 0.15)',
        },
        accent: {
          blue: '#3B82F6',
          purple: '#8B5CF6',
          amber: '#F59E0B',
          rose: '#F43F5E',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      boxShadow: {
        glass: '0 8px 32px 0 rgba(0, 0, 0, 0.37)',
        glow: '0 0 20px rgba(255, 87, 34, 0.25)',
      },
    },
  },
  plugins: [],
};
