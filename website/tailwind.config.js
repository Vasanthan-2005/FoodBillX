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
        background: '#030408',
        surface: '#0B0D14',
        cardBackground: '#10131E',
        surfaceBorder: 'rgba(255, 255, 255, 0.08)',
        primary: {
          DEFAULT: '#FF6D00',
          hover: '#FF8F00',
          light: 'rgba(255, 109, 0, 0.16)',
        },
        secondary: {
          DEFAULT: '#00E676',
          light: 'rgba(0, 230, 118, 0.15)',
        },
        cyber: {
          cyan: '#22D3EE',
          purple: '#A855F7',
          amber: '#FFB300',
          rose: '#FB7185',
        },
      },
      fontFamily: {
        sans: ['Outfit', 'system-ui', '-apple-system', 'sans-serif'],
        display: ['Space Grotesk', 'Outfit', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      boxShadow: {
        glass: '0 12px 40px 0 rgba(0, 0, 0, 0.55)',
        glow: '0 0 28px rgba(255, 109, 0, 0.32)',
        cyanGlow: '0 0 24px rgba(34, 211, 238, 0.25)',
      },
    },
  },
  plugins: [],
};
