const DEFAULT_AUTH_REDIRECT = '/profile'
const AUTH_PAGES = new Set(['/login', '/register'])

export function safeRedirectPath(value, fallback = DEFAULT_AUTH_REDIRECT) {
  if (typeof value !== 'string') return fallback
  const redirect = value.trim()
  if (!redirect || redirect[0] !== '/') return fallback
  if (redirect.startsWith('//') || redirect.startsWith('/\\')) return fallback
  if (/[\r\n]/.test(redirect)) return fallback
  if (AUTH_PAGES.has(redirect.split(/[?#]/)[0])) return fallback
  return redirect
}

export function validateLoginForm(form) {
  const identifier = form?.identifier?.trim() || ''
  if (!identifier) return '请输入用户名或邮箱'
  if (!form?.password) return '请输入密码'
  return ''
}

export function validateRegisterForm(form) {
  const username = form?.username?.trim() || ''
  const email = form?.email?.trim() || ''
  const password = form?.password || ''

  if (username.length < 3 || username.length > 50) return '用户名长度需要在 3 到 50 个字符之间'
  if (!/^[A-Za-z0-9_-]+$/.test(username)) return '用户名只能包含字母、数字、下划线或短横线'
  if (!email) return '请输入邮箱'
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return '请输入有效邮箱'
  if (password.length < 8) return '密码至少需要 8 个字符'
  return ''
}

export function isAuthApiPath(url = '') {
  return ['/auth/login', '/auth/register', '/auth/me', '/auth/logout', '/auth/change-password'].some(path =>
    String(url).includes(path)
  )
}
