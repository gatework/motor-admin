import { getMessage, localeFromDom } from 'application/scripts/i18n'

export default {
  data () {
    return {
      locale: localeFromDom()
    }
  },
  created () {
    this._updateLocale = this._updateLocale || (() => {
      this.locale = localeFromDom()
    })

    window.addEventListener('motor:locale-changed', this._updateLocale)
  },
  beforeUnmount () {
    window.removeEventListener('motor:locale-changed', this._updateLocale)
  },
  methods: {
    t (key, fallback = '', replacements = {}) {
      return getMessage(this.locale, key, fallback, replacements)
    },
    _updateLocale () {
      this.locale = localeFromDom()
    }
  }
}
