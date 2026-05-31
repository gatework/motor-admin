<template>
  <Card>
    <UserForm
      :user="currentUser"
      :require-password="false"
      :mode="'update'"
      :submit-text="t('settings.generalPage.submitUpdate')"
      :with-role="false"
      @success="onUserUpdate"
      @error="showErrorMessage"
    />
  </Card>
  <Card class="mt-3">
    <SubscribeForm
      :submit-text="t('settings.generalPage.submitSubscribe')"
      :email="currentUser.email"
      @success="subscribeSuccesMessage"
    />
  </Card>
  <VButton
    size="large"
    class="my-3 bg-white"
    long
    type="error"
    ghost
    @click="signOut"
  >
    <Icon type="ios-log-out" />
    {{ t('settings.generalPage.signOut') }}
  </VButton>
</template>

<script>
import api from 'application/api'
import UserForm from 'application/components/user_form'
import SubscribeForm from 'application/components/subscribe_form'
import { basePath } from 'application/scripts/configs'
import { currentUser, setCurrentUser } from 'application/scripts/current_user'
import { errorMessage } from 'application/scripts/error_messages'
import localeMixin from 'application/scripts/locale_mixin'

export default {
  name: 'GeneralSettingsPage',
  components: {
    UserForm,
    SubscribeForm
  },
  mixins: [localeMixin],
  computed: {
    currentUser: () => currentUser
  },
  methods: {
    signOut () {
      api.delete('session').then(() => {
        window.location.href = basePath === '/' ? '/sign_in' : basePath + '/sign_in'
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
    onUserUpdate (user) {
      setCurrentUser(user)

      this.$Message.info(this.t('settings.generalPage.userUpdated'))
    },
    subscribeSuccesMessage () {
      this.$Message.info(this.t('settings.generalPage.subscribed'))
    },
    showErrorMessage (error) {
      this.$Message.error(errorMessage(error))
    }
  }
}
</script>
