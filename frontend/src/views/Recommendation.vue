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

const normalizeProfile = (value = {}) => ({
  ...defaultProfile(),
  ...value,
  preferredCategories: Array.isArray(value.preferredCategories) ? value.preferredCategories : [],
  preferredTags: Array.isArray(value.preferredTags) ? value.preferredTags : []
})

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

const budgetMaxTicket = (value) => ({
  low: 60,
  medium: 120,
  high: 300
})[value?.budgetLevel] || 120

const categoryAliases = {
  历史古迹: ['历史古迹', '历史', '古建', '世界遗产', '中轴线', '故宫'],
  博物馆: ['博物馆', '展览', '室内'],
  自然公园: ['自然公园', '城市公园', '公园', '自然', '日落', '轻徒步'],
  城市地标: ['城市地标', '地标', '中轴线', '步行'],
  商业街区: ['商业街区', '购物', '夜游', '美食'],
  美食街区: ['美食街区', '美食', '夜游', '商业街区'],
  摄影打卡: ['摄影打卡', '摄影', '观景摄影', '日落', '俯瞰'],
  亲子休闲: ['亲子休闲', '亲子', '室内', '公园', '低预算'],
  城市漫步: ['城市漫步', 'citywalk', '胡同', '步行', '轻徒步']
}

const spotTags = (spot) =>
  Array.isArray(spot.tags) ? spot.tags : String(spot.tags || '').split(/[,\s，、]+/).filter(Boolean)

const spotText = (spot) => [
  spot.name,
  spot.category,
  spot.district,
  spot.description,
  ...spotTags(spot)
].filter(Boolean).join(' ')

const unique = (items) => [...new Set(items.filter(Boolean))]

const matchedCategories = (spot, selectedCategories) => {
  const text = spotText(spot)
  return selectedCategories.filter(category => {
    const aliases = categoryAliases[category] || [category]
    return aliases.some(alias => text.includes(alias))
  })
}

const matchedTags = (spot, selectedTags) => {
  const text = spotText(spot)
  return selectedTags.filter(tag => text.includes(tag))
}

const durationHours = (value) => {
  const match = String(value || '').match(/[\d.]+/)
  return match ? Number(match[0]) : 2
}

const preferenceScore = (spot, prefs) => {
  const categories = matchedCategories(spot, prefs.preferredCategories)
  const tags = matchedTags(spot, prefs.preferredTags)
  const ticket = Number(spot.ticket || 0)
  const hours = durationHours(spot.duration)
  const crowd = String(spot.crowd || '')
  let score = Number(spot.rating || 0) * 10

  score += categories.length * 18
  score += tags.length * 14

  if (ticket <= budgetMaxTicket(prefs)) score += 12
  else score -= Math.min(18, Math.ceil((ticket - budgetMaxTicket(prefs)) / 10))

  if (prefs.crowdPreference === 'avoid_crowded') {
    if (crowd.includes('低')) score += 12
    else if (crowd.includes('中')) score += 4
    else if (crowd.includes('高')) score -= 10
  }
  if (prefs.crowdPreference === 'popular') {
    if (crowd.includes('高')) score += 10
    else if (crowd.includes('中')) score += 6
    if (Number(spot.rating || 0) >= 4.6) score += 6
  }

  if (prefs.intensity === 'light') {
    if (hours <= 2) score += 10
    else if (hours <= 3) score += 3
    else score -= 8
  }
  if (prefs.intensity === 'high') {
    if (hours >= 3) score += 10
    else if (hours >= 2.5) score += 6
  }
  if (prefs.intensity === 'medium' && hours >= 1.5 && hours <= 3) score += 5

  return {
    score: Math.max(1, Math.min(99, Math.round(score))),
    categories,
    tags
  }
}

const recommendationReason = (spot, prefs, matches) => {
  const parts = []
  if (matches.categories.length) parts.push(`匹配你的「${matches.categories.join('、')}」类型偏好`)
  if (matches.tags.length) parts.push(`命中「${matches.tags.join('、')}」标签`)

  const ticket = Number(spot.ticket || 0)
  if (ticket <= budgetMaxTicket(prefs)) parts.push(`门票符合${budgetLabels[prefs.budgetLevel] || budgetLabels.medium}`)
  if (prefs.crowdPreference === 'avoid_crowded') parts.push('更适合避开拥挤的人流选择')
  if (prefs.crowdPreference === 'popular') parts.push('兼顾热门程度和评分表现')
  if (prefs.intensity === 'light') parts.push('游玩节奏轻松')
  if (prefs.intensity === 'high') parts.push('适合更充实的行程')

  return `${(parts.length ? parts.slice(0, 3) : ['综合评分、成本和游玩节奏更均衡']).join('，')}。`
}

const personalizedRecommendation = (spot, item = {}) => {
  const prefs = normalizeProfile(profile.value)
  const localMatch = preferenceScore(spot, prefs)
  const backendScore = Number(item.score ?? spot.score ?? 0)
  const score = backendScore
    ? Math.round(localMatch.score * 0.85 + Math.min(100, backendScore) * 0.15)
    : localMatch.score
  const localTags = unique([
    ...localMatch.categories,
    ...localMatch.tags,
    ...spotTags(spot)
  ]).slice(0, 3)

  return {
    scenicSpot: spot,
    score,
    matchedTags: localTags,
    reason: recommendationReason(spot, prefs, localMatch)
  }
}

const loadProfile = async () => {
  const local = readLocalProfile()
  if (local && hasMeaningfulProfile(local)) {
    profile.value = normalizeProfile(local)
    return true
  }

  try {
    const data = await tourismApi.getProfilePreferences()
    const remote = data.exists && data.profile ? normalizeProfile(data.profile) : null
    if (remote && hasMeaningfulProfile(remote)) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(remote))
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

const normalizeRecommendation = (item) => {
  const scenicSpot = item.scenic_spot || item.scenicSpot || item
  return personalizedRecommendation(scenicSpot, item)
}

const fallbackRecommendations = () =>
  fallbackSpots
    .map(spot => normalizeRecommendation({ scenic_spot: spot }))
    .sort((left, right) => right.score - left.score)

const loadRecommendations = async () => {
  const hasProfile = await loadProfile()
  sourceLabel.value = hasProfile ? '根据偏好' : '默认推荐'
  maxTicket.value = budgetMaxTicket(profile.value)

  try {
    const data = await tourismApi.personalizedRecommendations({
      ...profile.value,
      limit: 12
    })
    const items = (data.recommendations || []).map(normalizeRecommendation)
    recommendations.value = (items.length ? items : fallbackRecommendations())
      .sort((left, right) => right.score - left.score)
  } catch (error) {
    recommendations.value = fallbackRecommendations()
    sourceLabel.value = hasProfile ? '根据偏好' : '默认推荐'
  }
}

onMounted(loadRecommendations)
</script>
