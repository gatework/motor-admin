// 数据库连接串工具：负责在表单字段和 Rails 数据库 URL 之间做安全转换。
// 将数据库 URL 拆成表单字段对象，解析失败时返回空对象。
function databaseUrlToObject (url) {
  if (!url) {
    return {}
  }

  let parsedUrl

  try {
    parsedUrl = new URL(url)
  } catch {
    return {}
  }

  const protocol = parsedUrl.protocol.replace(/:$/, '')

  return {
    protocol: normalizeProtocol(protocol),
    username: decodedUrlPart(parsedUrl.username),
    password: decodedUrlPart(parsedUrl.password),
    host: parsedUrl.hostname || undefined,
    port: parsedUrl.port || undefined,
    database: decodedUrlPart(parsedUrl.pathname.replace(/^\//, ''))
  }
}

// 将表单字段组装为数据库 URL，缺少必要字段时返回空字符串。
function databaseObjectToUrl ({ protocol, username, password, host, port, database }) {
  if (!protocol || !host || !port || !database) {
    return ''
  }

  const encodedUsername = encodedUrlPart(username)
  const encodedPassword = encodedUrlPart(password)
  const encodedDatabase = encodedUrlPart(database)
  const auth = encodedUsername ? `${encodedUsername}${encodedPassword ? `:${encodedPassword}` : ''}@` : ''

  // 用户名、密码和数据库名必须转义，否则特殊字符会破坏连接串结构。
  return `${normalizeProtocol(protocol)}://${auth}${host}:${port}/${encodedDatabase}`
}

// 将用户选择的协议名转换为 Rails 适配器使用的标准协议。
function normalizeProtocol (protocol) {
  const normalizedProtocol = String(protocol || '').toLowerCase()

  return {
    mysql: 'mysql2',
    postgresql: 'postgres'
  }[normalizedProtocol] || normalizedProtocol
}

// 编码 URL 中的用户名、密码、数据库名等可变部分。
function encodedUrlPart (value) {
  if (value === undefined || value === null || value === '') {
    return ''
  }

  return encodeURIComponent(String(value))
}

// 解码 URL 片段，遇到非法编码时保留原值。
function decodedUrlPart (value) {
  if (!value) {
    return undefined
  }

  try {
    return decodeURIComponent(value)
  } catch {
    return value
  }
}

export { databaseUrlToObject, databaseObjectToUrl, normalizeProtocol }
