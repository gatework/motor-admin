import { reactive } from 'vue'

// 当前登录用户状态：从 Rails 首屏数据初始化，并支持设置页局部更新。
const appNode = document.getElementById('app')
const userAttrs = readCurrentUser()
const currentUser = reactive(userAttrs)

// 从 Rails 首屏 DOM 属性中读取当前用户 JSON，失败时返回空对象。
function readCurrentUser () {
  const rawUser = appNode?.getAttribute('data-current-user')

  if (!rawUser) return {}

  try {
    const parsedUser = JSON.parse(rawUser)

    return parsedUser && typeof parsedUser === 'object' ? parsedUser : {}
  } catch {
    return {}
  }
}

// 合并更新当前用户响应式对象，保持已绑定组件同步刷新。
function setCurrentUser (attrs) {
  Object.assign(currentUser, attrs || {})
}

export { currentUser, setCurrentUser }
