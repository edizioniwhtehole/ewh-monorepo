/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        status: {
          grey: '#9CA3AF',
          red: '#EF4444',
          yellow: '#F59E0B',
          'green-light': '#10B981',
          'green-medium': '#059669',
          'green-dark': '#047857',
        },
      },
    },
  },
  plugins: [],
}
