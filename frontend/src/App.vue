<template>
  <div class="min-h-screen bg-slate-50 text-slate-950">
    <aside class="fixed inset-y-0 left-0 z-30 hidden w-72 border-r border-slate-200 bg-white lg:block">
      <div class="flex h-full flex-col">
        <div class="border-b border-slate-200 px-6 py-5">
          <div class="text-xs font-semibold uppercase tracking-[0.18em] text-teal-700">TourPilot</div>
          <div class="mt-2 text-2xl font-bold tracking-tight">个性化旅游系统</div>
        </div>

        <nav class="flex-1 space-y-1 px-3 py-4">
          <router-link
            v-for="item in navItems"
            :key="item.to"
            :to="item.to"
            class="group flex items-center gap-3 rounded-md px-3 py-3 text-sm font-medium text-slate-600 transition hover:bg-slate-100 hover:text-slate-950"
            active-class="bg-slate-900 text-white hover:bg-slate-900 hover:text-white"
          >
            <span class="grid h-8 w-8 place-items-center rounded-md border border-slate-200 bg-white text-xs font-bold text-slate-700 group-[.router-link-active]:border-slate-700 group-[.router-link-active]:bg-slate-800 group-[.router-link-active]:text-white">
              {{ item.code }}
            </span>
            <span>{{ item.label }}</span>
          </router-link>
        </nav>

        <div class="border-t border-slate-200 p-4">
          <div class="rounded-md bg-teal-50 p-4">
            <div class="text-sm font-semibold text-teal-950">演示数据已就绪</div>
            <p class="mt-1 text-xs leading-5 text-teal-800">PostGIS、小型景点数据、路线图、游记和成就可用于基础演示。</p>
          </div>
        </div>
      </div>
    </aside>

    <div class="lg:pl-72">
      <header class="sticky top-0 z-20 border-b border-slate-200 bg-white/90 backdrop-blur">
        <div class="flex min-h-16 items-center justify-between gap-4 px-4 sm:px-6 lg:px-8">
          <div>
            <div class="text-sm text-slate-500">北京中轴线演示环境</div>
            <div class="text-lg font-semibold text-slate-950">{{ currentTitle }}</div>
          </div>
          <div class="flex items-center gap-3">
            <button class="rounded-md border border-slate-300 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100">
              导出方案
            </button>
            <button class="rounded-md bg-slate-900 px-3 py-2 text-sm font-medium text-white hover:bg-slate-800">
              演示账号
            </button>
          </div>
        </div>

        <nav class="flex gap-2 overflow-x-auto border-t border-slate-100 px-4 py-2 lg:hidden">
          <router-link
            v-for="item in navItems"
            :key="item.to"
            :to="item.to"
            class="whitespace-nowrap rounded-md px-3 py-2 text-sm font-medium text-slate-600"
            active-class="bg-slate-900 text-white"
          >
            {{ item.label }}
          </router-link>
        </nav>
      </header>

      <main class="px-4 py-6 sm:px-6 lg:px-8">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()

const navItems = [
  { to: '/', label: '总览', code: 'OV' },
  { to: '/recommend', label: '推荐与预算', code: 'BD' },
  { to: '/route', label: '路线规划', code: 'RT' },
  { to: '/diary', label: '旅游日记', code: 'DY' },
  { to: '/achievements', label: '成就系统', code: 'AC' }
]

const currentTitle = computed(() => navItems.find(item => item.to === route.path)?.label || '工作台')
</script>
