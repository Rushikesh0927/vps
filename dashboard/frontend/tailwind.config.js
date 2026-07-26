/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        bg: {
          DEFAULT: '#0e0e10',
          deep:    '#0a0a0c',
        },
        surface: {
          DEFAULT: '#18181b',
          up:      '#212124',
          soft:    '#141416',
        },
        border: {
          DEFAULT: '#2a2a2e',
          up:      '#3d3d42',
        },
        text: {
          DEFAULT: '#f2f1ee',
          muted:   '#a09fa6',
          dim:     '#6b6a72',
        },
        accent: {
          DEFAULT: '#f47c48',
          soft:    'rgba(244,124,72,0.10)',
        },
        green: {
          DEFAULT: '#56c996',
          soft:    'rgba(86,201,150,0.10)',
        },
        amber: {
          DEFAULT: '#e8b35f',
          soft:    'rgba(232,179,95,0.10)',
        },
        red: {
          DEFAULT: '#ee7777',
          soft:    'rgba(238,119,119,0.10)',
        },
      },
      fontFamily: {
        sans: ['DM Sans', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      boxShadow: {
        sm: '0 2px 8px rgba(0,0,0,0.20)',
        md: '0 8px 24px rgba(0,0,0,0.28)',
        lg: '0 20px 48px rgba(0,0,0,0.38)',
      },
      borderRadius: {
        DEFAULT: '8px',
        sm: '6px',
        md: '10px',
        lg: '14px',
        xl: '18px',
      },
    },
  },
  plugins: [],
};
