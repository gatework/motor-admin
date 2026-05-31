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
  <div v-if="users.length">
    <User
      v-for="user in users"
      :key="user.id"
      :user="user"
      class="mb-3"
      :removable="user.email.toLowerCase() !== currentUser.email.toLowerCase()"
      @update="loadUsers"
    />
  </div>
  <VButton
    role="addUserBtn"
    size="large"
    long
    class="mb-3"
    type="dashed"
    @click="openAddUserModal"
  >
    <Icon type="md-add" />
    {{ t('settings.usersPage.addUser') }}
  </VButton>
  <Spin
    v-if="isLoading"
    fix
  />
</template>

<script>
import api from 'application/api'

import UserForm from 'application/components/user_form'
import User from 'application/components/user'
import { currentUser } from 'application/scripts/current_user'
import { errorMessage, errorMessages } from 'application/scripts/error_messages'
import localeMixin from 'application/scripts/locale_mixin'

let usersCache = []

export default {
  name: 'UsersSettingsPage',
  components: {
    User
  },
  mixins: [localeMixin],
  data () {
    return {
      users: usersCache,
      errors: [],
      isLoading: true
    }
  },
  computed: {
    currentUser: () => currentUser
  },
  mounted () {
    this.loadUsers().finally(() => {
      this.isLoading = false
    })
  },
  methods: {
    loadUsers () {
      this.errors = []

      return api.get('admin_users').then((result) => {
        this.users = result.data.data
        usersCache = this.users
      }).catch((error) => {
        this.errors = errorMessages(error)
      })
    },
    openAddUserModal () {
      this.$Modal.open(UserForm, {
        submitText: this.t('settings.usersPage.addUserSubmit'),
        onSuccess: (data) => {
          this.$Modal.remove()
          this.$Message.info(this.t('settings.usersPage.added', '', { email: data.email }))

          this.loadUsers()
        },
        onError: (error) => {
          this.$Message.error(errorMessage(error))
        }
      }, {
        closable: true
      })
    }
  }
}
</script>
