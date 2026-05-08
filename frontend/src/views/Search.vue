<template>
  <div class="space-y-6">
    <section class="grid gap-6 lg:grid-cols-[0.75fr_1.25fr]">
      <div class="rounded-md border border-slate-200 bg-white p-5">
        <h1 class="text-2xl font-bold">发现景点</h1>
        <p class="mt-2 text-sm leading-6 text-slate-500">搜索景点名称、类型、标签或描述，快速找到适合自己的目的地。</p>

        <form class="mt-5 space-y-4" @submit.prevent="runSearch">
          <input
            v-model="query"
            class="h-11 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
            placeholder="例如：故宫、博物馆、摄影、低预算"
            type="search"
          >

          <div>
            <label class="text-sm font-semibold text-slate-700">景点类型</label>
            <select v-model="category" class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700">
              <option value="">全部类型</option>
              <option v-for="item in categories" :key="item" :value="item">{{ item }}</option>
            </select>
          </div>

          <div>
            <label class="text-sm font-semibold text-slate-700">最高门票预算</label>
            <div class="mt-2 flex items-center gap-3">
              <input v-model.number="maxTicket" type="range" min="0" max="120" step="10" class="flex-1 accent-teal-700">
              <span class="w-16 text-right text-sm font-bold">¥{{ maxTicket }}</span>
            </div>
          </div>

          <button class="w-full rounded-md bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white hover:bg-slate-800">
            搜索景点
          </button>
        </form>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h2 class="text-lg font-semibold">搜索结果</h2>
            <p class="mt-1 text-sm text-slate-500">共找到 {{ filteredSpots.length }} 个景点</p>
          </div>
          <span class="rounded-md bg-teal-50 px-3 py-1 text-sm font-semibold text-teal-800">{{ sourceLabel }}</span>
        </div>

        <div class="mt-5 grid gap-4 md:grid-cols-2">
          <router-link
            v-for="spot in filteredSpots"
            :key="spot.id"
            :to="`/spots/${spot.id}`"
            class="overflow-hidden rounded-md border border-slate-200 bg-white transition hover:-translate-y-0.5 hover:border-teal-700 hover:shadow-sm"
          >
            <img :src="spot.image" :alt="spot.name" class="h-40 w-full object-cover">
            <div class="p-4">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <h3 class="font-semibold text-slate-950">{{ spot.name }}</h3>
                  <div class="mt-1 text-sm text-slate-500">{{ spot.category }} · {{ spot.district }}</div>
                </div>
                <span class="rounded-md bg-amber-50 px-2 py-1 text-sm font-bold text-amber-800">{{ spot.rating }}</span>
              </div>
              <p class="mt-3 line-clamp-2 text-sm leading-6 text-slate-500">{{ spot.description }}</p>
              <div class="mt-4 flex flex-wrap gap-2">
                <span v-for="tag in spot.tags" :key="tag" class="rounded-md bg-slate-100 px-2 py-1 text-xs text-slate-600">{{ tag }}</span>
              </div>
              <div class="mt-4 flex items-center justify-between border-t border-slate-100 pt-3 text-sm text-slate-500">
                <span>门票 ¥{{ spot.ticket }}</span>
                <span>{{ spot.duration }}</span>
              </div>
            </div>
          </router-link>
        </div>

        <div v-if="!filteredSpots.length" class="mt-5 rounded-md border border-dashed border-slate-300 p-8 text-center">
          <div class="text-lg font-semibold">没有找到匹配景点</div>
          <p class="mt-2 text-sm text-slate-500">试试缩短关键词，或放宽门票预算。</p>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { scenicSpots as fallbackSpots } from '@/data/demoData'
import { tourismApi } from '@/services/tourismApi'

const route = useRoute()
const router = useRouter()

const query = ref(typeof route.query.q === 'string' ? route.query.q : '')
const category = ref('')
const maxTicket = ref(120)
const spots = ref(fallbackSpots)
const sourceLabel = ref('本地数据')

const categories = computed(() => [...new Set(spots.value.map(spot => spot.category).filter(Boolean))])

const filteredSpots = computed(() => {
  const keyword = query.value.trim().toLowerCase()
  return spots.value
    .filter(spot => !category.value || spot.category === category.value)
    .filter(spot => Number(spot.ticket ?? 0) <= maxTicket.value)
    .filter(spot => {
      if (!keyword) return true
      return [spot.name, spot.category, spot.district, spot.description, ...(spot.tags || [])]
        .join(' ')
        .toLowerCase()
        .includes(keyword)
    })
    .sort((a, b) => Number(b.rating || 0) - Number(a.rating || 0))
})

const loadSpots = async () => {
  try {
    const response = await tourismApi.scenicSpots({ q: query.value.trim() })
    spots.value = response.items?.length ? response.items : fallbackSpots
    sourceLabel.value = response.items?.length ? '数据库结果' : '本地数据'
  } catch (error) {
    spots.value = fallbackSpots
    sourceLabel.value = '本地数据'
  }
}

const runSearch = () => {
  router.push({ path: '/search', query: query.value.trim() ? { q: query.value.trim() } : {} })
  loadSpots()
}

watch(
  () => route.query.q,
  value => {
    query.value = typeof value === 'string' ? value : ''
    loadSpots()
  }
)

onMounted(loadSpots)
</script>
