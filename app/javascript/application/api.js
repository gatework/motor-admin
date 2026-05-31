import axios from 'axios'

import { basePath } from 'application/scripts/configs'

// API 客户端：统一挂载后台基础路径和 Rails CSRF 请求头。
const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
const normalizedBasePath = basePath.replace(/\/$/, '')

const api = axios.create({
  baseURL: `${normalizedBasePath}/api`,
  headers: csrfToken ? { 'X-CSRF-Token': csrfToken } : {}
})

export default api
