<template>
  <Card class="mb-3 other-settings-card">
    <div class="d-flex align-items-center mt-2">
      {{ t('settings.languageSelectLabel') }}
      <select
        v-model="locale"
        size="1"
        class="ms-2"
        @change="changeLanguage"
      >
        <option value="en">
          {{ t('settings.languageOptions.en') }}
        </option>
        <option value="es">
          {{ t('settings.languageOptions.es') }}
        </option>
        <option value="el">
          {{ t('settings.languageOptions.el') }}
        </option>
        <option value="zh-CN">
          {{ t('settings.languageOptions.zh-CN') }}
        </option>
      </select>
    </div>
    <Divider />
    <div class="align-items-center mb-2">
      <VForm>
        <FormItem
          prop="token"
          :label="t('settings.otherPage.slackToken')"
          class="col-12 mb-2"
        >
          <VInput
            v-model="slackApiKey"
            type="text"
            :placeholder="t('settings.otherPage.slackTokenPlaceholder')"
          />
        </FormItem>
        <a
          href="https://my.slack.com/services/new/bot"
          target="_blank"
        >{{ t('settings.otherPage.createSlackBotHere') }}</a>
        <VButton
          type="primary"
          class="mt-3"
          size="large"
          long
          @click="setSlackToken"
        >
          {{ t('settings.otherPage.submit') }}
        </VButton>
      </VForm>
    </div>
    <Divider />
    <div class="align-items-center mb-2">
      <VForm>
        <FormItem
          prop="html"
          :label="t('settings.otherPage.trackingScript')"
          class="col-12 mb-2"
        >
          <VInput
            v-model="configs['ui.custom_html']"
            type="textarea"
            :placeholder="t('settings.otherPage.trackingScriptPlaceholder')"
            :autosize="{ minRows: 4, maxRows: 7 }"
          />
        </FormItem>
        <VButton
          type="primary"
          class="mt-3"
          size="large"
          long
          @click="setCustomHtml(configs['ui.custom_html'])"
        >
          {{ t('settings.otherPage.submit') }}
        </VButton>
      </VForm>
    </div>
    <Spin
      v-if="isLoading"
      fix
    />
  </Card>
</template>

<script>
import api from 'application/api'
import { errorMessage } from 'application/scripts/error_messages'
import localeMixin from 'application/scripts/locale_mixin'

// 其他设置页：维护语言、Slack 凭据和自定义 HTML 等辅助配置。
export default {
  name: 'OtherSettingsPage',
  mixins: [localeMixin],
  // 保存加载状态、Slack token 和普通配置表。
  data () {
    return {
      isLoading: false,
      slackApiKey: '',
      configs: {}
    }
  },
  // 并行加载普通配置和 Slack 加密配置。
  mounted () {
    this.isLoading = true

    Promise.all([
      this.loadSlackCredentials(),
      this.loadConfigs()
    ]).finally(() => {
      this.isLoading = false
    })
  },
  methods: {
    // 保存语言配置，更新 DOM lang 并广播语言变更事件。
    changeLanguage (event) {
      const nextLocale = event.target.value

      api.post('configs', {
        data: {
          key: 'language',
          value: nextLocale
        }
      }).then(() => {
        this.locale = nextLocale
        document.documentElement.setAttribute('lang', nextLocale)
        window.dispatchEvent(new Event('motor:locale-changed'))
        this.$Message.info(this.t('settings.otherPage.languageChanged'))
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
    // 保存自定义 HTML/追踪脚本配置。
    setCustomHtml (value) {
      api.post('configs', {
        data: {
          key: 'ui.custom_html',
          value: value
        }
      }).then(() => {
        this.$Message.info(this.t('settings.otherPage.changesSaved'))
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
    // 保存 Slack Bot token 到加密配置。
    setSlackToken () {
      api.post('encrypted_configs', {
        data: {
          key: 'slack.credentials',
          value: { api_key: this.slackApiKey }
        }
      }).then(() => {
        this.$Message.info(this.t('settings.otherPage.credentialsSaved'))
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
    // 加载普通 Motor 配置并转换为 key-value 对象。
    loadConfigs () {
      return api.get('configs').then((result) => {
        this.configs = result.data.data.reduce((acc, conf) => {
          acc[conf.key] = conf.value

          return acc
        }, {})
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
    // 加载 Slack 加密配置，缺失时保持空值。
    loadSlackCredentials () {
      return api.get('encrypted_configs/slack.credentials').then((result) => {
        this.slackApiKey = result.data.data.value?.api_key || ''
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
    // 展示统一 API 错误消息。
    showErrorMessage (error) {
      this.$Message.error(errorMessage(error))
    }
  }
}
</script>

<style lang="scss" scoped>
.other-settings-card {
  line-height: normal;
}
</style>
