function humanizeKey (key) {
  return key === 'base' ? '' : `${key.replace(/_/g, ' ')} `
}

function normalizeErrorValue (value, key = '') {
  if (Array.isArray(value)) {
    return value.flatMap((item) => normalizeErrorValue(item, key))
  }

  if (value && typeof value === 'object') {
    return Object.entries(value).flatMap(([nestedKey, nestedValue]) => normalizeErrorValue(nestedValue, nestedKey))
  }

  return [`${humanizeKey(key)}${value}`.trim()].filter(Boolean)
}

function errorMessages (error, fallback = 'Unable to perform this action') {
  const errors = error?.response?.data?.errors

  if (!errors) {
    return [error?.message || fallback]
  }

  return normalizeErrorValue(errors)
}

function errorMessage (error, fallback) {
  return errorMessages(error, fallback).join('\n')
}

export { errorMessage, errorMessages }
