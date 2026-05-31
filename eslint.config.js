const js = require('@eslint/js')
const vue = require('eslint-plugin-vue')
const globals = require('globals')

module.exports = [
  {
    ignores: [
      'node_modules/**',
      'public/**',
      'tmp/**',
      'vendor/**'
    ]
  },
  js.configs.recommended,
  ...vue.configs['flat/recommended'],
  {
    files: ['app/packs/**/*.{js,vue}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.browser,
        ...globals.es2024
      }
    },
    rules: {
      'no-unused-vars': ['error', { argsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' }],
      'vue/multi-word-component-names': 'off',
      'vue/no-reserved-component-names': 'off',
      'vue/no-mutating-props': 'off',
      'vue/no-required-prop-with-default': 'off',
      'vue/no-v-html': 'off',
      'vue/v-on-event-hyphenation': 'off'
    }
  }
]
