<template>
  <Card
    v-if="!configs.length"
    class="mb-3"
  >
    <DatabaseForm
      :submit-text="t('settings.databasePage.submitUpdate')"
      :is-default-setup="true"
      @success="handleInitialSuccess"
      @error="showErrorMessage"
    />
  </Card>
  <Card
    v-for="(config, index) in configs"
    :key="index"
    class="mb-3"
  >
    <div v-if="config.name !== 'default'">
      <div class="row">
        <div class="col fs-3 fw-bold">
          {{ config.name }}
        </div>
        <div class="col">
          <VButton
            type="error"
            class="float-end"
            ghost
            icon="md-trash"
            @click="remove(index)"
          >
            {{ t('settings.databasePage.remove') }}
          </VButton>
        </div>
      </div>
      <Divider class="mb-1 mt-3" />
    </div>
    <VForm
      v-if="!config.showFullForm"
      :model="config"
    >
      <FormItem
        prop="url"
        :label="t('settings.databasePage.urlLabel')"
        class="col-12 mb-2"
        :rules="[{required: true}]"
      >
        <VInput
          :model-value="maskedDatabaseUrl(config.url)"
          type="text"
          size="large"
          :placeholder="t('settings.databasePage.urlPlaceholder')"
        />
      </FormItem>
      <VButton
        icon="ios-arrow-down"
        type="text"
        long
        @click="config.showFullForm = true"
      >
        {{ t('settings.databasePage.expand') }}
      </VButton>
    </VForm>
    <DatabaseForm
      v-else
      :configs="config"
      :submit-text="t('settings.databasePage.submitUpdate')"
      @submit="handleUpdate"
      @error="showErrorMessage"
    />
  </Card>
  <VButton
    size="large"
    long
    type="dashed"
    class="mb-3"
    @click="openAddDatabaseModal"
  >
    <Icon type="md-add" />
    {{ t('settings.databasePage.addDatabase') }}
  </VButton>
  <Spin
    v-if="!isLoaded"
    fix
  />
</template>

<script>
import api from 'application/api'
import { errorMessage } from 'application/scripts/error_messages'
import localeMixin from 'application/scripts/locale_mixin'

import DatabaseForm from 'application/components/database_form'

// 数据库设置页：维护多数据库凭据列表，并统一持久化为加密配置。
export default {
  name: 'DatabaseSettingsPage',
  components: {
    DatabaseForm
  },
  mixins: [localeMixin],
  // 保存加载状态和数据库配置列表。
  data () {
    return {
      isLoaded: false,
      configs: []
    }
  },
  // 首次进入页面时加载数据库加密配置。
  mounted () {
    this.loadConfigs().then(() => {
      this.isLoaded = true
    })
  },
  methods: {
    // 从后端读取数据库凭据配置。
    loadConfigs () {
      return api.get('encrypted_configs/database.credentials').then((result) => {
        this.configs = result.data.data.value || []
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
    // 初始化默认数据库成功后刷新列表。
    handleInitialSuccess (config) {
      this.$Message.info(this.t('settings.databasePage.updatedSuccess'))

      this.configs = config.value || []
    },
    // 打开新增数据库弹窗，并在提交后合并保存。
    openAddDatabaseModal () {
      this.$Modal.open(DatabaseForm, {
        withName: true,
        submitText: this.t('settings.databasePage.submitCreate'),
        onSubmit: (data) => {
          this.handleUpdate(data, { rethrow: true }).then(() => {
            this.$Modal.remove()
          })
        }
      }, {
        title: this.t('settings.databasePage.createDatabase'),
        closable: true
      })
    },
    // 删除指定数据库配置并持久化剩余列表。
    remove (index) {
      this.$Dialog.confirm({
        title: this.t('settings.databasePage.areYouSure'),
        closable: true,
        onOk: () => {
          const dataConfigs = [...this.configs]

          dataConfigs.splice(index, 1)
          api.post('encrypted_configs', {
            data: {
              key: 'database.credentials',
              value: dataConfigs.map(this.databaseConfigPayload)
            }
          }).then((result) => {
            this.$Message.info(this.t('settings.databasePage.removed'))

            this.configs = result.data.data.value
          }).catch((error) => {
            this.showErrorMessage(error)
          })
        }
      })
    },
    // 新增或替换单条数据库配置后保存完整列表。
    handleUpdate (configs, options = {}) {
      const dataConfigs = [...this.configs]
      const index = dataConfigs.findIndex((c) => c.name === configs.name)
      const { rethrow = false } = options

      if (index === -1) {
        dataConfigs.push(configs)
      } else {
        dataConfigs.splice(index, 1, configs)
      }

      return api.post('encrypted_configs', {
        data: {
          key: 'database.credentials',
          value: dataConfigs.map(this.databaseConfigPayload)
        }
      }).then((result) => {
        this.$Message.info(this.t('settings.databasePage.updatedSuccess'))

        this.configs = result.data.data.value
      }).catch((error) => {
        this.showErrorMessage(error)

        if (rethrow) {
          throw error
        }
      })
    },
    // 展示统一 API 错误消息。
    showErrorMessage (error) {
      this.$Message.error(errorMessage(error))
    },
    // 对数据库 URL 中的账号密码进行展示脱敏。
    maskedDatabaseUrl (url) {
      return (url || '').replace(/\/\/.*?@/, '//xxxxx:xxxxx@')
    },
    // 生成后端保存数据库配置所需 payload。
    databaseConfigPayload (config) {
      const payload = { name: config.name, url: config.url }
      const schemaSearchPath = config.schema_search_path?.trim()

      if (schemaSearchPath) {
        payload.schema_search_path = schemaSearchPath
      }

      return payload
    }
  }
}
</script>
