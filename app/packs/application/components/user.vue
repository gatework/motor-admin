<template>
  <Card>
    <div class="row">
      <div class="col-10 d-flex justify-content-center flex-column">
        <div class="row">
          <div class="col-lg-5">
            <Icon type="ios-mail" />
            {{ user.email }}
          </div>
          <div class="col-lg-5">
            <template v-if="fullName">
              <Icon type="ios-person" />
              {{ fullName }}
            </template>
          </div>
          <div class="col-lg-2">
            <div
              v-for="role in user.roles"
              :key="role.id"
              class="ivu-tag ivu-tag-size-default ivu-tag-checked"
            >
              <span class="ivu-tag-text">{{ role.name }}</span>
            </div>
          </div>
        </div>
      </div>
      <div class="col-2 d-flex justify-content-end align-items-center">
        <VButton
          type="text"
          icon="ios-redo"
          :to="`/impersonate/${user.impersonate_token}`"
          target="_blank"
        />
        <Dropdown
          trigger="click"
          placement="bottom-end"
        >
          <VButton
            type="text"
            size="large"
          >
            <Icon
              type="md-more"
              size="large"
            />
          </VButton>
          <template #list>
            <DropdownMenu>
              <DropdownItem
                @click="editUser"
              >
                {{ t('settings.usersPage.edit') }}
              </DropdownItem>
              <DropdownItem
                @click="resetPassword"
              >
                {{ t('settings.usersPage.resetPassword') }}
              </DropdownItem>
              <DropdownItem
                v-if="removable"
                @click="deleteUser"
              >
                {{ t('settings.usersPage.remove') }}
              </DropdownItem>
            </DropdownMenu>
          </template>
        </Dropdown>
      </div>
    </div>
    <Spin
      v-if="isLoading"
      fix
    />
  </Card>
</template>

<script>
import api from 'application/api'
import UserForm from 'application/components/user_form'
import { errorMessage } from 'application/scripts/error_messages'
import localeMixin from 'application/scripts/locale_mixin'

export default {
  name: 'User',
  mixins: [localeMixin],
  props: {
    user: {
      type: Object,
      required: true
    },
    removable: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  emits: ['update'],
  data () {
    return {
      isLoading: false
    }
  },
  computed: {
    fullName () {
      return [this.user.first_name, this.user.last_name].filter(Boolean).join(' ')
    }
  },
  methods: {
    editUser () {
      this.$Modal.open(UserForm, {
        user: this.user,
        requirePassword: false,
        mode: 'update',
        submitText: this.t('settings.usersPage.updateSubmit'),
        onSuccess: (data) => {
          this.$Modal.remove()
          this.$Message.info(this.t('settings.usersPage.updated', '', { email: data.email }))

          this.$emit('update')
        },
        onError: (error) => {
          this.$Message.error(errorMessage(error))
        }
      }, {
        closable: true
      })
    },
    resetPassword () {
      this.isLoading = true

      api.post(`admin_users/${this.user.id}/reset_password`).then(() => {
        this.$Message.info(this.t('settings.usersPage.resetPasswordSent', '', { email: this.user.email }))
      }).catch((error) => {
        this.$Message.error(errorMessage(error))
      }).finally(() => {
        this.isLoading = false
      })
    },
    deleteUser () {
      this.$Dialog.confirm({
        title: this.t('settings.usersPage.areYouSure'),
        closable: true,
        onOk: () => {
          api.delete(`admin_users/${this.user.id}`).then(() => {
            this.$Message.info(this.t('settings.usersPage.removed', '', { email: this.user.email }))

            this.$emit('update')
          }).catch((error) => {
            this.$Message.error(errorMessage(error))
          })
        }
      })
    }
  }
}
</script>

<style lang="scss" scoped>
:deep(.ivu-card-body) {
  padding: 8px 16px;
}
</style>
