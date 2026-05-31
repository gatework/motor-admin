<template>
  <Card class="mb-3">
    <RadioGroup
      v-model="configsValue.service"
      class="d-flex flex-column flex-md-row gap-3"
    >
      <Radio
        v-for="option in serviceOptions"
        :key="option.value"
        :label="option.value"
        border
        size="large"
        class="my-1 me-0 flex-fill"
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

// 文件存储设置页：加载当前存储服务，并按服务类型切换对应配置表单。
export default {
  name: 'StorageSettingsPage',
  components: {
    AwsS3Form,
    GcsForm
  },
  mixins: [localeMixin],
  // 保存加载状态和当前存储服务配置。
  data () {
    return {
      isLoaded: false,
      configsValue: { service: 'aws_s3', configs: {} }
    }
  },
  computed: {
    // 返回支持的存储服务选项。
    serviceOptions () {
      return [
        { label: this.t('settings.storagePage.labelAws'), value: 'aws_s3' },
        { label: this.t('settings.storagePage.labelGoogleCloud'), value: 'google' }
      ]
    }
  },
  // 首次进入页面时加载文件存储配置。
  mounted () {
    this.loadConfigs().finally(() => {
      this.isLoaded = true
    })
  },
  methods: {
    // 从后端读取文件存储加密配置。
    loadConfigs () {
      return api.get('encrypted_configs/files.storage').then((result) => {
        this.configsValue = result.data.data.value || { service: 'aws_s3', configs: {} }
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
    // 保存成功时展示提示。
    showSuccessMessage () {
      this.$Message.info(this.t('settings.storagePage.updatedSuccess'))
    },
    // 展示统一 API 错误消息。
    showErrorMessage (error) {
      this.$Message.error(errorMessage(error))
    }
  }
}
</script>
