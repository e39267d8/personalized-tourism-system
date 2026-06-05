<template>
  <div class="mx-auto max-w-md">
    <section class="rounded-md border border-slate-200 bg-white p-6 shadow-sm">
      <div>
        <p class="text-sm font-semibold text-teal-700">创建账号</p>
        <h1 class="mt-2 text-2xl font-bold text-slate-950">注册 TourPilot</h1>
        <p class="mt-2 text-sm leading-6 text-slate-500">注册后即可保存旅行偏好和发布自己的游记。</p>
      </div>

      <form class="mt-6 space-y-4" @submit.prevent="submit">
        <div>
          <label class="text-sm font-semibold text-slate-700">用户名</label>
          <input v-model="form.username" autocomplete="username" class="mt-2 h-11 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700" maxlength="50">
        </div>
        <div>
          <label class="text-sm font-semibold text-slate-700">邮箱</label>
          <input v-model="form.email" autocomplete="email" class="mt-2 h-11 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700" maxlength="100" type="email">
        </div>
        <div>
          <label class="text-sm font-semibold text-slate-700">昵称</label>
          <input v-model="form.nickname" class="mt-2 h-11 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700" maxlength="50">
        </div>
        <div>
          <label class="text-sm font-semibold text-slate-700">密码</label>
          <input v-model="form.password" autocomplete="new-password" class="mt-2 h-11 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700" type="password">
          <p class="mt-1 text-xs text-slate-400">至少 8 个字符。</p>
        </div>

        <div v-if="error" class="rounded-md bg-rose-50 px-3 py-2 text-sm text-rose-700">{{ error }}</div>

        <button
          class="h-11 w-full rounded-md bg-slate-900 text-sm font-semibold text-white hover:bg-slate-800 disabled:opacity-60"
          :disabled="submitting"
        >
          {{ submitting ? '注册中...' : '注册并登录' }}
        </button>
      </form>

      <div class="mt-5 flex items-center justify-between text-sm">
        <span class="text-slate-500">已有账号？</span>
        <router-link :to="{ path: '/login', query: redirectQuery }" class="font-semibold text-teal-700 hover:text-teal-900">
          去登录
        </router-link>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { register } from '@/stores/auth'
import { safeRedirectPath, validateRegisterForm } from '@/utils/auth'

const route = useRoute()
const router = useRouter()
const submitting = ref(false)
const error = ref('')
const form = reactive({
  username: '',
  email: '',
  nickname: '',
  password: ''
})

const redirectPath = computed(() => safeRedirectPath(route.query.redirect))
const redirectQuery = computed(() => redirectPath.value ? { redirect: redirectPath.value } : {})

async function submit() {
  if (submitting.value) return
  error.value = ''
  const validationMessage = validateRegisterForm(form)
  if (validationMessage) {
    error.value = validationMessage
    return
  }
  submitting.value = true
  try {
    await register({
      username: form.username.trim(),
      email: form.email.trim(),
      nickname: form.nickname.trim(),
      password: form.password
    })
    router.push(redirectPath.value)
  } catch (err) {
    error.value = err.response?.data?.message || '注册失败，请稍后重试'
  } finally {
    submitting.value = false
  }
}
</script>
