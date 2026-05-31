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
      :loading="isLoading"
      @click="handleSubmit"
    >
      {{ displaySubmitText }}
    </VButton>
    <Spin
      v-if="isLoading"
      fix
    />
  </VForm>
</template>

<script>
import api from 'application/api'
import localeMixin from 'application/scripts/locale_mixin'

// 邮件配置表单：维护 SMTP 参数，并在保存前清理输入空白。
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
  // 保存提交加载状态。
  data () {
    return {
      isLoading: false
    }
  },
  computed: {
    // 计算提交按钮文案。
    displaySubmitText () {
      return this.submitText || this.t('settings.emailPage.submitUpdate')
    },
    // 返回 SMTP 表单必填校验规则。
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
    // 提交 SMTP 加密配置到后端。
    submit () {
      this.isLoading = true

      api.post('encrypted_configs', {
        data: {
          key: 'email.smtp',
          value: this.normalizedConfigs()
        }
      }).then((result) => {
        this.$emit('success', result.data.data)
      }).catch((error) => {
        this.$emit('error', error)
      }).finally(() => {
        this.isLoading = false
      })
    },
    // 表单校验通过后执行提交。
    handleSubmit () {
      this.$refs.form.validate((valid) => {
        if (valid) {
          this.submit()
        }
      })
    },
    // 输出清理过空白的 SMTP 配置。
    normalizedConfigs () {
      return {
        address: this.cleanedValue('address'),
        host: this.cleanedValue('host'),
        port: this.cleanedValue('port'),
        username: this.cleanedValue('username'),
        password: this.cleanedValue('password')
      }
    },
    // 读取字段并去除首尾空白。
    cleanedValue (key) {
      return this.configs[key]?.toString().trim() || ''
    }
  }
}
</script>
