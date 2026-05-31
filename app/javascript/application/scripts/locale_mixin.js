import { getMessage, localeFromDom } from 'application/scripts/i18n'

// 本地化 mixin：组件通过 t() 读取当前语言，并响应语言切换事件。
export default {
  // 保存当前组件使用的 locale。
  data () {
    return {
      locale: localeFromDom()
    }
  },
  // 监听全局语言变更事件。
  created () {
    this._updateLocale = this._updateLocale || (() => {
      this.locale = localeFromDom()
    })

    window.addEventListener('motor:locale-changed', this._updateLocale)
  },
  // 组件销毁时移除语言变更监听。
  beforeUnmount () {
    window.removeEventListener('motor:locale-changed', this._updateLocale)
  },
  methods: {
    // 读取本地化文案并执行占位符替换。
    t (key, fallback = '', replacements = {}) {
      return getMessage(this.locale, key, fallback, replacements)
    },
    // 从 DOM 重新同步当前 locale。
    _updateLocale () {
      this.locale = localeFromDom()
    }
  }
}
