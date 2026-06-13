<template>
  <div class="space-y-6">
    <section class="grid gap-6 xl:grid-cols-[0.78fr_1.22fr]">
      <aside class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-start justify-between gap-4">
          <div>
            <h1 class="text-2xl font-bold text-slate-950">个性化推荐结果</h1>
          </div>
          <span class="rounded-md bg-teal-50 px-2.5 py-1 text-sm font-semibold text-teal-800">
            {{ sourceLabel }}
          </span>
        </div>

        <div class="mt-6 rounded-md bg-slate-50 p-4">
          <div class="flex items-center justify-between gap-3">
            <div class="text-sm font-semibold text-slate-950">当前偏好</div>
            <router-link to="/profile" class="text-sm font-semibold text-teal-700 hover:text-teal-900">
              修改问卷
            </router-link>
          </div>

          <div class="mt-4 space-y-4 text-sm">
            <div>
              <div class="font-semibold text-slate-700">景点类型</div>
              <div class="mt-2 flex flex-wrap gap-2">
                <span v-for="item in profile.preferredCategories" :key="item" class="rounded-md bg-white px-2.5 py-1 text-slate-600">{{ item }}</span>
                <span v-if="!profile.preferredCategories.length" class="text-slate-400">未选择</span>
              </div>
            </div>

            <div>
              <div class="font-semibold text-slate-700">偏好标签</div>
              <div class="mt-2 flex flex-wrap gap-2">
                <span v-for="item in profile.preferredTags" :key="item" class="rounded-md bg-white px-2.5 py-1 text-slate-600">{{ item }}</span>
                <span v-if="!profile.preferredTags.length" class="text-slate-400">未选择</span>
              </div>
            </div>

            <div class="grid gap-3 sm:grid-cols-3">
              <div class="rounded-md bg-white p-3">
                <div class="text-xs text-slate-400">预算</div>
                <div class="mt-1 font-semibold">{{ budgetLabel }}</div>
              </div>
              <div class="rounded-md bg-white p-3">
                <div class="text-xs text-slate-400">人流</div>
                <div class="mt-1 font-semibold">{{ crowdLabel }}</div>
              </div>
              <div class="rounded-md bg-white p-3">
                <div class="text-xs text-slate-400">强度</div>
                <div class="mt-1 font-semibold">{{ intensityLabel }}</div>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-6">
          <div class="flex items-center justify-between">
            <label class="text-sm font-semibold text-slate-700">最高门票预算</label>
            <span class="text-2xl font-bold text-slate-950">¥{{ maxTicket }}</span>
          </div>
          <input v-model.number="maxTicket" type="range" min="0" max="300" step="10" class="mt-4 w-full accent-teal-700">
          <div class="mt-2 flex justify-between text-xs text-slate-400">
            <span>免费</span>
            <span>均衡</span>
            <span>深度体验</span>
          </div>
        </div>

        <div class="mt-6 rounded-md border border-slate-200 p-4">
          <div class="text-sm font-semibold text-slate-950">推荐逻辑</div>
          <p class="mt-2 text-sm leading-6 text-slate-500">
            综合偏好标签、景点类型、评分、预算和人流强度，优先展示更适合当前出行需求的目的地。
          </p>
        </div>
      </aside>

      <section class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 class="text-lg font-semibold text-slate-950">推荐目的地</h2>
            <p class="mt-1 text-sm text-slate-500">
              找到 {{ filteredRecommendations.length }} 个符合当前预算的目的地。
            </p>
          </div>
          <select v-model="sortBy" class="h-10 rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700" @change="loadRecommendations">
            <option v-for="item in sortOptions" :key="item.value" :value="item.value">{{ item.label }}</option>
          </select>
          <button class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100" @click="loadRecommendations">
            重新计算
          </button>
        </div>

        <div v-if="loading && !recommendations.length" class="mt-5 grid gap-4 md:grid-cols-2">
          <div v-for="item in 4" :key="item" class="overflow-hidden rounded-md border border-slate-200 bg-white">
            <div class="h-44 w-full animate-pulse bg-slate-100"></div>
            <div class="space-y-3 p-4">
              <div class="h-4 w-2/3 animate-pulse rounded bg-slate-100"></div>
              <div class="h-3 w-full animate-pulse rounded bg-slate-100"></div>
              <div class="h-3 w-5/6 animate-pulse rounded bg-slate-100"></div>
            </div>
          </div>
        </div>

        <div v-else class="mt-5 grid gap-4 md:grid-cols-2">
          <router-link
            v-for="item in filteredRecommendations"
            :key="item.scenicSpot.id"
            :to="`/spots/${item.scenicSpot.id}`"
            class="overflow-hidden rounded-md border border-slate-200 transition hover:-translate-y-0.5 hover:border-teal-700 hover:shadow-sm"
          >
            <img
              :src="spotImageUrl(item.scenicSpot)"
              :alt="item.scenicSpot.name"
              class="h-44 w-full object-cover"
              @error="event => handleSpotImageError(event, item.scenicSpot)"
            >
            <div class="p-4">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <h3 class="font-semibold text-slate-950">{{ item.scenicSpot.name }}</h3>
                  <div class="mt-1 text-sm text-slate-500">{{ item.scenicSpot.category }} · {{ item.scenicSpot.district }}</div>
                </div>
                <div class="rounded-md bg-amber-50 px-2 py-1 text-sm font-bold text-amber-800">
                  {{ metricBadge(item) }}
                </div>
              </div>

              <p class="mt-3 line-clamp-2 text-sm leading-6 text-slate-500">{{ item.scenicSpot.description }}</p>

              <div class="mt-4 flex flex-wrap gap-2">
                <span v-for="tag in item.matchedTags" :key="tag" class="rounded-md bg-teal-50 px-2 py-1 text-xs font-medium text-teal-800">{{ tag }}</span>
                <span v-if="!item.matchedTags.length" class="rounded-md bg-slate-100 px-2 py-1 text-xs text-slate-600">综合推荐</span>
              </div>

              <p class="mt-3 text-sm leading-6 text-slate-600">{{ item.reason }}</p>

              <div class="mt-4 grid gap-2 border-t border-slate-100 pt-3 text-sm text-slate-500 sm:grid-cols-3">
                <span>评分 {{ item.scenicSpot.rating }}</span>
                <span>门票 ¥{{ item.scenicSpot.ticket }}</span>
                <span>{{ metricSummary(item) }}</span>
              </div>
            </div>
          </router-link>
        </div>

        <div v-if="!loading && !filteredRecommendations.length" class="mt-5 rounded-md border border-dashed border-slate-300 p-8 text-center">
          <div class="text-lg font-semibold text-slate-950">当前预算下没有匹配结果</div>
          <p class="mt-2 text-sm text-slate-500">可以提高门票预算，或到个人中心调整偏好标签。</p>
        </div>
      </section>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { scenicSpots as fallbackSpots } from '@/data/demoData'
import { tourismApi } from '@/services/tourismApi'
import { handleSpotImageError, spotImageUrl } from '@/utils/images'
import {
  budgetLabels,
  budgetMaxTicket,
  crowdLabels,
  defaultProfile,
  hasMeaningfulProfile,
  intensityLabels,
  normalizeProfile,
  normalizeRecommendation,
  readStoredProfile,
  writeStoredProfile
} from '@/utils/recommendation'

const profile = ref(defaultProfile())
const recommendations = ref([])
const maxTicket = ref(120)
const loading = ref(false)
const sortBy = ref('interest')
const sortOptions = [
  { value: 'interest', label: '个人兴趣优先' },
  { value: 'rating', label: '评价优先' },
  { value: 'hot', label: '热度优先' }
]
const sourceLabel = ref('个性化算法')
let recommendationsRequestSeq = 0

const budgetLabel = computed(() => budgetLabels[profile.value.budgetLevel] || budgetLabels.medium)
const crowdLabel = computed(() => crowdLabels[profile.value.crowdPreference] || crowdLabels.any)
const intensityLabel = computed(() => intensityLabels[profile.value.intensity] || intensityLabels.medium)

const filteredRecommendations = computed(() =>
  recommendations.value.filter(item => Number(item.scenicSpot.ticket || 0) <= maxTicket.value)
)

const metricBadge = (item) => {
  if (item.displayMetric === 'rating') {
    return `评分 ${Number(item.displayValue || item.scenicSpot.rating || 0).toFixed(1)}`
  }
  if (item.displayMetric === 'hot') {
    return `热度 ${Math.round(Number(item.displayValue || 0))}`
  }
  return `匹配 ${Math.round(Number(item.displayValue || item.score || 0))}`
}

const metricSummary = (item) => {
  if (item.displayMetric !== 'hot') return item.scenicSpot.duration
  const hotSignals = Number(item.scenicSpot.behaviorFavoriteCount || 0) +
    Number(item.scenicSpot.behaviorCheckinCount || 0) +
    Number(item.scenicSpot.diaryMentionCount || 0) +
    Number(item.scenicSpot.routeReferenceCount || 0)
  return hotSignals > 0 ? `热度信号 ${hotSignals}` : item.scenicSpot.duration
}

const loadProfile = async () => {
  const local = readStoredProfile()
  if (local && hasMeaningfulProfile(local)) {
    profile.value = local
    return true
  }

  try {
    const data = await tourismApi.getProfilePreferences()
    const remote = data.exists && data.profile ? normalizeProfile(data.profile) : null
    if (remote && hasMeaningfulProfile(remote)) {
      writeStoredProfile(remote)
      profile.value = remote
      return true
    }
    if (local) {
      profile.value = normalizeProfile(local)
      return hasMeaningfulProfile(local)
    }
    if (remote) {
      profile.value = remote
      return false
    }
  } catch (error) {
    if (local) {
      profile.value = normalizeProfile(local)
      return hasMeaningfulProfile(local)
    }
    return false
  }

  profile.value = defaultProfile()
  return false
}

const fallbackRecommendations = () => {
  const items = fallbackSpots.map(spot => normalizeRecommendation({ scenic_spot: spot }, profile.value))
  if (sortBy.value === 'rating') {
    return items.sort((left, right) => Number(right.scenicSpot.rating || 0) - Number(left.scenicSpot.rating || 0))
  }
  if (sortBy.value === 'hot') {
    return items.sort((left, right) => Number(right.scenicSpot.viewCount || right.score || 0) - Number(left.scenicSpot.viewCount || left.score || 0))
  }
  return items.sort((left, right) => right.score - left.score)
}

const loadRecommendations = async () => {
  const seq = ++recommendationsRequestSeq
  loading.value = true

  try {
    const hasProfile = await loadProfile()
    if (seq !== recommendationsRequestSeq) return
    sourceLabel.value = hasProfile ? '根据偏好' : '默认推荐'
    maxTicket.value = budgetMaxTicket(profile.value)

    const data = await tourismApi.personalizedRecommendations({
      ...profile.value,
      sortBy: sortBy.value,
      limit: 12
    })
    const items = (data.recommendations || []).map(item => normalizeRecommendation(item, profile.value, {
      preserveBackendScore: true,
      useBackendReason: true
    }))
    if (seq !== recommendationsRequestSeq) return
    recommendations.value = items.length ? items : fallbackRecommendations()
  } catch (error) {
    if (seq !== recommendationsRequestSeq) return
    recommendations.value = fallbackRecommendations()
    sourceLabel.value = hasMeaningfulProfile(profile.value) ? '根据偏好' : '默认推荐'
  } finally {
    if (seq === recommendationsRequestSeq) {
      loading.value = false
    }
  }
}

onMounted(loadRecommendations)
</script>
