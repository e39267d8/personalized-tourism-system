<template>
  <div class="space-y-6">
    <section class="overflow-hidden rounded-md border border-slate-200 bg-white">
      <div class="grid gap-0 lg:grid-cols-[1.25fr_0.75fr]">
        <div class="p-6 sm:p-8">
          <div class="inline-flex rounded-md bg-teal-50 px-3 py-1 text-sm font-medium text-teal-800">基础演示版</div>
          <h1 class="mt-5 max-w-3xl text-3xl font-bold tracking-tight text-slate-950 sm:text-5xl">
            用预算、偏好和路径算法生成一条能执行的旅行方案
          </h1>
          <p class="mt-4 max-w-2xl text-base leading-7 text-slate-600">
            当前版本覆盖景点推荐、路线规划、旅游日记、成就徽章和预算决策。页面先以演示数据跑通，后续可替换为数据库 API。
          </p>
          <div class="mt-6 flex flex-wrap gap-3">
            <router-link to="/recommend" class="rounded-md bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800">
              生成预算方案
            </router-link>
            <router-link to="/route" class="rounded-md border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">
              查看路线规划
            </router-link>
          </div>
        </div>
        <div class="relative min-h-72">
          <img
            class="absolute inset-0 h-full w-full object-cover"
            src="https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1400&q=80"
            alt="城市旅行场景"
          >
          <div class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-slate-950/80 to-transparent p-6 text-white">
            <div class="text-sm opacity-80">推荐演示路线</div>
            <div class="mt-1 text-2xl font-semibold">前门 -> 天安门 -> 故宫 -> 景山</div>
          </div>
        </div>
      </div>
    </section>

    <section class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
      <div v-for="stat in dashboardStats" :key="stat.label" class="rounded-md border border-slate-200 bg-white p-5">
        <div class="text-sm font-medium text-slate-500">{{ stat.label }}</div>
        <div class="mt-2 text-3xl font-bold text-slate-950">{{ stat.value }}</div>
        <div class="mt-1 text-sm text-slate-500">{{ stat.detail }}</div>
      </div>
    </section>

    <section class="grid gap-6 xl:grid-cols-[0.95fr_1.05fr]">
      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-center justify-between">
          <div>
            <h2 class="text-lg font-semibold text-slate-950">预算决定目的地</h2>
            <p class="mt-1 text-sm text-slate-500">输入预算后，系统优先压缩门票、交通或餐饮。</p>
          </div>
          <router-link to="/recommend" class="text-sm font-semibold text-teal-700 hover:text-teal-900">调整</router-link>
        </div>
        <div class="mt-5 space-y-3">
          <div v-for="plan in budgetPlans" :key="plan.id" class="rounded-md border border-slate-200 p-4">
            <div class="flex items-start justify-between gap-4">
              <div>
                <div class="text-sm font-semibold text-slate-950">{{ plan.label }}</div>
                <div class="mt-1 text-sm text-slate-500">{{ plan.title }}</div>
              </div>
              <div class="rounded-md bg-amber-50 px-2.5 py-1 text-sm font-bold text-amber-800">¥{{ plan.budget }}</div>
            </div>
            <div class="mt-3 text-sm text-slate-700">{{ plan.route }}</div>
          </div>
        </div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-center justify-between">
          <div>
            <h2 class="text-lg font-semibold text-slate-950">热门景点池</h2>
            <p class="mt-1 text-sm text-slate-500">用于推荐、地图和游记关联。</p>
          </div>
          <span class="rounded-md bg-slate-100 px-2.5 py-1 text-sm font-medium text-slate-600">{{ apiState }}</span>
        </div>
        <div class="mt-5 grid gap-4 sm:grid-cols-2">
          <article v-for="spot in spots.slice(0, 4)" :key="spot.id" class="overflow-hidden rounded-md border border-slate-200">
            <img :src="spot.image" :alt="spot.name" class="h-32 w-full object-cover">
            <div class="p-4">
              <div class="flex items-center justify-between">
                <h3 class="font-semibold text-slate-950">{{ spot.name }}</h3>
                <span class="text-sm font-bold text-amber-700">{{ spot.rating }}</span>
              </div>
              <p class="mt-2 line-clamp-2 text-sm leading-6 text-slate-500">{{ spot.description }}</p>
            </div>
          </article>
        </div>
      </div>
    </section>

    <section class="grid gap-6 xl:grid-cols-[1fr_0.85fr]">
      <div class="rounded-md border border-slate-200 bg-white p-5">
        <h2 class="text-lg font-semibold text-slate-950">路线方案</h2>
        <div class="mt-4 space-y-3">
          <div v-for="route in routes" :key="route.id" class="rounded-md border border-slate-200 p-4">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <div class="font-semibold text-slate-950">{{ route.title }}</div>
                <div class="mt-1 text-sm text-slate-500">{{ route.stops.join(' / ') }}</div>
              </div>
              <div class="text-right text-sm text-slate-600">
                <div>{{ route.distance }} · {{ route.time }}</div>
                <div class="font-semibold text-teal-700">约 ¥{{ route.cost }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <h2 class="text-lg font-semibold text-slate-950">预留扩展区</h2>
        <div class="mt-4 grid gap-3">
          <div class="rounded-md bg-slate-50 p-4">
            <div class="font-semibold">高德数据接入</div>
            <p class="mt-1 text-sm leading-6 text-slate-500">后续可在这里展示 POI 同步状态、API key 配置和抓取日志。</p>
          </div>
          <div class="rounded-md bg-slate-50 p-4">
            <div class="font-semibold">真实用户画像</div>
            <p class="mt-1 text-sm leading-6 text-slate-500">保留偏好权重、预算区间、出行方式、历史收藏入口。</p>
          </div>
          <div class="rounded-md bg-slate-50 p-4">
            <div class="font-semibold">AIGC 游记助手</div>
            <p class="mt-1 text-sm leading-6 text-slate-500">可接入摘要、标题生成、行程复盘和图片说明。</p>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { budgetPlans, dashboardStats as fallbackStats, routePlans as fallbackRoutes, scenicSpots as fallbackSpots } from '@/data/demoData'
import { tourismApi } from '@/services/tourismApi'

const dashboardStats = ref(fallbackStats)
const spots = ref(fallbackSpots)
const routes = ref(fallbackRoutes)
const apiState = ref('本地演示数据')

onMounted(async () => {
  try {
    const [dashboard, scenic, routeData] = await Promise.all([
      tourismApi.dashboard(),
      tourismApi.scenicSpots(),
      tourismApi.routes()
    ])
    dashboardStats.value = dashboard.stats || fallbackStats
    spots.value = scenic.items || fallbackSpots
    routes.value = routeData.items || fallbackRoutes
    apiState.value = '后端 API 已连接'
  } catch (error) {
    apiState.value = '本地演示数据'
  }
})
</script>
