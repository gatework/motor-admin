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
      class="d-flex"
      @update:model-value="assignUrl"
    >
      <Radio
        v-for="(option, index) in dbTypeOptions"
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
import { databaseUrlToObject } from 'application/scripts/urls'
import localeMixin from 'application/scripts/locale_mixin'

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
  data () {
    return {
      isError: false,
      isLoading: false,
      dataConfigs: {}
    }
  },
  computed: {
    displaySubmitText () {
      return this.submitText || this.t('settings.common.submit')
    },
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
    dbTypeOptions () {
      return [
        { label: this.t('settings.databasePage.dbTypePostgreSQL'), value: 'postgres' },
        { label: this.t('settings.databasePage.dbTypeMySQL'), value: 'mysql2' },
        { label: this.t('settings.databasePage.dbTypeSqlServer'), value: 'sqlserver' }
      ]
    }
  },
  watch: {
    configs () {
      this.dataConfigs = { ...this.configs }

      this.assignFields()
    }
  },
  mounted () {
    this.dataConfigs = { ...this.configs }

    this.assignFields()
  },
  methods: {
    assignFields () {
      if ('url' in this.dataConfigs) {
        Object.assign(this.dataConfigs, databaseUrlToObject(this.dataConfigs.url))
      }
    },
    assignUrl () {
      const { username, protocol, host, password, database, port } = this.dataConfigs

      if (host && port && database) {
        this.dataConfigs.url = `${protocol}://`

        if (username && !password) {
          this.dataConfigs.url += `${username}@`
        } else if (username && password) {
          this.dataConfigs.url += `${username}:${password}@`
        }

        this.dataConfigs.url += `${host}:${port}/${database}`
      }
    },
    submit () {
      this.isLoading = true

      api.post('verify_db_connection', {
        url: this.dataConfigs.url
      }).then(() => {
        if (this.isDefaultSetup) {
          this.submitDefault()
        } else {
          const dbConfig = { name: this.dataConfigs.name, url: this.dataConfigs.url.replace('mysql://', 'mysql2://').replace('postgresql://', 'postgres://') }

          if (this.dataConfigs.schema_search_path?.match(/\w/)) {
            dbConfig.schema_search_path = this.dataConfigs.schema_search_path
          }

          this.$emit('submit', dbConfig)

          this.isLoading = false
        }
      }).catch((error) => {
        if (error.response?.data?.errors) {
          this.$refs.form.setErrors(error.response.data.errors)
        } else if (error.message) {
          this.$refs.form.setErrors([error.message])
        }

        this.$emit('error', error)

        this.isError = true
        this.isLoading = false
      })
    },
    submitDefault () {
      api.post('encrypted_configs', {
        data: {
          key: 'database.credentials',
          value: [
            { name: 'default', url: this.dataConfigs.url, schema_search_path: this.dataConfigs.schema_search_path }
          ]
        }
      }).then((result) => {
        this.$emit('success', result.data.data)
      }).catch((error) => {
        if (error.response?.data?.errors) {
          this.$refs.form.setErrors(error.response.data.errors)
        } else if (error.message) {
          this.$refs.form.setErrors([error.message])
        }

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
