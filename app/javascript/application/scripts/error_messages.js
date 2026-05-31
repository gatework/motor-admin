// API 错误文案工具：把 Rails 常见错误结构压平成可展示的消息列表。
// 把字段名转换为可读前缀，base 错误不显示字段名。
function humanizeKey (key) {
  return key === 'base' ? '' : `${key.replace(/_/g, ' ')} `
}

// 递归展开数组/对象形式的 Rails errors，输出字符串列表。
function normalizeErrorValue (value, key = '') {
  if (Array.isArray(value)) {
    return value.flatMap((item) => normalizeErrorValue(item, key))
  }

  if (value && typeof value === 'object') {
    return Object.entries(value).flatMap(([nestedKey, nestedValue]) => normalizeErrorValue(nestedValue, nestedKey))
  }

  return [`${humanizeKey(key)}${value}`.trim()].filter(Boolean)
}

// 从 axios error 中提取所有错误消息，缺失时使用 fallback。
function errorMessages (error, fallback = 'Unable to perform this action') {
  const errors = error?.response?.data?.errors

  if (!errors) {
    return [error?.message || fallback]
  }

  return normalizeErrorValue(errors)
}

// 返回适合弹窗展示的单个错误字符串。
function errorMessage (error, fallback) {
  return errorMessages(error, fallback).join('\n')
}

export { errorMessage, errorMessages }
