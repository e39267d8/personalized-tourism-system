<template>
  <div class="min-h-screen bg-slate-50 text-slate-950">
    <header class="sticky top-0 z-40 border-b border-slate-200 bg-white/95 backdrop-blur">
      <div class="mx-auto flex min-h-16 max-w-7xl items-center gap-4 px-4 sm:px-6 lg:px-8">
        <router-link to="/" class="flex min-w-0 items-center gap-3">
          <span class="grid h-10 w-10 flex-none place-items-center rounded-md bg-teal-700 text-sm font-bold text-white">TP</span>
          <span class="min-w-0">
            <span class="block text-lg font-bold leading-5">TourPilot</span>
            <span class="block truncate text-xs text-slate-500">个性化旅游规划与记录</span>
          </span>
        </router-link>

        <form class="hidden flex-1 md:block" @submit.prevent="submitSearch">
          <label class="relative block">
            <span class="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-sm text-slate-400">搜索</span>
            <input
              v-model="keyword"
              class="h-10 w-full rounded-md border border-slate-300 bg-slate-50 pl-12 pr-24 text-sm outline-none transition focus:border-teal-700 focus:bg-white"
              placeholder="景点、路线、博物馆、citywalk"
              type="search"
            >
            <button class="absolute right-1.5 top-1/2 -translate-y-1/2 rounded-md bg-slate-900 px-3 py-1.5 text-sm font-semibold text-white hover:bg-slate-800">
              搜索
            </button>
          </label>
        </form>

        <nav class="hidden items-center gap-1 lg:flex">
          <router-link
            v-for="item in navItems"
            :key="item.to"
            :to="item.to"
            class="rounded-md px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-100 hover:text-slate-950"
            active-class="bg-slate-900 text-white hover:bg-slate-900 hover:text-white"
          >
            {{ item.label }}
          </router-link>
        </nav>

        <div class="ml-auto hidden items-center gap-2 sm:flex lg:ml-0">
          <template v-if="authStore.user">
            <router-link to="/profile" class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">
              {{ authStore.user.nickname || authStore.user.username }}
            </router-link>
            <button class="rounded-md px-3 py-2 text-sm font-semibold text-slate-500 hover:bg-slate-100 hover:text-slate-900" @click="handleLogout">
              退出
            </button>
          </template>
          <template v-else>
            <router-link to="/login" class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">
              登录
            </router-link>
            <router-link to="/register" class="rounded-md bg-slate-900 px-3 py-2 text-sm font-semibold text-white hover:bg-slate-800">
              注册
            </router-link>
          </template>
        </div>
      </div>

      <div class="border-t border-slate-100 px-4 py-2 md:hidden">
        <form @submit.prevent="submitSearch">
          <input
            v-model="keyword"
            class="h-10 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
            placeholder="搜索景点或路线"
            type="search"
          >
        </form>
      </div>

      <nav class="flex gap-2 overflow-x-auto border-t border-slate-100 px-4 py-2 lg:hidden">
        <router-link
          v-for="item in mobileNavItems"
          :key="item.to"
          :to="item.to"
          class="whitespace-nowrap rounded-md px-3 py-2 text-sm font-medium text-slate-600"
          active-class="bg-slate-900 text-white"
        >
          {{ item.label }}
        </router-link>
      </nav>
    </header>

    <main class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { authStore, logout } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const keyword = ref(typeof route.query.q === 'string' ? route.query.q : '')

const navItems = [
  { to: '/', label: '首页' },
  { to: '/search', label: '发现景点' },
  { to: '/recommend', label: '预算推荐' },
  { to: '/route', label: '路线规划' },
  { to: '/food', label: '美食推荐' },
  { to: '/agent', label: 'AI助手' },
  { to: '/diary', label: '旅行日记' },
  { to: '/achievements', label: '成就' },
  { to: '/tools/huffman', label: '压缩演示' }
]

const mobileNavItems = [...navItems, { to: '/profile', label: '我的' }]

const submitSearch = () => {
  const q = keyword.value.trim()
  router.push({ path: '/search', query: q ? { q } : {} })
}

async function handleLogout() {
  await logout()
  if (route.meta.requiresAuth) router.push('/')
}

watch(
  () => route.query.q,
  value => {
    keyword.value = typeof value === 'string' ? value : ''
  }
)
</script>
