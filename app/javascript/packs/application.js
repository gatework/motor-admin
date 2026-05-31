import 'bootstrap/dist/css/bootstrap.css'

import app from 'application'

// Rails 页面加载完成后挂载设置页 Vue 应用。
document.addEventListener('DOMContentLoaded', () => {
  app.mount('#app')
})
