<template>
  <div
    v-if="errors.length"
    class="alert alert-danger"
  >
    <div
      v-for="error in errors"
      :key="error"
    >
      {{ error }}
    </div>
  </div>
  <div v-if="roles.length">
    <Role
      v-for="role in roles"
      :key="role.id"
      :role="role"
      @update="loadRoles"
    />
  </div>
  <VButton
    size="large"
    long
    type="dashed"
    class="mb-3"
    @click="openAddRoleModal"
  >
    <Icon type="md-add" />
    {{ t('settings.rolesPage.addRole') }}
  </VButton>
  <Spin
    v-if="!isLoaded"
    fix
  />
</template>

<script>
import api from 'application/api'
import { errorMessage, errorMessages } from 'application/scripts/error_messages'
import localeMixin from 'application/scripts/locale_mixin'
import Role from '../components/role'
import RoleForm from '../components/role_form'

let rolesCache = []

// 角色设置页：展示角色列表，并承接新增角色后的刷新和错误提示。
export default {
  name: 'RolesSettingsPage',
  components: {
    Role
  },
  mixins: [localeMixin],
  // 使用模块级缓存加快返回页面时的首屏展示。
  data () {
    return {
      roles: rolesCache,
      errors: [],
      isLoaded: false
    }
  },
  // 首次进入页面时加载角色列表。
  mounted () {
    this.loadRoles().finally(() => {
      this.isLoaded = true
    })
  },
  methods: {
    // 从后端加载角色列表，并刷新模块级缓存。
    loadRoles () {
      this.errors = []

      return api.get('roles').then((result) => {
        this.roles = result.data.data
        rolesCache = this.roles
      }).catch((error) => {
        this.errors = errorMessages(error)
      })
    },
    // 打开新增角色抽屉，成功后刷新列表。
    openAddRoleModal () {
      this.$Drawer.open(RoleForm, {
        submitText: this.t('settings.rolesPage.addRoleSubmit'),
        onSuccess: (data) => {
          this.$Drawer.remove()
          this.$Message.info(this.t('settings.rolesPage.added', '', { name: data.name }))

          this.loadRoles()
        },
        onError: (error) => {
          this.$Message.error(errorMessage(error))
        }
      }, {
        title: this.t('settings.rolesPage.createNewRole'),
        closable: true
      })
    }
  }
}
</script>
