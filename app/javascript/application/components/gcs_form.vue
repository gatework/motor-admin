<template>
  <VForm
    ref="form"
    :model="configs"
    :rules="rules"
    @keyup.enter="handleSubmit"
  >
    <div class="row">
      <FormItem
        prop="project"
        :label="t('settings.storagePage.gcsProjectLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="configs.project"
          type="text"
          :placeholder="t('settings.storagePage.gcsProjectPlaceholder')"
        />
      </FormItem>
      <FormItem
        prop="bucket"
        :label="t('settings.storagePage.gcsBucketLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="configs.bucket"
          type="text"
          :placeholder="t('settings.storagePage.gcsBucketPlaceholder')"
        />
      </FormItem>
      <FormItem
        prop="credentials"
        :label="t('settings.storagePage.gcsCredentialsLabel')"
        class="col-12"
      >
        <VInput
          v-model="configs.credentials"
          type="textarea"
          :autosize="{ minRows: 4, maxRows: 7 }"
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

// Google Cloud Storage 表单：保存项目、存储桶和 JSON 凭据配置。
export default {
  name: 'GcsForm',
  mixins: [localeMixin],
  props: {
    configs: {
      type: Object,
      required: true
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
    // 返回 GCS 必填字段校验规则。
    rules () {
      return {
        credentials: [{ required: true }],
        project: [{ required: true }],
        bucket: [{ required: true }]
      }
    },
    // 返回本地化提交按钮文案。
    displaySubmitText () {
      return this.t('settings.storagePage.updateSubmit')
    }
  },
  methods: {
    // 提交 Google Cloud Storage 加密配置。
    submit () {
      this.isLoading = true

      api.post('encrypted_configs', {
        data: {
          key: 'files.storage',
          value: {
            service: 'google',
            configs: this.normalizedConfigs()
          }
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
    // 输出清理过空白的 GCS 配置。
    normalizedConfigs () {
      return {
        bucket: this.cleanedValue('bucket'),
        credentials: this.cleanedValue('credentials'),
        project: this.cleanedValue('project')
      }
    },
    // 读取字段并去除首尾空白。
    cleanedValue (key) {
      return this.configs[key]?.toString().trim() || ''
    }
  }
}
</script>
