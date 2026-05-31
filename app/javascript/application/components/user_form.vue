<template>
  <VForm
    ref="form"
    :model="value"
    :rules="rules"
    @keyup.enter="handleSubmit"
  >
    <div class="row">
      <FormItem
        prop="first_name"
        :label="t('settings.usersPage.firstNameLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="value.first_name"
          type="text"
          :placeholder="t('settings.usersPage.firstNamePlaceholder')"
        />
      </FormItem>
      <FormItem
        prop="last_name"
        :label="t('settings.usersPage.lastNameLabel')"
        class="col-12 col-md-6"
      >
        <VInput
          v-model="value.last_name"
          type="text"
          :placeholder="t('settings.usersPage.lastNamePlaceholder')"
        />
      </FormItem>
      <FormItem
        prop="email"
        :label="t('settings.usersPage.emailLabel')"
        class="col-12"
      >
        <VInput
          v-model="value.email"
          prefix="md-mail"
          type="email"
          autocomplete="false"
          name="email"
          :placeholder="t('settings.usersPage.emailPlaceholder')"
        />
      </FormItem>
      <FormItem
        prop="password"
        :label="t('settings.usersPage.passwordLabel')"
        class="col-12"
      >
        <VInput
          v-model="value.password"
          prefix="md-key"
          type="password"
          name="password"
          :placeholder="t('settings.usersPage.passwordPlaceholder')"
        />
      </FormItem>
      <FormItem
        v-if="mode !== 'setup' && withRole"
        prop="role_ids"
        :label="t('settings.usersPage.rolesLabel')"
        class="col-12"
      >
        <RolesSelect
          v-model="value.role_ids"
        />
      </FormItem>
    </div>
    <VButton
      type="primary"
      class="mt-1"
      size="large"
      long
      :loading="isLoading"
      @click="handleSubmit()"
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
import RolesSelect from './roles_select'
import localeMixin from 'application/scripts/locale_mixin'

// 用户表单：负责管理员创建、初始化和资料更新，提交前会清理空白字段。
export default {
  name: 'UserForm',
  components: {
    RolesSelect
  },
  mixins: [localeMixin],
  props: {
    user: {
      type: Object,
      required: false,
      // 新建用户时提供空白表单值。
      default () {
        return {
          email: '',
          password: '',
          first_name: '',
          last_name: '',
          role_ids: []
        }
      }
    },
    requirePassword: {
      type: Boolean,
      required: false,
      default: true
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
    },
    withRole: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  emits: ['success', 'error'],
  // 保存提交加载状态和可编辑的用户副本。
  data () {
    return {
      isLoading: false,
      value: {}
    }
  },
  computed: {
    // 计算提交按钮文案。
    displaySubmitText () {
      return this.submitText || this.t('settings.usersPage.updateSubmit')
    },
    // 根据创建、初始化或更新模式计算 API 路径。
    apiPath () {
      return {
        create: 'admin_users',
        setup: 'setup',
        update: `admin_users/${this.user.id}`
      }[this.mode]
    },
    // 根据模式计算 HTTP 方法。
    apiMethod () {
      return this.mode === 'update' ? 'put' : 'post'
    },
    // 返回用户表单校验规则。
    rules () {
      return {
        email: [{ required: true, type: 'email' }],
        password: [{ required: this.requirePassword, min: 6 }],
        role_ids: [{ required: this.mode !== 'setup' && this.withRole }]
      }
    }
  },
  watch: {
    // 外部用户变化时重建可编辑副本。
    user (value) {
      if (value) {
        this.value = this.normalizeUser(this.user)
      }
    }
  },
  // 初始化可编辑用户副本。
  created () {
    this.value = this.normalizeUser(this.user)
  },
  methods: {
    // 深拷贝用户并把 roles 转换为 role_ids，适配表单控件。
    normalizeUser (user) {
      return JSON.parse(JSON.stringify({
        ...user,
        role_ids: user.roles ? user.roles.map((e) => e.id) : []
      }))
    },
    // 提交管理员创建、初始化或更新请求。
    submit () {
      this.isLoading = true

      const adminUser = this.normalizedAdminUser()

      if (!this.withRole) {
        delete adminUser.role_ids
      }

      api[this.apiMethod](this.apiPath, {
        admin_user: adminUser
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
    // 输出清理过空白且符合后端参数结构的管理员对象。
    normalizedAdminUser () {
      const adminUser = {
        email: this.cleanedValue('email'),
        first_name: this.cleanedValue('first_name'),
        last_name: this.cleanedValue('last_name'),
        password: this.cleanedValue('password'),
        role_ids: this.value.role_ids || []
      }

      if (!adminUser.password) {
        delete adminUser.password
      }

      return adminUser
    },
    // 读取字段并去除首尾空白。
    cleanedValue (key) {
      return this.value[key]?.toString().trim() || ''
    }
  }
}
</script>
