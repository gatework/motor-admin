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

export default {
  name: 'RolesSettingsPage',
  components: {
    Role
  },
  mixins: [localeMixin],
  data () {
    return {
      roles: rolesCache,
      errors: [],
      isLoaded: false
    }
  },
  mounted () {
    this.loadRoles().finally(() => {
      this.isLoaded = true
    })
  },
  methods: {
    loadRoles () {
      this.errors = []

      return api.get('roles').then((result) => {
        this.roles = result.data.data
        rolesCache = this.roles
      }).catch((error) => {
        this.errors = errorMessages(error)
      })
    },
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
