import axios from 'axios'

import { basePath } from 'application/scripts/configs'

const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

const api = axios.create({
  baseURL: `${basePath.replace(/\/$/, '')}/api`,
  headers: csrfToken ? { 'X-CSRF-Token': csrfToken } : {}
})

export default api
