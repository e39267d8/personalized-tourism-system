<template>
  <div class="mx-auto max-w-md">
    <section class="rounded-md border border-slate-200 bg-white p-6 shadow-sm">
      <div>
        <p class="text-sm font-semibold text-teal-700">欢迎回来</p>
        <h1 class="mt-2 text-2xl font-bold text-slate-950">登录 TourPilot</h1>
        <p class="mt-2 text-sm leading-6 text-slate-500">登录后可以保存偏好、发布游记、收藏和评论。</p>
      </div>

      <form class="mt-6 space-y-4" @submit.prevent="submit">
        <div>
          <label class="text-sm font-semibold text-slate-700">用户名或邮箱</label>
          <input
            v-model="form.identifier"
            autocomplete="username"
            class="mt-2 h-11 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
            placeholder="demo_user 或 demo@example.com"
          >
        </div>
        <div>
          <label class="text-sm font-semibold text-slate-700">密码</label>
          <input
            v-model="form.password"
            autocomplete="current-password"
            class="mt-2 h-11 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
            placeholder="demo123456"
            type="password"
          >
        </div>

        <div v-if="error" class="rounded-md bg-rose-50 px-3 py-2 text-sm text-rose-700">{{ error }}</div>

        <button
          class="h-11 w-full rounded-md bg-slate-900 text-sm font-semibold text-white hover:bg-slate-800 disabled:opacity-60"
          :disabled="submitting"
        >
          {{ submitting ? '登录中...' : '登录' }}
        </button>
      </form>

      <div class="mt-5 flex items-center justify-between text-sm">
        <span class="text-slate-500">还没有账号？</span>
        <router-link :to="{ path: '/register', query: redirectQuery }" class="font-semibold text-teal-700 hover:text-teal-900">
          注册新账号
        </router-link>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { login } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const submitting = ref(false)
const error = ref('')
const form = reactive({
  identifier: '',
  password: ''
})

const redirectPath = computed(() => typeof route.query.redirect === 'string' ? route.query.redirect : '/profile')
const redirectQuery = computed(() => redirectPath.value ? { redirect: redirectPath.value } : {})

async function submit() {
  error.value = ''
  if (!form.identifier.trim() || !form.password) {
    error.value = '请输入账号和密码'
    return
  }
  submitting.value = true
  try {
    await login({ identifier: form.identifier.trim(), password: form.password })
    router.push(redirectPath.value || '/profile')
  } catch (err) {
    error.value = err.response?.data?.message || '登录失败，请检查账号和密码'
  } finally {
    submitting.value = false
  }
}
</script>
