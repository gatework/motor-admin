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
  data () {
    return {
      isLoading: false,
      value: {}
    }
  },
  computed: {
    displaySubmitText () {
      return this.submitText || this.t('settings.usersPage.updateSubmit')
    },
    apiPath () {
      return {
        create: 'admin_users',
        setup: 'setup',
        update: `admin_users/${this.user.id}`
      }[this.mode]
    },
    apiMethod () {
      return this.mode === 'update' ? 'put' : 'post'
    },
    rules () {
      return {
        email: [{ required: true, type: 'email' }],
        password: [{ required: this.requirePassword, min: 6 }],
        role_ids: [{ required: this.mode !== 'setup' && this.withRole }]
      }
    }
  },
  watch: {
    user (value) {
      if (value) {
        this.value = this.normalizeUser(this.user)
      }
    }
  },
  created () {
    this.value = this.normalizeUser(this.user)
  },
  methods: {
    normalizeUser (user) {
      return JSON.parse(JSON.stringify({
        ...user,
        role_ids: user.roles ? user.roles.map((e) => e.id) : []
      }))
    },
    submit () {
      this.isLoading = true

      const adminUser = { ...this.value }

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
