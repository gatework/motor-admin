<template>
  <VForm
    ref="form"
    :model="configs"
    :rules="rules"
    @keyup.enter="handleSubmit"
  >
    <div class="row">
      <FormItem
        prop="host"
        :label="t('settings.emailPage.hostLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="configs.host"
          type="text"
          :placeholder="t('settings.emailPage.hostPlaceholder')"
        />
      </FormItem>
      <FormItem
        prop="port"
        :label="t('settings.emailPage.portLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="configs.port"
          type="text"
          :placeholder="t('settings.emailPage.portPlaceholder')"
        />
      </FormItem>
      <FormItem
        prop="username"
        :label="t('settings.emailPage.usernameLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="configs.username"
          type="text"
          :placeholder="t('settings.emailPage.usernamePlaceholder')"
        />
      </FormItem>
      <FormItem
        prop="password"
        :label="t('settings.emailPage.passwordLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="configs.password"
          type="password"
          :placeholder="t('settings.emailPage.passwordPlaceholder')"
        />
      </FormItem>
      <FormItem
        prop="address"
        :label="t('settings.emailPage.addressLabel')"
        class="col-12"
      >
        <VInput
          v-model="configs.address"
          :placeholder="t('settings.emailPage.addressPlaceholder')"
        />
      </FormItem>
    </div>
    <VButton
      type="primary"
      class="mt-1"
      size="large"
      long
      @click="handleSubmit"
    >
      {{ displaySubmitText }}
    </VButton>
  </VForm>
</template>

<script>
import api from 'application/api'
import localeMixin from 'application/scripts/locale_mixin'

export default {
  name: 'EmailForm',
  mixins: [localeMixin],
  props: {
    configs: {
      type: Object,
      required: true
    },
    submitText: {
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['success', 'error'],
  data () {
    return {
      isLoading: false
    }
  },
  computed: {
    displaySubmitText () {
      return this.submitText || this.t('settings.emailPage.submitUpdate')
    },
    rules () {
      return {
        host: [{ required: true }],
        port: [{ required: true }],
        username: [{ required: true }],
        password: [{ required: true }],
        address: [{ required: true }]
      }
    }
  },
  methods: {
    submit () {
      this.isLoading = true

      api.post('encrypted_configs', {
        data: {
          key: 'email.smtp',
          value: this.configs
        }
      }).then((result) => {
        this.$emit('success', result.data.data)
      }).catch((error) => {
        this.$emit('error', error)
      }).finally(() => {
        this.isLoading = false
      })
    },
    handleSubmit () {
      this.$refs.form.validate((valid) => {
        if (valid) {
          this.submit()
        }
      })
    }
  }
}
</script>
