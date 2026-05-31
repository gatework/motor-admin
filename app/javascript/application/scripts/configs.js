// 前端运行配置：读取 Rails 注入的基础路径和版本号。
const appNode = document.getElementById('app')

const basePath = appNode?.getAttribute('data-base-path') || '/'
const version = appNode?.getAttribute('data-version') || ''

export { version, basePath }
