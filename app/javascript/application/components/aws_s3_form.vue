<template>
  <VForm
    ref="form"
    :model="configs"
    :rules="rules"
    @keyup.enter="handleSubmit"
  >
    <div class="row">
      <FormItem
        prop="access_key_id"
        :label="t('settings.storagePage.awsAccessKeyIdLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="configs.access_key_id"
          type="text"
        />
      </FormItem>
      <FormItem
        prop="secret_access_key"
        :label="t('settings.storagePage.awsSecretAccessKeyLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="configs.secret_access_key"
          type="password"
          :placeholder="t('settings.storagePage.awsSecretAccessKeyPlaceholder')"
        />
      </FormItem>
      <FormItem
        prop="region"
        :label="t('settings.storagePage.awsRegionLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="configs.region"
          type="text"
          :placeholder="t('settings.storagePage.awsRegionPlaceholder')"
        />
      </FormItem>
      <FormItem
        prop="bucket"
        :label="t('settings.storagePage.awsBucketLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="configs.bucket"
          :placeholder="t('settings.storagePage.awsBucketPlaceholder')"
        />
      </FormItem>
      <FormItem
        prop="endpoint"
        :label="t('settings.storagePage.awsEndpointLabel')"
        class="col-12"
      >
        <VInput
          v-model="configs.endpoint"
          type="text"
          :placeholder="t('settings.storagePage.awsEndpointPlaceholder')"
        />
        <small>{{ t('settings.storagePage.awsEndpointHint') }}</small>
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

// AWS S3 存储表单：保存对象存储凭据，并剔除空的可选 endpoint。
export default {
  name: 'AwsS3Form',
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
    // 返回 AWS S3 必填字段校验规则。
    rules () {
      return {
        access_key_id: [{ required: true }],
        secret_access_key: [{ required: true }],
        region: [{ required: true }],
        bucket: [{ required: true }]
      }
    },
    // 返回本地化提交按钮文案。
    displaySubmitText () {
      return this.t('settings.storagePage.updateSubmit')
    }
  },
  methods: {
    // 提交 AWS S3 存储加密配置。
    submit () {
      this.isLoading = true

      api.post('encrypted_configs', {
        data: {
          key: 'files.storage',
          value: {
            service: 'aws_s3',
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
    // 输出标准化后的 S3 配置，endpoint 为空时不保存。
    normalizedConfigs () {
      const configs = {
        access_key_id: this.cleanedValue('access_key_id'),
        secret_access_key: this.cleanedValue('secret_access_key'),
        region: this.cleanedValue('region'),
        bucket: this.cleanedValue('bucket')
      }
      const endpoint = this.cleanedValue('endpoint')

      if (endpoint) {
        configs.endpoint = endpoint
      }

      return configs
    },
    // 读取字段并去除首尾空白。
    cleanedValue (key) {
      return this.configs[key]?.toString().trim() || ''
    }
  }
}
</script>
