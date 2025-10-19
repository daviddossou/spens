// Tailwind CSS configuration for the Spens application
//
// ARCHITECTURE NOTE:
// This project uses a CSS-first approach with custom properties defined in variables.css
// Tailwind is used minimally for utility classes. Most styling is done through
// component-specific CSS classes (e.g., .btn, .switcher, .card, etc.)
//
// The theme extension below allows Tailwind utilities to reference our CSS variables
// when needed (e.g., text-primary, bg-success, border-danger)

module.exports = {
  content: [
    "./app/views/**/*.{erb,html,html+erb}",
    "./app/components/**/*.{erb,rb}",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.{js,ts,jsx,tsx}",
    "./app/assets/stylesheets/**/*.{css,scss}"
  ],
  safelist: [
    // Explicitly safelist utilities used in Ruby strings
    'cursor-pointer',
    'cursor-not-allowed'
  ],
  theme: {
    extend: {
      colors: {
        // Primary color palette
        primary: {
          DEFAULT: 'var(--color-primary)',
          50: 'var(--color-primary-50)',
          20: 'var(--color-primary-20)',
          dark: 'var(--color-primary-dark)'
        },

        // Secondary color palette
        secondary: {
          DEFAULT: 'var(--color-secondary)',
          50: 'var(--color-secondary-50)',
          20: 'var(--color-secondary-20)',
          dark: 'var(--color-secondary-dark)'
        },

        // Semantic colors
        success: {
          DEFAULT: 'var(--color-success)',
          50: 'var(--color-success-50)',
          20: 'var(--color-success-20)',
          dark: 'var(--color-success-dark)'
        },
        danger: {
          DEFAULT: 'var(--color-danger)',
          50: 'var(--color-danger-50)',
          20: 'var(--color-danger-20)',
          dark: 'var(--color-danger-dark)'
        },
        warning: {
          DEFAULT: 'var(--color-warning)',
          50: 'var(--color-warning-50)',
          20: 'var(--color-warning-20)',
          dark: 'var(--color-warning-dark)'
        },
        info: {
          DEFAULT: 'var(--color-info)',
          50: 'var(--color-info-50)',
          20: 'var(--color-info-20)'
        },

        // Base colors
        'off-white': 'var(--color-off-white)',
        'dark-gray': 'var(--color-dark-gray)',
        'slate-gray': 'var(--color-slate-gray)',
        'light-gray': 'var(--color-light-gray)',

        // Additional brand colors
        'steel-blue': 'var(--color-steel-blue)',
        'emerald-green': 'var(--color-emerald-green)',
        'royal-purple': 'var(--color-royal-purple)',
        'charcoal-black': 'var(--color-charcoal-black)',
        'deep-indigo': 'var(--color-deep-indigo)',
        'olive-gold': 'var(--color-olive-gold)',
        'crimson-red': 'var(--color-crimson-red)',
        'golden-brown': 'var(--color-golden-brown)',

        // Tint colors for cards and backgrounds
        'soft-blue': 'var(--color-soft-blue)',
        'sky-blue': 'var(--color-sky-blue)',
        'mint-green': 'var(--color-mint-green)',
        'lavender-gray': 'var(--color-lavender-gray)',
        'light-purple': 'var(--color-light-purple)',
        'warm-beige': 'var(--color-warm-beige)',
        'pale-gold': 'var(--color-pale-gold)',
        'rose-pink': 'var(--color-rose-pink)'
      },

      // Add other theme extensions as needed
      borderColor: {
        DEFAULT: 'var(--border-default)'
      },

      ringColor: {
        DEFAULT: 'var(--focus-ring)'
      }
    }
  },
  plugins: []
};
