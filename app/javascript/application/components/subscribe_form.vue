<template>
  <VForm
    v-if="!isSubmitted && !submittedEmail"
    ref="form"
    :model="value"
    :rules="rules"
    @keyup.enter="handleSubmit"
  >
    <div class="row">
      <div class="col-12 mb-3 text-center">
        {{ t('settings.subscribePage.description') }}
      </div>
      <FormItem
        prop="email"
        class="col-12"
      >
        <VInput
          v-model="value.email"
          prefix="md-mail"
          type="email"
          name="email"
          :disabled="isSubmitted"
          size="large"
          :placeholder="t('settings.subscribePage.emailPlaceholder')"
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
    <Spin
      v-if="isLoading"
      size="large"
      fix
    />
  </VForm>
  <div v-else>
    <Icon
      type="md-checkmark-circle text-success"
    />
    {{ submittedEmail ? t('settings.subscribePage.subscribedMessageWithEmail', '', { email: submittedEmail }) : t('settings.subscribePage.subscribedMessage') }}
  </div>
</template>

<script>
import axios from 'axios'
import localeMixin from 'application/scripts/locale_mixin'

export default {
  name: 'SubscribeForm',
  mixins: [localeMixin],
  props: {
    email: {
      type: String,
      required: false,
      default: ''
    },
    submitText: {
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['success', 'error'],
  // 保存订阅加载状态、提交状态和邮箱输入值。
  data () {
    return {
      isLoading: false,
      isSubmitted: false,
      value: { email: '' }
    }
  },
  computed: {
    // 计算订阅按钮文案。
    displaySubmitText () {
      return this.submitText || this.t('settings.subscribePage.submit')
    },
    // 返回邮箱表单校验规则。
    rules () {
      return {
        email: [{ required: true, type: 'email' }]
      }
    },
    // 从 localStorage 读取已订阅邮箱，用于避免重复展示表单。
    submittedEmail () {
      if (window.localStorage) {
        return JSON.parse(window.localStorage.getItem('newsletter') || '{}').email
      } else {
        return ''
      }
    }
  },
  watch: {
    // 外部邮箱变化时填入表单。
    email (value) {
      if (value) {
        this.value.email = value
      }
    }
  },
  // 初始化邮箱输入值。
  mounted () {
    this.value.email = this.email
  },
  methods: {
    // 调用 Motor 官网订阅接口并记录本地订阅状态。
    submit () {
      this.isLoading = true

      axios.post('https://app.getmotoradmin.com/api/subscribe', {
        email: this.value.email
      }).then((result) => {
        localStorage.setItem('newsletter', JSON.stringify(result.data))
        localStorage.setItem('motor:current_user:is_subscribed', 'true')

        this.$emit('success', result.data.data)
      }).catch((error) => {
        this.$emit('error', error)
      }).finally(() => {
        this.isSubmitted = true
        this.isLoading = false
      })
    },
    // 表单校验通过后执行订阅。
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
