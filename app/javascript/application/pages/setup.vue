<template>
  <div class="setup-container">
    <div class="text-center">
      <h1 class="py-5">
        {{ t('settings.setupPage.pageTitle') }}
      </h1>
    </div>
    <Card class="mb-2">
      <UserForm
        v-if="step === 'user'"
        :mode="'setup'"
        :submit-text="t('settings.setupPage.start')"
        @success="onUserSuccess"
      />
      <DatabaseForm
        v-if="step === 'database'"
        :is-default-setup="true"
        :submit-text="t('settings.setupPage.connectToDatabase')"
        @success="onDatabaseSuccess"
      />
      <SubscribeForm
        v-if="step === 'subscribe'"
        :email="currentUser.email"
        :submit-text="t('settings.setupPage.subscribe')"
        @success="onSubscribeSuccess"
      />
    </Card>
    <div class="text-center">
      <a
        v-if="step != 'user'"
        href="#"
        @click.prevent="onSkip"
      >
        {{ t('settings.setupPage.skipStep') }}
      </a>
    </div>
    <div
      class="footer text-right d-none d-md-block"
    >
      <small>
        <a
          href="https://www.getmotoradmin.com/"
          target="_blank"
        > Motor Admin v{{ version }} </a>
      </small>
    </div>
  </div>
</template>

<script>
import UserForm from 'application/components/user_form'
import DatabaseForm from 'application/components/database_form'
import SubscribeForm from 'application/components/subscribe_form'
import { version, basePath } from 'application/scripts/configs'
import { currentUser, setCurrentUser } from 'application/scripts/current_user'
import localeMixin from 'application/scripts/locale_mixin'

// 初始化向导页：依次创建管理员、配置数据库并引导订阅。
export default {
  name: 'SetupPage',
  components: {
    UserForm,
    SubscribeForm,
    DatabaseForm
  },
  mixins: [localeMixin],
  // 保存当前初始化步骤。
  data () {
    return {
      step: 'user'
    }
  },
  computed: {
    // 暴露版本号用于页脚展示。
    version: () => version,
    // 暴露当前用户，供订阅步骤预填邮箱。
    currentUser: () => currentUser
  },
  methods: {
    // 首位管理员创建成功后进入数据库配置步骤。
    onUserSuccess (user) {
      this.step = 'database'

      setCurrentUser(user)
    },
    // 数据库配置完成后，已订阅则进入后台，否则进入订阅步骤。
    onDatabaseSuccess () {
      if (window.localStorage.getItem('newsletter')) {
        window.location.href = basePath
      } else {
        this.step = 'subscribe'
      }
    },
    // 订阅完成后进入后台。
    onSubscribeSuccess () {
      window.location.href = basePath
    },
    // 跳过当前非用户步骤，按流程进入下一步或后台。
    onSkip () {
      if (this.step === 'database') {
        this.onDatabaseSuccess()
      } else {
        window.location.href = basePath
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.setup-container {
  margin: 0 auto;
  max-width: 650px;
}

.footer {
  position: absolute;
  bottom: 0;
  right: 25px;
  height: 2.5rem;
}
</style>
