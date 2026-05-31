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

export default {
  name: 'SetupPage',
  components: {
    UserForm,
    SubscribeForm,
    DatabaseForm
  },
  mixins: [localeMixin],
  data () {
    return {
      step: 'user'
    }
  },
  computed: {
    version: () => version,
    currentUser: () => currentUser
  },
  methods: {
    onUserSuccess (user) {
      this.step = 'database'

      setCurrentUser(user)
    },
    onDatabaseSuccess () {
      if (window.localStorage.getItem('newsletter')) {
        window.location.href = basePath
      } else {
        this.step = 'subscribe'
      }
    },
    onSubscribeSuccess () {
      window.location.href = basePath
    },
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
