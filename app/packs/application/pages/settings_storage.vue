<template>
  <Card class="mb-3">
    <RadioGroup
      v-model="configsValue.service"
      class="d-flex"
    >
      <Radio
        v-for="(option, index) in serviceOptions"
        :key="option.value"
        :label="option.value"
        border
        size="large"
        :style="index !== 0 ? 'margin-left: 15px !important' : ''"
        class="my-1 me-0 w-100"
      >
        {{ option.label }}
      </Radio>
    </RadioGroup>
    <Divider class="mb-3" />
    <AwsS3Form
      v-if="configsValue.service === 'aws_s3'"
      :configs="configsValue.configs"
      @success="showSuccessMessage"
      @error="showErrorMessage"
    />
    <GcsForm
      v-if="configsValue.service === 'google'"
      :configs="configsValue.configs"
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
import AwsS3Form from 'application/components/aws_s3_form'
import GcsForm from 'application/components/gcs_form'
import { errorMessage } from 'application/scripts/error_messages'
import localeMixin from 'application/scripts/locale_mixin'

export default {
  name: 'StorageSettingsPage',
  components: {
    AwsS3Form,
    GcsForm
  },
  mixins: [localeMixin],
  data () {
    return {
      isLoaded: false,
      configsValue: { service: 'aws_s3', configs: {} }
    }
  },
  computed: {
    serviceOptions () {
      return [
        { label: this.t('settings.storagePage.labelAws'), value: 'aws_s3' },
        { label: this.t('settings.storagePage.labelGoogleCloud'), value: 'google' }
      ]
    }
  },
  mounted () {
    this.loadConfigs().finally(() => {
      this.isLoaded = true
    })
  },
  methods: {
    loadConfigs () {
      return api.get('encrypted_configs/files.storage').then((result) => {
        this.configsValue = result.data.data.value || { service: 'aws_s3', configs: {} }
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
    showSuccessMessage () {
      this.$Message.info(this.t('settings.storagePage.updatedSuccess'))
    },
    showErrorMessage (error) {
      this.$Message.error(errorMessage(error))
    }
  }
}
</script>
