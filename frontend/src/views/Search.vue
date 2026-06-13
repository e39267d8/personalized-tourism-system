<template>
  <div class="space-y-6">
    <section class="grid gap-6 lg:grid-cols-[0.72fr_1.28fr]">
      <div class="rounded-md border border-slate-200 bg-white p-5">
        <h1 class="text-2xl font-bold">发现景点</h1>
        <form class="mt-5 space-y-4" @submit.prevent="runSearch">
          <div>
            <label class="text-sm font-semibold text-slate-700">关键词</label>
            <input
              v-model="query"
              class="mt-2 h-11 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
              placeholder="故宫、博物馆、摄影、低预算"
              type="search"
              @input="loadSuggestions"
            >
            <div v-if="suggestions.length" class="mt-2 flex flex-wrap gap-2">
              <button
                v-for="item in suggestions"
                :key="item"
                type="button"
                class="rounded-md bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-600 hover:bg-teal-50 hover:text-teal-800"
                @click="useSuggestion(item)"
              >
                {{ item }}
              </button>
            </div>
          </div>

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

          <div>
            <label class="text-sm font-semibold text-slate-700">排序方式</label>
            <select v-model="sort" class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700">
              <option value="relevance">相关度优先</option>
              <option value="rating">评分优先</option>
              <option value="price">低价优先</option>
              <option value="hot">热度优先</option>
            </select>
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
            <p class="mt-1 text-sm text-slate-500">找到 {{ spots.length }} 个景点，已按{{ sortLabel }}排序。</p>
          </div>
          <span class="rounded-md bg-teal-50 px-3 py-1 text-sm font-semibold text-teal-800">{{ sourceLabel }}</span>
        </div>

        <div v-if="loading && !spots.length" class="mt-5 grid gap-4 md:grid-cols-2">
          <div v-for="item in 4" :key="item" class="overflow-hidden rounded-md border border-slate-200 bg-white">
            <div class="h-40 w-full animate-pulse bg-slate-100"></div>
            <div class="space-y-3 p-4">
              <div class="h-4 w-2/3 animate-pulse rounded bg-slate-100"></div>
              <div class="h-3 w-full animate-pulse rounded bg-slate-100"></div>
              <div class="h-3 w-5/6 animate-pulse rounded bg-slate-100"></div>
            </div>
          </div>
        </div>

        <div v-else class="mt-5 grid gap-4 md:grid-cols-2">
          <router-link
            v-for="spot in spots"
            :key="spot.id"
            :to="`/spots/${spot.id}`"
            class="overflow-hidden rounded-md border border-slate-200 bg-white transition hover:-translate-y-0.5 hover:border-teal-700 hover:shadow-sm"
          >
            <img
              :src="spotImageUrl(spot)"
              :alt="spot.name"
              class="h-40 w-full object-cover"
              @error="event => handleSpotImageError(event, spot)"
            >
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
              <div class="mt-3 flex items-center justify-between text-xs">
                <span class="rounded-md bg-teal-50 px-2 py-1 font-medium text-teal-800">{{ spot.matchReason || '综合推荐' }}</span>
                <span class="font-semibold text-slate-500">相关度 {{ Math.round(Number(spot.score || 0)) }}</span>
              </div>
            </div>
          </router-link>
        </div>

        <div v-if="ready && !loading && !spots.length" class="mt-5 rounded-md border border-dashed border-slate-300 p-8 text-center">
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
import { handleSpotImageError, spotImageUrl } from '@/utils/images'

const route = useRoute()
const router = useRouter()

const query = ref(typeof route.query.q === 'string' ? route.query.q : '')
const category = ref('')
const maxTicket = ref(120)
const sort = ref('relevance')
const spots = ref([])
const categoryOptions = ref([])
const suggestions = ref([])
const loading = ref(false)
const ready = ref(false)
let spotsRequestSeq = 0
let suggestionsRequestSeq = 0
const sourceLabel = ref('精选景点')
const sortLabels = {
  relevance: '综合相关度',
  rating: '评分',
  price: '低价',
  hot: '热度'
}

const categories = computed(() => {
  if (categoryOptions.value.length) return categoryOptions.value
  return [...new Set(spots.value.map(spot => spot.category).filter(Boolean))]
})
const sortLabel = computed(() => sortLabels[sort.value] || sortLabels.relevance)

const loadCategories = async () => {
  try {
    const response = await tourismApi.scenicCategories()
    categoryOptions.value = (response.items || []).map(item => item.name).filter(Boolean)
  } catch (error) {
    categoryOptions.value = []
  }
}

const loadSuggestions = async () => {
  const seq = ++suggestionsRequestSeq
  try {
    const response = await tourismApi.searchSuggestions({ q: query.value.trim() })
    if (seq !== suggestionsRequestSeq) return
    suggestions.value = response.items || []
  } catch (error) {
    if (seq !== suggestionsRequestSeq) return
    suggestions.value = []
  }
}

const loadSpots = async () => {
  const seq = ++spotsRequestSeq
  loading.value = true
  ready.value = false
  try {
    const response = await tourismApi.scenicSpots({
      q: query.value.trim(),
      category: category.value,
      max_ticket: String(maxTicket.value),
      sort: sort.value,
      limit: 50
    })
    if (seq !== spotsRequestSeq) return
    spots.value = response.items || []
    ready.value = true
    sourceLabel.value = '智能检索'
  } catch (error) {
    if (seq !== spotsRequestSeq) return
    spots.value = fallbackSpots
    ready.value = true
    sourceLabel.value = '精选景点'
  } finally {
    if (seq === spotsRequestSeq) {
      loading.value = false
    }
  }
}

const runSearch = () => {
  const q = query.value.trim()
  if ((route.query.q || '') === q) {
    loadSpots()
    loadSuggestions()
    return
  }
  router.push({ path: '/search', query: q ? { q } : {} })
}

const useSuggestion = (item) => {
  query.value = item
  runSearch()
}

watch(
  () => route.query.q,
  value => {
    query.value = typeof value === 'string' ? value : ''
    loadSpots()
    loadSuggestions()
  }
)

watch([category, maxTicket, sort], loadSpots)

onMounted(() => {
  loadCategories()
  loadSpots()
  loadSuggestions()
})
</script>
