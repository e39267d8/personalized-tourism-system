<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-slate-900">美食推荐</h1>
        <p v-if="!loading" class="mt-1 text-sm text-slate-500">
          返回前 {{ foods.length }} 家餐饮 · {{ cuisines.length }} 种菜系{{ selectedScenicName ? ' · ' + selectedScenicName : '' }}
        </p>
      </div>
      <!-- Sort -->
      <select
        v-model="sortBy"
        class="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500/40"
        @change="onSortChange"
      >
        <option value="hot">热门推荐</option>
        <option value="rating">评分最高</option>
        <option value="distance" :disabled="!selectedScenicId">距离最近</option>
      </select>
    </div>

    <!-- Filters -->
    <div class="rounded-md border border-slate-200 bg-white p-5">
      <div class="flex flex-wrap items-center gap-4">
        <!-- Location selector -->
        <div class="flex items-center gap-2">
          <label class="text-sm font-semibold text-slate-700">景点 / 学校</label>
          <select
            v-model="selectedScenic"
            class="rounded-md border border-slate-300 h-10 px-3 text-sm bg-white outline-none focus:border-teal-700"
            @change="onScenicChange"
          >
            <option :value="0">全部景点 / 学校</option>
            <optgroup v-if="campusScenicSpots.length" label="学校">
              <option v-for="spot in campusScenicSpots" :key="spot.id" :value="spot.id">{{ spot.name }}</option>
            </optgroup>
            <optgroup label="景点">
              <option v-for="spot in regularScenicSpots" :key="spot.id" :value="spot.id">{{ spot.name }}</option>
            </optgroup>
          </select>
        </div>

        <!-- Search -->
        <div class="flex items-center gap-2 flex-1 min-w-[200px]">
          <label class="text-sm font-semibold text-slate-700 flex-shrink-0">搜索</label>
          <input
            v-model="searchQuery"
            type="text"
            placeholder="输入美食、菜系、饭店或窗口名称"
            class="flex-1 rounded-md border border-slate-300 h-10 px-3 text-sm outline-none focus:border-teal-700"
            @input="debouncedSearch"
          />
        </div>
      </div>

      <!-- Cuisine chips -->
      <div v-if="cuisines.length" class="mt-4 flex flex-wrap items-center gap-2">
        <span class="text-sm font-semibold text-slate-700 mr-1">菜系</span>
        <button
          v-for="c in cuisines"
          :key="c.key"
          @click="toggleCuisine(c.key)"
          :class="[
            'rounded-md px-2.5 py-1 text-xs font-medium transition',
            selectedCuisine === c.key
              ? 'bg-teal-700 text-white'
              : 'bg-slate-100 text-slate-600 hover:bg-teal-50 hover:text-teal-800'
          ]"
        >
          {{ c.label }}
        </button>
        <button
          v-if="selectedCuisine"
          @click="clearCuisines"
          class="rounded-md px-2.5 py-1 text-xs font-medium text-slate-500 hover:text-red-600 transition"
        >
          清除
        </button>
      </div>
      <p v-if="!selectedScenicId" class="mt-3 text-xs text-slate-500">选择具体景点或学校后，可以按距离最近排序。</p>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="n in 6" :key="'s'+n" class="rounded-md border border-slate-200 bg-white p-5 animate-pulse">
        <div class="h-4 bg-slate-200 rounded w-2/3 mb-3"></div>
        <div class="h-3 bg-slate-100 rounded w-1/2 mb-4"></div>
        <div class="h-3 bg-slate-100 rounded w-full mb-2"></div>
        <div class="h-3 bg-slate-100 rounded w-3/4"></div>
      </div>
    </div>

    <!-- Empty -->
    <div v-else-if="!foods.length" class="rounded-md border border-slate-200 bg-white p-16 text-center">
      <h3 class="text-lg font-semibold text-slate-700 mb-2">暂未找到匹配美食</h3>
      <p class="text-sm text-slate-500">试试切换景区、菜系或修改搜索词</p>
      <button @click="resetAll" class="mt-4 rounded-md bg-teal-700 px-4 py-2 text-sm font-semibold text-white hover:bg-teal-800 transition">重置筛选</button>
    </div>

    <!-- Food Card Grid -->
    <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      <article
        v-for="item in foods"
        :key="item.id"
        class="group rounded-md border border-slate-200 bg-white shadow-sm hover:shadow-md transition-shadow cursor-pointer"
        @click="goToScenic(item)"
      >
        <div class="p-5">
          <!-- Name + Rating -->
          <div class="flex items-start justify-between gap-2">
            <div class="min-w-0">
              <h3 class="text-base font-bold text-slate-900 truncate">{{ item.name }}</h3>
              <div class="mt-1 flex items-center gap-2">
                <span
                  v-if="item.cuisineLabel"
                  class="rounded-md bg-teal-50 px-2 py-0.5 text-xs font-semibold text-teal-800"
                >{{ item.cuisineLabel }}</span>
                <span
                  v-if="item.scenicName"
                  class="rounded-md bg-slate-100 px-2 py-0.5 text-xs text-slate-500"
                >{{ item.locationTypeLabel || '景点' }} · {{ item.scenicName }}</span>
              </div>
            </div>
            <div class="flex items-center gap-1 flex-shrink-0">
              <svg class="w-4 h-4 text-amber-500" fill="currentColor" viewBox="0 0 20 20">
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
              </svg>
              <span class="text-sm font-bold text-amber-700">{{ formatRating(item.rating) }}</span>
            </div>
          </div>

          <div class="mt-4 grid grid-cols-2 gap-2 text-xs">
            <div class="rounded-md bg-amber-50 px-2.5 py-2 text-amber-800">
              <div class="font-semibold">综合热度</div>
              <div class="mt-0.5 text-sm font-bold">{{ formatHotScore(item.hotScore ?? item.score) }}</div>
            </div>
            <div class="rounded-md bg-teal-50 px-2.5 py-2 text-teal-800">
              <div class="font-semibold">距离</div>
              <div class="mt-0.5 text-sm font-bold">{{ formatDistance(item.distanceMeters) }}</div>
            </div>
          </div>

          <!-- Address -->
          <div class="mt-3 flex items-center gap-1.5 text-xs text-slate-500">
            <svg class="w-3.5 h-3.5 flex-shrink-0 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
            </svg>
            <span class="truncate">{{ item.address || '地址待补充' }}</span>
          </div>

          <!-- Hours & Phone -->
          <div class="mt-2 flex items-center gap-3 text-xs text-slate-500">
            <span v-if="item.openingHours" class="flex items-center gap-1">
              <svg class="w-3.5 h-3.5 flex-shrink-0 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              {{ item.openingHours }}
            </span>
            <span v-if="item.phone" class="flex items-center gap-1">
              <svg class="w-3.5 h-3.5 flex-shrink-0 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
              </svg>
              {{ item.phone }}
            </span>
          </div>

          <!-- Price + Action -->
          <div class="mt-4 flex items-center justify-between">
            <div class="flex items-center gap-1">
              <span v-for="n in (item.priceLevel || 0)" :key="n" class="text-teal-700 text-sm font-bold">&yen;</span>
              <span v-for="n in (4 - (item.priceLevel || 0))" :key="'g'+n" class="text-slate-300 text-sm">&yen;</span>
            </div>
            <span class="text-xs font-medium text-teal-700 opacity-0 group-hover:opacity-100 transition-opacity">
              查看景点 &rarr;
            </span>
          </div>
        </div>
      </article>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { tourismApi } from '@/services/tourismApi'

const router = useRouter()
const foods = ref([])
const cuisines = ref([])
const scenicSpots = ref([])
const loading = ref(false)
const sortBy = ref('hot')
const searchQuery = ref('')
const selectedScenic = ref(0)
const selectedCuisine = ref('')

let searchTimer = null

const selectedScenicId = computed(() => Number(selectedScenic.value) || 0)

const selectedScenicName = computed(() => {
  if (!selectedScenicId.value) return ''
  const s = scenicSpots.value.find(s => Number(s.id) === selectedScenicId.value)
  return s ? s.name : ''
})

const campusScenicSpots = computed(() => scenicSpots.value.filter(isCampusSpot))
const regularScenicSpots = computed(() => scenicSpots.value.filter(spot => !isCampusSpot(spot)))

function isCampusSpot(spot) {
  const text = `${spot.category || ''} ${(spot.tags || []).join(' ')} ${spot.name || ''}`
  return /高校|校园|学校|大学/.test(text)
}

function formatRating(r) {
  return Number(r || 0).toFixed(1)
}

function formatHotScore(score) {
  return Math.round(Number(score || 0))
}

function formatDistance(meters) {
  const value = Number(meters || 0)
  if (!Number.isFinite(value) || value <= 0) return '待计算'
  if (value < 1000) return `约 ${Math.round(value)}m`
  return `约 ${(value / 1000).toFixed(1)}km`
}

function buildParams() {
  const params = { sort: sortBy.value, limit: 10 }
  if (selectedScenicId.value > 0) params.scenic_spot_id = selectedScenicId.value
  if (searchQuery.value.trim()) params.q = searchQuery.value.trim()
  if (selectedCuisine.value) params.cuisine = selectedCuisine.value
  return params
}

async function loadFoods() {
  loading.value = true
  try {
    const data = await tourismApi.foodRecommend(buildParams())
    const items = data.items || data || []
    foods.value = items
    if (data.sort && data.sort !== sortBy.value) sortBy.value = data.sort
  } catch {
    foods.value = []
  } finally {
    loading.value = false
  }
}

async function loadCuisines() {
  try {
    const params = {}
    if (selectedScenicId.value > 0) params.scenic_spot_id = selectedScenicId.value
    const data = await tourismApi.foodCuisines(params)
    const raw = data.cuisines || data.items || data || []
    cuisines.value = raw.map(c => typeof c === 'string' ? { key: c, label: c } : { key: c.key || c.value || c, label: c.label || c.name || c })
  } catch {
    cuisines.value = []
  }
}

async function loadScenicSpots() {
  try {
    const data = await tourismApi.scenicSpots({ limit: 100 })
    const all = data.items || data || []
    scenicSpots.value = all
  } catch {
    scenicSpots.value = []
  }
}

function toggleCuisine(key) {
  selectedCuisine.value = selectedCuisine.value === key ? '' : key
  loadFoods()
}

function clearCuisines() {
  selectedCuisine.value = ''
  loadFoods()
}

function onScenicChange() {
  selectedCuisine.value = ''
  if (!selectedScenicId.value && sortBy.value === 'distance') sortBy.value = 'hot'
  loadCuisines()
  loadFoods()
}

function onSortChange() {
  if (sortBy.value === 'distance' && !selectedScenicId.value) sortBy.value = 'hot'
  loadFoods()
}
function debouncedSearch() {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(loadFoods, 400)
}

function resetAll() {
  selectedScenic.value = 0
  selectedCuisine.value = ''
  searchQuery.value = ''
  sortBy.value = 'hot'
  loadCuisines()
  loadFoods()
}

function goToScenic(item) {
  const id = item.scenicSpotId || item.scenic_spot_id || 0
  if (id > 0) router.push(`/spots/${id}`)
}

onMounted(() => {
  loadScenicSpots()
  loadCuisines()
  loadFoods()
})
</script>
