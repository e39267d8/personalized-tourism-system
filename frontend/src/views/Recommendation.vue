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
          <button class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100" @click="loadRecommendations">
            重新计算
          </button>
        </div>

        <div class="mt-5 grid gap-4 md:grid-cols-2">
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
                  {{ Math.round(item.score) }}
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
                <span>{{ item.scenicSpot.duration }}</span>
              </div>
            </div>
          </router-link>
        </div>

        <div v-if="!filteredRecommendations.length" class="mt-5 rounded-md border border-dashed border-slate-300 p-8 text-center">
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

const STORAGE_KEY = 'tourism_user_profile'

const defaultProfile = () => ({
  preferredCategories: [],
  preferredTags: [],
  budgetLevel: 'medium',
  crowdPreference: 'any',
  intensity: 'medium'
})

const profile = ref(defaultProfile())
const recommendations = ref([])
const maxTicket = ref(120)
const sourceLabel = ref('个性化算法')

const budgetLabels = {
  low: '\u4f4e\u9884\u7b97',
  medium: '\u4e2d\u7b49\u9884\u7b97',
  high: '\u9ad8\u9884\u7b97'
}
const crowdLabels = {
  avoid_crowded: '\u907f\u5f00\u62e5\u6324',
  popular: '\u504f\u597d\u70ed\u95e8',
  any: '\u90fd\u53ef\u4ee5'
}
const intensityLabels = {
  light: '\u8f7b\u677e',
  medium: '\u9002\u4e2d',
  high: '\u5145\u5b9e'
}

const budgetLabel = computed(() => budgetLabels[profile.value.budgetLevel] || budgetLabels.medium)
const crowdLabel = computed(() => crowdLabels[profile.value.crowdPreference] || crowdLabels.any)
const intensityLabel = computed(() => intensityLabels[profile.value.intensity] || intensityLabels.medium)

const filteredRecommendations = computed(() =>
  recommendations.value.filter(item => Number(item.scenicSpot.ticket || 0) <= maxTicket.value)
)

const hasMeaningfulProfile = (value) => {
  if (!value) return false
  return Boolean(
    value.preferredTags?.length ||
    value.preferredCategories?.length ||
    (value.budgetLevel && value.budgetLevel !== 'medium') ||
    (value.crowdPreference && value.crowdPreference !== 'any') ||
    (value.intensity && value.intensity !== 'medium')
  )
}

const readLocalProfile = () => {
  const raw = localStorage.getItem(STORAGE_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw)
  } catch (error) {
    localStorage.removeItem(STORAGE_KEY)
    return null
  }
}

const loadProfile = async () => {
  try {
    const data = await tourismApi.getProfilePreferences()
    if (data.exists && data.profile) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data.profile))
      profile.value = { ...defaultProfile(), ...data.profile }
      return true
    }
  } catch (error) {
    const local = readLocalProfile()
    if (local) {
      profile.value = { ...defaultProfile(), ...local }
      return hasMeaningfulProfile(local)
    }
    return false
  }

  const local = readLocalProfile()
  if (local) {
    profile.value = { ...defaultProfile(), ...local }
    return hasMeaningfulProfile(local)
  }
  profile.value = defaultProfile()
  return false
}

const normalizeRecommendation = (item) => {
  const scenicSpot = item.scenic_spot || item.scenicSpot || item
  return {
    scenicSpot,
    score: Number(item.score ?? scenicSpot.score ?? Number(scenicSpot.rating || 0) * 15),
    matchedTags: item.matchedTags || scenicSpot.tags?.slice?.(0, 2) || [],
    reason: item.reason || '基于综合评分推荐。'
  }
}

const fallbackRecommendations = () => fallbackSpots.slice(0, 8).map(spot => normalizeRecommendation({
  scenic_spot: spot,
  score: Number(spot.rating || 0) * 15,
  matchedTags: spot.tags?.slice?.(0, 2) || [],
  reason: '基于热门主题和综合评分推荐。'
}))

const loadRecommendations = async () => {
  const hasProfile = await loadProfile()
  sourceLabel.value = hasProfile ? '根据偏好' : '默认推荐'

  try {
    const data = await tourismApi.personalizedRecommendations({
      ...profile.value,
      limit: 12
    })
    recommendations.value = (data.recommendations || []).map(normalizeRecommendation)
  } catch (error) {
    recommendations.value = fallbackRecommendations()
    sourceLabel.value = '精选推荐'
  }
}

onMounted(loadRecommendations)
</script>
