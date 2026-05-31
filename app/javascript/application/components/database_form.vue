<template>
  <VForm
    ref="form"
    :model="dataConfigs"
    :rules="rules"
    @keyup.enter="handleSubmit"
  >
    <FormItem
      v-if="withName"
      prop="name"
      :label="t('settings.databasePage.nameLabel')"
      class="col-12"
    >
      <VInput
        v-model="dataConfigs.name"
        type="text"
        :placeholder="t('settings.databasePage.namePlaceholder')"
      />
    </FormItem>
    <FormItem
      prop="url"
      :label="t('settings.databasePage.urlLabel')"
      class="col-12"
    >
      <VInput
        v-model="dataConfigs.url"
        type="text"
        size="large"
        :placeholder="t('settings.databasePage.urlPlaceholder')"
        @update:model-value="assignFields"
      />
    </FormItem>
    <Divider />
    <RadioGroup
      v-model="dataConfigs.protocol"
      class="d-flex flex-column flex-md-row gap-3"
      @update:model-value="assignUrl"
    >
      <Radio
        v-for="option in dbTypeOptions"
        :key="option.value"
        :label="option.value"
        border
        size="large"
        class="my-1 me-0 flex-fill"
      >
        {{ option.label }}
      </Radio>
    </RadioGroup>
    <div class="row">
      <FormItem
        prop="host"
        :label="t('settings.databasePage.hostLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="dataConfigs.host"
          type="text"
          :placeholder="t('settings.databasePage.hostPlaceholder')"
          @update:model-value="assignUrl"
        />
        <small v-if="isError && ['localhost', '0.0.0.0', '127.0.0.1'].includes(dataConfigs.host)">
          <span v-html="t('settings.databasePage.dockerHostHint')" />
        </small>
      </FormItem>
      <FormItem
        prop="port"
        :label="t('settings.databasePage.portLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="dataConfigs.port"
          type="text"
          :placeholder="t('settings.databasePage.portPlaceholder')"
          @update:model-value="assignUrl"
        />
      </FormItem>
      <FormItem
        prop="username"
        :label="t('settings.databasePage.usernameLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="dataConfigs.username"
          type="text"
          :placeholder="t('settings.databasePage.usernamePlaceholder')"
          @update:model-value="assignUrl"
        />
      </FormItem>
      <FormItem
        prop="password"
        :label="t('settings.databasePage.passwordLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="dataConfigs.password"
          type="password"
          :placeholder="t('settings.databasePage.passwordPlaceholder')"
          @update:model-value="assignUrl"
        />
      </FormItem>
      <FormItem
        prop="database"
        :label="t('settings.databasePage.databaseLabel')"
        class="col-12"
      >
        <VInput
          v-model="dataConfigs.database"
          :placeholder="t('settings.databasePage.databasePlaceholder')"
          @update:model-value="assignUrl"
        />
      </FormItem>
      <FormItem
        v-if="dataConfigs.protocol === 'postgres'"
        prop="schema_search_path"
        :label="t('settings.databasePage.schemaLabel')"
        class="col-12"
      >
        <VInput
          v-model="dataConfigs.schema_search_path"
          :placeholder="t('settings.databasePage.schemaPlaceholder')"
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
import { databaseObjectToUrl, databaseUrlToObject, normalizeProtocol } from 'application/scripts/urls'
import localeMixin from 'application/scripts/locale_mixin'

// 数据库配置表单：先验证连接，再保存标准化后的加密数据库配置。
export default {
  name: 'DatabaseForm',
  mixins: [localeMixin],
  props: {
    configs: {
      type: Object,
      required: false,
      default: () => ({ protocol: 'postgres' })
    },
    isDefaultSetup: {
      type: Boolean,
      required: false,
      default: false
    },
    withName: {
      type: Boolean,
      required: false,
      default: false
    },
    submitText: {
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['success', 'error', 'submit'],
  // 保存连接校验错误、加载状态和当前表单数据。
  data () {
    return {
      isError: false,
      isLoading: false,
      dataConfigs: {}
    }
  },
  computed: {
    // 计算提交按钮文案。
    displaySubmitText () {
      return this.submitText || this.t('settings.common.submit')
    },
    // 返回数据库表单校验规则。
    rules () {
      return {
        name: [{
          required: this.withName,
          min: 3,
          max: 10
        }],
        url: [{ required: true }],
        host: [{ required: true }],
        port: [{ required: true }]
      }
    },
    // 返回支持的数据库类型选项。
    dbTypeOptions () {
      return [
        { label: this.t('settings.databasePage.dbTypePostgreSQL'), value: 'postgres' },
        { label: this.t('settings.databasePage.dbTypeMySQL'), value: 'mysql2' },
        { label: this.t('settings.databasePage.dbTypeSqlServer'), value: 'sqlserver' }
      ]
    }
  },
  watch: {
    // 外部配置变化时重置表单并重新拆分 URL 字段。
    configs () {
      this.dataConfigs = { ...this.configs }

      this.assignFields()
    }
  },
  // 初始化表单数据并从 URL 反填字段。
  mounted () {
    this.dataConfigs = { ...this.configs }

    this.assignFields()
  },
  methods: {
    // 从 URL 字段反向填充协议、账号、主机、端口和库名。
    assignFields () {
      if ('url' in this.dataConfigs) {
        Object.assign(this.dataConfigs, databaseUrlToObject(this.dataConfigs.url))
      }
    },
    // 根据表单字段重新组装数据库 URL。
    assignUrl () {
      this.dataConfigs.url = databaseObjectToUrl(this.dataConfigs)
    },
    // 先验证连接，默认初始化模式直接保存，普通模式交给父组件合并配置。
    submit () {
      this.isLoading = true
      this.isError = false

      api.post('verify_db_connection', this.connectionVerificationParams()).then(() => {
        if (this.isDefaultSetup) {
          this.submitDefault()
        } else {
          const dbConfig = this.normalizedDatabaseConfig(this.dataConfigs.name)

          this.$emit('submit', dbConfig)

          this.isLoading = false
        }
      }).catch((error) => {
        this.applyError(error)

        this.isError = true
        this.isLoading = false
      })
    },
    // 生成连接验证 API 的请求参数。
    connectionVerificationParams () {
      const params = {
        url: this.normalizedDatabaseUrl(this.dataConfigs.url)
      }
      const schemaSearchPath = this.dataConfigs.schema_search_path?.trim()

      if (schemaSearchPath) {
        params.schema_search_path = schemaSearchPath
      }

      return params
    },
    // 初始化流程下直接保存 default 数据库配置。
    submitDefault () {
      api.post('encrypted_configs', {
        data: {
          key: 'database.credentials',
          value: [
            this.normalizedDatabaseConfig('default')
          ]
        }
      }).then((result) => {
        this.$emit('success', result.data.data)
      }).catch((error) => {
        this.applyError(error)
      }).finally(() => {
        this.isLoading = false
      })
    },
    // 生成后端保存所需的单条数据库配置。
    normalizedDatabaseConfig (name) {
      const dbConfig = {
        name,
        url: this.normalizedDatabaseUrl(this.dataConfigs.url)
      }
      const schemaSearchPath = this.dataConfigs.schema_search_path?.trim()

      if (schemaSearchPath) {
        dbConfig.schema_search_path = schemaSearchPath
      }

      return dbConfig
    },
    // 只规范化 URL 协议名，保留后半段已编码内容。
    normalizedDatabaseUrl (url) {
      const [protocol, rest] = url.split('://')

      if (!rest) return url

      return `${normalizeProtocol(protocol)}://${rest}`
    },
    // 将后端错误写入表单并向父组件透传。
    applyError (error) {
      if (error.response?.data?.errors) {
        this.$refs.form.setErrors(error.response.data.errors)
      } else if (error.message) {
        this.$refs.form.setErrors([error.message])
      }

      this.$emit('error', error)
    },
    // 表单校验通过后执行提交。
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
