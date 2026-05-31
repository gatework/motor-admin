<template>
  <VForm
    ref="form"
    :model="value"
    :rules="rules"
    label-position="top"
    class="rule-settings"
    @keyup.enter="handleSubmit"
  >
    <div class="row">
      <FormItem
        prop="name"
        :label="t('settings.rolesPage.nameLabel')"
      >
        <VInput
          v-model="value.name"
          type="text"
          :placeholder="t('settings.rolesPage.namePlaceholder')"
        />
      </FormItem>
    </div>
    <FormItem
      prop="rules"
      :label="t('settings.rolesPage.permissionsLabel')"
      class="mb-1"
    >
      <RuleItem
        v-for="(rule, index) in value.rules"
        :key="index"
        :rule="rule"
        @remove="removeRule(rule)"
      />
    </FormItem>

    <VButton
      long
      icon="md-add"
      @click="addNewRule"
    >
      {{ t('settings.rolesPage.addRule') }}
    </VButton>
    <VButton
      v-if="mode === 'create'"
      type="primary"
      class="mt-4"
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
  <div
    v-if="mode === 'update'"
    class="sticky-footer"
  >
    <VButton
      class="role-remove-button"
      type="error"
      :loading="isRemoveLoading"
      ghost
      @click="remove"
    >
      {{ t('settings.rolesPage.remove') }}
    </VButton>
    <VButton
      type="primary"
      @click="handleSubmit"
    >
      {{ t('settings.rolesPage.submitButton') }}
    </VButton>
  </div>
</template>

<script>
import api from 'application/api'
import RuleItem from './rule_item'
import localeMixin from 'application/scripts/locale_mixin'

// 角色表单：维护角色名称和权限规则，并处理新增、更新与删除动作。
export default {
  name: 'RoleForm',
  components: {
    RuleItem
  },
  mixins: [localeMixin],
  props: {
    role: {
      type: Object,
      required: false,
      // 新建角色时提供空白表单值。
      default () {
        return {
          name: '',
          rules: []
        }
      }
    },
    mode: {
      type: String,
      required: false,
      default: 'create'
    },
    submitText: {
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['success', 'error', 'remove'],
  // 保存提交、删除加载状态和可编辑的角色副本。
  data () {
    return {
      isLoading: false,
      isRemoveLoading: false,
      value: {}
    }
  },
  computed: {
    // 计算提交按钮文案。
    displaySubmitText () {
      return this.submitText || this.t('settings.rolesPage.addRoleSubmit')
    },
    // 根据创建/更新模式计算 API 路径。
    apiPath () {
      return {
        create: 'roles',
        update: `roles/${this.role.id}`
      }[this.mode]
    },
    // 根据创建/更新模式计算 HTTP 方法。
    apiMethod () {
      return this.mode === 'update' ? 'put' : 'post'
    },
    // 返回角色表单校验规则。
    rules () {
      return {
        name: [{ required: true }]
      }
    }
  },
  watch: {
    // 外部角色变化时重建可编辑副本，避免直接修改 prop。
    role (value) {
      if (value) {
        this.value = JSON.parse(JSON.stringify(value))
      }
    }
  },
  // 初始化可编辑角色副本。
  mounted () {
    this.value = JSON.parse(JSON.stringify(this.role))
  },
  methods: {
    // 提交创建或更新请求，空 subject 规则不发送给后端。
    submit () {
      return api[this.apiMethod](this.apiPath, {
        role: {
          name: this.value.name,
          rules: this.value.rules.filter((r) => r.subjects.length)
        }
      })
    },
    // 新增一条空权限规则。
    addNewRule () {
      this.value.rules.push({ subjects: [], actions: [], attributes: [], conditions: [] })
    },
    // 从本地角色副本移除指定规则。
    removeRule (rule) {
      const index = this.value.rules.indexOf(rule)

      this.value.rules.splice(index, 1)
    },
    // 确认后删除当前角色。
    remove () {
      this.$Dialog.confirm({
        title: this.t('settings.rolesPage.areYouSure'),
        closable: true,
        onOk: () => {
          this.isRemoveLoading = true

          api.delete(this.apiPath).then(() => {
            this.$emit('remove')
          }).catch((error) => {
            this.$emit('error', error)
          }).finally(() => {
            this.isRemoveLoading = false
          })
        }
      })
    },
    // 表单校验通过后提交并透传结果。
    handleSubmit () {
      this.$refs.form.validate((valid) => {
        if (valid) {
          this.isLoading = true

          this.submit().then((result) => {
            this.$emit('success', result.data.data)
          }).catch((error) => {
            this.$emit('error', error)
          }).finally(() => {
            this.isLoading = false
          })
        }
      })
    }
  }
}
</script>

<style lang="scss">
.rule-settings {
  min-height: calc(100% - 62px);
}

.sticky-footer {
  background: #fff;
  border-top: 1px solid #e8e8e8;
  bottom: 0;
  display: flex;
  gap: 12px;
  justify-content: space-between;
  left: 0;
  padding: 10px 0;
  position: sticky;
  width: 100%;
}

.role-remove-button {
  margin-right: auto;
}

.ivu-modal-body {
  .sticky-footer {
    padding: 10px 0 0;
  }
}
</style>
