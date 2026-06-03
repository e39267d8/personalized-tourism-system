import { reactive } from 'vue'
import { tourismApi } from '@/services/tourismApi'
import { diaryStore } from '@/stores/diaryStore'

export const authStore = reactive({
  token: localStorage.getItem('token') || '',
  user: null,
  initialized: false,
  loading: false
})

function applyUser(user) {
  authStore.user = user || null
  diaryStore.user.nickname = user?.nickname || user?.username || '旅行者'
  diaryStore.user.avatar = user?.avatarUrl || ''
}

export function setAuthSession(payload) {
  authStore.token = payload?.token || ''
  if (authStore.token) localStorage.setItem('token', authStore.token)
  applyUser(payload?.user || null)
}

export function clearAuthSession() {
  authStore.token = ''
  localStorage.removeItem('token')
  applyUser(null)
}

export function isAuthenticated() {
  return Boolean(authStore.token && authStore.user)
}

export async function restoreAuth() {
  if (authStore.initialized) return isAuthenticated()
  authStore.loading = true
  try {
    if (authStore.token) {
      const data = await tourismApi.authMe()
      applyUser(data.user)
    }
  } catch {
    clearAuthSession()
  } finally {
    authStore.initialized = true
    authStore.loading = false
  }
  return isAuthenticated()
}

export async function login(payload) {
  const data = await tourismApi.login(payload)
  setAuthSession(data)
  authStore.initialized = true
  return data
}

export async function register(payload) {
  const data = await tourismApi.register(payload)
  setAuthSession(data)
  authStore.initialized = true
  return data
}

export async function logout() {
  try {
    if (authStore.token) await tourismApi.logout()
  } finally {
    clearAuthSession()
    authStore.initialized = true
  }
}

export async function changePassword(payload) {
  return tourismApi.changePassword(payload)
}

if (typeof window !== 'undefined') {
  window.addEventListener('tourism-auth:unauthorized', () => {
    clearAuthSession()
    authStore.initialized = true
  })
}
