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
  data () {
    return {
      isLoading: false
    }
  },
  computed: {
    rules () {
      return {
        access_key_id: [{ required: true }],
        secret_access_key: [{ required: true }],
        region: [{ required: true }],
        bucket: [{ required: true }]
      }
    },
    displaySubmitText () {
      return this.t('settings.storagePage.updateSubmit')
    }
  },
  methods: {
    submit () {
      this.isLoading = true

      api.post('encrypted_configs', {
        data: {
          key: 'files.storage',
          value: {
            service: 'aws_s3',
            configs: this.configs
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
