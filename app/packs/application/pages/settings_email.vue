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

export default {
  name: 'EmailSettingsPage',
  components: {
    EmailForm
  },
  mixins: [localeMixin],
  data () {
    return {
      isLoaded: false,
      configs: {}
    }
  },
  mounted () {
    this.loadConfigs().finally(() => {
      this.isLoaded = true
    })
  },
  methods: {
    loadConfigs () {
      return api.get('encrypted_configs/email.smtp').then((result) => {
        this.configs = result.data.data.value || {}
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
    showSuccessMessage () {
      this.$Message.info(this.t('settings.emailPage.updatedSuccess'))
    },
    showErrorMessage (error) {
      this.$Message.error(errorMessage(error))
    }
  }
}
</script>
