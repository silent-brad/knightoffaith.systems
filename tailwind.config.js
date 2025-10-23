/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./templates/**/*.html",
    "./posts/**/*.typ",
    "./*.html"
  ],
  theme: {
    extend: {},
  },
  plugins: [],
  corePlugins: {
    // Enable all core plugins since we're not using Pico.css
    preflight: true,
  }
}
