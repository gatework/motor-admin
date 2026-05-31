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
  name: 'GcsForm',
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
        credentials: [{ required: true }],
        project: [{ required: true }],
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
            service: 'google',
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
