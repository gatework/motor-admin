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

// 个人设置页：维护当前管理员资料、订阅状态和退出登录入口。
export default {
  name: 'GeneralSettingsPage',
  components: {
    UserForm,
    SubscribeForm
  },
  mixins: [localeMixin],
  computed: {
    // 暴露全局当前用户响应式对象。
    currentUser: () => currentUser
  },
  methods: {
    // 注销当前 session 并跳转回登录页。
    signOut () {
      api.delete('session').then(() => {
        window.location.href = basePath === '/' ? '/sign_in' : basePath + '/sign_in'
      }).catch((error) => {
        this.showErrorMessage(error)
      })
    },
    // 更新本地当前用户状态并提示保存成功。
    onUserUpdate (user) {
      setCurrentUser(user)

      this.$Message.info(this.t('settings.generalPage.userUpdated'))
    },
    // 订阅成功时展示提示。
    subscribeSuccesMessage () {
      this.$Message.info(this.t('settings.generalPage.subscribed'))
    },
    // 展示统一 API 错误消息。
    showErrorMessage (error) {
      this.$Message.error(errorMessage(error))
    }
  }
}
</script>
