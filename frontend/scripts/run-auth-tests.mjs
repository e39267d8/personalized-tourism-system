import assert from 'node:assert/strict'
import fs from 'node:fs'
import { isAuthApiPath, safeRedirectPath, validateLoginForm, validateRegisterForm } from '../src/utils/auth.js'
import { gcj02ToWgs84, toAmapLngLat, toBackendLatLng, wgs84ToGcj02 } from '../src/utils/coordinates.js'

function createStorage(initial = {}) {
  const data = new Map(Object.entries(initial))
  return {
    getItem: key => data.get(key) || null,
    setItem: (key, value) => data.set(key, String(value)),
    removeItem: key => data.delete(key),
    snapshot: () => Object.fromEntries(data.entries())
  }
}

function loadAuthStore({ initialStorage = {}, tourismApi = {} } = {}) {
  const source = fs.readFileSync(new URL('../src/stores/auth.js', import.meta.url), 'utf8')
    .replace(/^import .*$/gm, '')
    .replace('export const authStore', 'const authStore')
    .replaceAll('export async function ', 'async function ')
    .replaceAll('export function ', 'function ')

  const factory = new Function(
    'reactive',
    'tourismApi',
    'diaryStore',
    'localStorage',
    `${source}
return { authStore, setAuthSession, clearAuthSession, isAuthenticated, restoreAuth, login, register, logout, changePassword }`
  )

  const storage = createStorage(initialStorage)
  const diaryStore = { user: { nickname: '', avatar: '' } }
  const auth = factory(value => value, tourismApi, diaryStore, storage)
  return { auth, storage, diaryStore }
}

async function run() {
  {
    const beijingWgs = { latitude: 39.908823, longitude: 116.39747 }
    const beijingGcj = wgs84ToGcj02(beijingWgs.latitude, beijingWgs.longitude)
    assert.ok(Math.abs(beijingGcj.latitude - beijingWgs.latitude) > 0.0005)
    assert.ok(Math.abs(beijingGcj.longitude - beijingWgs.longitude) > 0.0005)

    const restored = gcj02ToWgs84(beijingGcj.latitude, beijingGcj.longitude)
    assert.ok(Math.abs(restored.latitude - beijingWgs.latitude) < 0.00005)
    assert.ok(Math.abs(restored.longitude - beijingWgs.longitude) < 0.00005)
    assert.deepEqual(toAmapLngLat(beijingWgs), [beijingGcj.longitude, beijingGcj.latitude])

    const backendPoint = toBackendLatLng({
      getLng: () => beijingGcj.longitude,
      getLat: () => beijingGcj.latitude
    })
    assert.ok(Math.abs(backendPoint.latitude - beijingWgs.latitude) < 0.00005)
    assert.ok(Math.abs(backendPoint.longitude - beijingWgs.longitude) < 0.00005)

    const parisWgs = { latitude: 48.8566, longitude: 2.3522 }
    assert.deepEqual(wgs84ToGcj02(parisWgs.latitude, parisWgs.longitude), parisWgs)
    assert.deepEqual(gcj02ToWgs84(parisWgs.latitude, parisWgs.longitude), parisWgs)
  }

  assert.equal(safeRedirectPath('/profile'), '/profile')
  assert.equal(safeRedirectPath('/diary/new?draft=1'), '/diary/new?draft=1')
  assert.equal(safeRedirectPath('https://example.com'), '/profile')
  assert.equal(safeRedirectPath('//example.com'), '/profile')
  assert.equal(safeRedirectPath('/\nprofile'), '/profile')
  assert.equal(safeRedirectPath('', '/'), '/')

  assert.equal(validateLoginForm({ identifier: '', password: '' }), '请输入用户名或邮箱')
  assert.equal(validateLoginForm({ identifier: 'demo_user', password: '' }), '请输入密码')
  assert.equal(validateLoginForm({ identifier: ' demo_user ', password: 'demo123456' }), '')

  assert.equal(
    validateRegisterForm({ username: 'ab', email: 'demo@example.com', password: 'demo123456' }),
    '用户名长度需要在 3 到 50 个字符之间'
  )
  assert.equal(
    validateRegisterForm({ username: 'demo user', email: 'demo@example.com', password: 'demo123456' }),
    '用户名只能包含字母、数字、下划线或短横线'
  )
  assert.equal(validateRegisterForm({ username: 'demo_user', email: 'bad', password: 'demo123456' }), '请输入有效邮箱')
  assert.equal(validateRegisterForm({ username: 'demo_user', email: 'demo@example.com', password: 'short' }), '密码至少需要 8 个字符')
  assert.equal(validateRegisterForm({ username: 'demo_user', email: 'demo@example.com', password: 'demo123456' }), '')

  assert.equal(isAuthApiPath('/auth/login'), true)
  assert.equal(isAuthApiPath('/auth/me'), true)
  assert.equal(isAuthApiPath('/profile'), false)

  {
    const tourismApi = {
      login: async () => ({
        token: 'token-1',
        user: { username: 'demo_user', nickname: '演示用户', avatarUrl: 'avatar.png' }
      })
    }
    const { auth, storage, diaryStore } = loadAuthStore({ tourismApi })
    await auth.login({ identifier: 'demo_user', password: 'demo123456' })
    assert.equal(auth.authStore.token, 'token-1')
    assert.equal(auth.authStore.user.username, 'demo_user')
    assert.equal(diaryStore.user.nickname, '演示用户')
    assert.deepEqual(storage.snapshot(), { token: 'token-1' })
    assert.equal(auth.isAuthenticated(), true)
  }

  {
    const tourismApi = {
      authMe: async () => ({ user: { username: 'demo_user', nickname: '演示用户' } })
    }
    const { auth } = loadAuthStore({ initialStorage: { token: 'stored-token' }, tourismApi })
    assert.equal(await auth.restoreAuth(), true)
    assert.equal(auth.authStore.user.nickname, '演示用户')
  }

  {
    const tourismApi = {
      authMe: async () => {
        throw new Error('unauthorized')
      }
    }
    const { auth, storage } = loadAuthStore({ initialStorage: { token: 'bad-token' }, tourismApi })
    assert.equal(await auth.restoreAuth(), false)
    assert.equal(auth.authStore.token, '')
    assert.equal(auth.authStore.user, null)
    assert.deepEqual(storage.snapshot(), {})
  }

  {
    let logoutCalled = false
    const tourismApi = {
      logout: async () => {
        logoutCalled = true
        return { loggedOut: true }
      }
    }
    const { auth, storage } = loadAuthStore({ tourismApi })
    auth.setAuthSession({ token: 'token-1', user: { username: 'demo_user' } })
    await auth.logout()
    assert.equal(logoutCalled, true)
    assert.equal(auth.authStore.token, '')
    assert.equal(auth.authStore.user, null)
    assert.deepEqual(storage.snapshot(), {})
  }
}

run()
  .then(() => {
    console.log('Auth tests passed.')
  })
  .catch(error => {
    console.error(error)
    process.exitCode = 1
  })
