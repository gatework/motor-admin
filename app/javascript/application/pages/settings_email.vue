<template>
  <Card class="mb-3">
    <EmailForm
      :configs="configs"
      :submit-text="t('settings.emailPage.submitUpdate')"
      @success="showSuccessMessage"
      @error="showErrorMessage"
    />
  </Card>
  <Spin
    v-if="!isLoaded"
    fix
  />
</template>

<script>
import api from 'application/api'
import EmailForm from 'application/components/email_form'
import { errorMessage } from 'application/scripts/error_messages'
import localeMixin from 'application/scripts/locale_mixin'

// 邮件设置页：加载已保存的 SMTP 配置，并承接表单保存结果提示。
export default {
  name: 'EmailSettingsPage',
  components: {
    EmailForm
  },
  mixins: [localeMixin],
  // 保存加载状态和 SMTP 配置。
  data () {
    return {
      isLoaded: false,
      configs: {}
    }
  },
  // 首次进入页面时加载邮件配置。
  mounted () {
    this.loadConfigs().finally(() => {
      this.isLoaded = true
    })
  },
  methods: {
    // 从后端读取 SMTP 加密配置。
    loadConfigs () {
      return api.get('encrypted_configs/email.smtp').then((result) => {
        this.configs = result.data.data.value || {}
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
    // 保存成功时展示提示。
    showSuccessMessage () {
      this.$Message.info(this.t('settings.emailPage.updatedSuccess'))
    },
    // 展示统一 API 错误消息。
    showErrorMessage (error) {
      this.$Message.error(errorMessage(error))
    }
  }
}
</script>
