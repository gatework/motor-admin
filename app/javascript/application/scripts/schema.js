import { reactive } from 'vue'

// 资源 schema 状态：承接后端按权限裁剪后的模型结构，供筛选和权限表单复用。
const appNode = document.getElementById('app')
const schema = reactive(readSchema())

const modelSlugMap = Object.fromEntries(schema.map((res) => [res.slug, res]))
const modelNameMap = Object.fromEntries(schema.map((res) => [res.name, res]))

// 从 Rails 首屏 DOM 属性读取资源 schema，解析失败时返回空数组。
function readSchema () {
  const rawSchema = appNode?.getAttribute('data-schema')

  if (!rawSchema) return []

  try {
    const parsedSchema = JSON.parse(rawSchema)

    return Array.isArray(parsedSchema) ? parsedSchema : []
  } catch {
    return []
  }
}

export { schema, modelSlugMap, modelNameMap }
