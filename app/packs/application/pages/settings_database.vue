<template>
  <Card
    v-if="!configs.length"
    class="mb-3"
  >
    <DatabaseForm
      :submit-text="t('settings.databasePage.submitUpdate')"
      :is-default-setup="true"
      @submit="handleUpdate"
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
          :model-value="config.url.replace(/\/\/.*?@/, '//xxxxx:xxxxx@')"
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

export default {
  name: 'DatabaseSettingsPage',
  components: {
    DatabaseForm
  },
  mixins: [localeMixin],
  data () {
    return {
      isLoaded: false,
      configs: []
    }
  },
  mounted () {
    this.loadConfigs().then(() => {
      this.isLoaded = true
    })
  },
  methods: {
    loadConfigs () {
      return api.get('encrypted_configs/database.credentials').then((result) => {
        this.configs = result.data.data.value || []
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
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
              value: dataConfigs.map((config) => ({ name: config.name, url: config.url }))
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
    handleUpdate (configs, options = {}) {
      const dataConfigs = [...this.configs]
      const index = dataConfigs.findIndex((c) => c.name === configs.name)
      const { rethrow = false } = options

      if (index === -1) {
        dataConfigs.push(configs)
      } else {
        dataConfigs.splice(dataConfigs.findIndex((c) => c.name === configs.name), 1, configs)
      }

      return api.post('encrypted_configs', {
        data: {
          key: 'database.credentials',
          value: dataConfigs.map((config) => ({ name: config.name, url: config.url, schema_search_path: config.schema_search_path }))
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
    showErrorMessage (error) {
      this.$Message.error(errorMessage(error))
    }
  }
}
</script>
