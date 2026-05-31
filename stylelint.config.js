module.exports = {
  extends: ['stylelint-config-sass-guidelines'],
  plugins: ['stylelint-scss'],
  rules: {
    'max-nesting-depth': 8,
    'selector-max-compound-selectors': 4,
    'selector-no-qualifying-type': null,
    'property-no-vendor-prefix': null,
    'selector-no-vendor-prefix': null,
    'scss/dollar-variable-pattern': null,
    'selector-max-id': null,
    'scss/at-extend-no-missing-placeholder': null
  }
}
