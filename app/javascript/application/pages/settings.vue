<template>
  <div class="settings-header">
    <div class="d-flex align-items-center">
      <a
        class="ivu-btn ivu-btn-primary d-flex align-items-center justify-content-center settings-home-button"
        :href="basePath"
        target="_self"
      >
        <Icon
          type="md-flash"
          size="26"
        />
      </a>
      <span
        class="ms-2 text-white settings-title"
      >{{ t('settings.header.settings') }}</span>
    </div>

    <a
      class="ivu-btn ivu-btn-primary ivu-btn-large ms-2"
      :href="basePath"
    >
      <span><i
        class="ion ion-md-arrow-round-back"
      /><span class="settings-admin-panel-label">{{ t('settings.header.adminPanel') }}</span></span>
    </a>
  </div>
  <div class="container mt-3 settings-container">
    <div class="ivu-tabs">
      <div class="ivu-tabs-bar">
        <div
          class="ivu-tabs-nav-container"
        >
          <div
            class="ivu-tabs-nav-wrap settings-tabs-nav-wrap"
          >
            <div class="ivu-tabs-scroll">
              <div
                class="ivu-tabs-nav text-center w-100"
              >
                <RouterLink
                  v-for="tab in tabs"
                  :key="tab.title"
                  :class="{ 'ivu-tabs-tab-focused ivu-tabs-tab-active' : tab === currentTab }"
                  class="ivu-tabs-tab"
                  :to="tab.to"
                >
                  {{ tab.title }}
                </RouterLink>
              </div>
            </div>
          </div>
        </div>
      </div>
      <slot />
    </div>
    <div class="position-relative">
      <RouterView />
      <div
        class="text-center settings-version"
      >
        <a
          href="https://github.com/motor-admin/motor-admin"
          target="_blank"
        >{{ t('settings.header.motorAdmin') }} v{{ version }}</a>
      </div>
    </div>
  </div>
</template>

<script>
import { basePath, version } from 'application/scripts/configs'
import localeMixin from 'application/scripts/locale_mixin'

// 设置页外壳：负责顶部导航、设置标签页和版本信息展示。
export default {
  name: 'SettingsPage',
  mixins: [localeMixin],
  computed: {
    // 暴露 Rails 后端注入的 basePath，供返回后台按钮使用。
    basePath: () => basePath,
    // 暴露当前前端版本号。
    version: () => version,
    // 根据当前路由匹配激活的设置标签页。
    currentTab () {
      return this.tabs.find((tab) => tab.to.name === this.$route.name)
    },
    // 生成设置页全部标签导航。
    tabs () {
      return [
        { title: this.t('settings.tabs.general'), to: { name: 'general_settings' } },
        { title: this.t('settings.tabs.users'), to: { name: 'users_settings' } },
        { title: this.t('settings.tabs.roles'), to: { name: 'roles_settings' } },
        { title: this.t('settings.tabs.database'), to: { name: 'database_settings' } },
        { title: this.t('settings.tabs.email'), to: { name: 'email_settings' } },
        { title: this.t('settings.tabs.storage'), to: { name: 'storage_settings' } },
        { title: this.t('settings.tabs.other'), to: { name: 'other_settings' } }
      ]
    }
  }
}
</script>

<style lang="scss">
@use 'application/styles/variables' as *;

.settings-header {
  background-color: $primary-color;
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 12px;

  .ivu-btn {
    font-size: 15px;
    font-weight: 500;
    display: flex;
    align-items: center;

    .ion {
      vertical-align: sub;
      line-height: 1;
    }

    .ion-md-arrow-round-back {
      font-size: 20px;
    }
  }
}

.settings-home-button {
  height: 42px;
  width: 44px;
}

.settings-title {
  font-size: 15px;
  font-weight: 500;
}

.settings-admin-panel-label {
  vertical-align: middle;
}

.settings-container {
  max-width: 800px;
}

.settings-tabs-nav-wrap {
  position: relative;
}

.settings-version {
  margin-bottom: 0;
}

.ivu-tabs-tab {
  padding: 8px 32px;
  margin: 0;

  @media screen and (max-width: $breakpoint-md) {
    padding: 8px 18px;
  }
}

a.ivu-tabs-tab {
  color: inherit;
}

.ivu-tabs-tab-active {
  border-bottom: 3px solid $primary-color;
}

.ivu-tabs-tab {
  user-select: none;
}

.ivu-tabs-scroll {
  overflow-x: auto;

  &::-webkit-scrollbar {
    display: none;
  }
}
</style>
