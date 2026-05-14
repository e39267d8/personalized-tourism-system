<template>
  <div class="space-y-10">
    <section class="relative overflow-hidden rounded-md bg-slate-950 text-white">
      <img
        class="absolute inset-0 h-full w-full object-cover opacity-60"
        src="https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=1800&q=85"
        alt="北京城市旅行"
      >
      <div class="absolute inset-0 bg-gradient-to-r from-slate-950 via-slate-950/75 to-slate-950/20"></div>

      <div class="relative grid min-h-[520px] content-end px-5 py-8 sm:px-8 lg:grid-cols-[1fr_0.7fr] lg:items-end lg:gap-10">
        <div class="pb-4">
          <p class="text-sm font-semibold uppercase tracking-[0.2em] text-teal-200">TourPilot</p>
          <h1 class="mt-4 max-w-3xl text-4xl font-bold leading-tight tracking-tight sm:text-6xl">
            按你的偏好规划下一站
          </h1>
          <p class="mt-5 max-w-2xl text-base leading-7 text-slate-200">
            搜索目的地、保存旅游偏好、生成路线和预算方案。首页推荐会根据你的标签、预算和人流选择动态变化。
          </p>

          <form class="mt-7 max-w-2xl rounded-md bg-white p-2 shadow-xl" @submit.prevent="submitSearch">
            <div class="flex flex-col gap-2 sm:flex-row">
              <input
                v-model="searchQuery"
                class="h-12 flex-1 rounded-md border border-slate-200 px-4 text-sm text-slate-950 outline-none focus:border-teal-700"
                placeholder="搜索故宫、博物馆、摄影、低预算..."
                type="search"
              >
              <button class="rounded-md bg-teal-700 px-5 py-3 text-sm font-semibold text-white hover:bg-teal-800">
                开始搜索
              </button>
            </div>
          </form>
        </div>

        <div class="hidden rounded-md bg-white/95 p-5 text-slate-950 shadow-xl lg:block">
          <div class="text-sm font-semibold text-slate-500">今日路线灵感</div>
          <h2 class="mt-2 text-2xl font-bold">{{ featuredRoute?.title || '中轴线经典一日' }}</h2>
          <p class="mt-3 text-sm leading-6 text-slate-600">
            {{ featuredRoute?.stops?.join(' -> ') || '前门 -> 天安门 -> 故宫 -> 景山' }}
          </p>
          <div class="mt-5 grid grid-cols-3 gap-3 text-center">
            <div class="rounded-md bg-slate-100 p-3">
              <div class="text-xs text-slate-500">距离</div>
              <div class="mt-1 font-bold">{{ featuredRoute?.distance || '3.2 km' }}</div>
            </div>
            <div class="rounded-md bg-slate-100 p-3">
              <div class="text-xs text-slate-500">时长</div>
              <div class="mt-1 font-bold">{{ featuredRoute?.time || '4 小时' }}</div>
            </div>
            <div class="rounded-md bg-slate-100 p-3">
              <div class="text-xs text-slate-500">预算</div>
              <div class="mt-1 font-bold">¥{{ featuredRoute?.cost || 92 }}</div>
            </div>
          </div>
          <router-link to="/route" class="mt-5 block rounded-md bg-slate-900 px-4 py-2.5 text-center text-sm font-semibold text-white hover:bg-slate-800">
            打开路线规划
          </router-link>
        </div>
      </div>
    </section>

    <section class="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
      <button
        v-for="item in quickSearches"
        :key="item.query"
        class="rounded-md border border-slate-200 bg-white p-4 text-left transition hover:-translate-y-0.5 hover:border-teal-700 hover:shadow-sm"
        @click="goSearch(item.query)"
      >
        <div class="font-semibold">{{ item.title }}</div>
        <p class="mt-1 text-sm text-slate-500">{{ item.copy }}</p>
      </button>
    </section>

    <section class="grid gap-6 lg:grid-cols-[1.35fr_0.65fr]">
      <div>
        <div class="flex flex-wrap items-end justify-between gap-4">
          <div>
            <h2 class="text-2xl font-bold">个性化推荐目的地</h2>
            <p class="mt-2 text-sm text-slate-500">{{ recommendationSubtitle }}</p>
          </div>
          <router-link to="/profile" class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">
            {{ hasUserProfile ? '修改偏好' : '完善偏好' }}
          </router-link>
        </div>

        <div class="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          <router-link
            v-for="item in recommendations"
            :key="item.scenicSpot.id"
            :to="`/spots/${item.scenicSpot.id}`"
            class="group overflow-hidden rounded-md border border-slate-200 bg-white transition hover:-translate-y-0.5 hover:border-teal-700 hover:shadow-sm"
          >
            <div class="relative">
              <img
                :src="spotImageUrl(item.scenicSpot)"
                :alt="item.scenicSpot.name"
                class="h-44 w-full object-cover transition group-hover:scale-[1.02]"
                @error="event => handleSpotImageError(event, item.scenicSpot)"
              >
              <div class="absolute right-3 top-3 rounded-md bg-white/95 px-2 py-1 text-sm font-bold text-amber-700">
                {{ Math.round(item.score) }}
              </div>
            </div>
            <div class="p-4">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <h3 class="font-semibold text-slate-950">{{ item.scenicSpot.name }}</h3>
                  <div class="mt-1 text-sm text-slate-500">{{ item.scenicSpot.category }} · {{ item.scenicSpot.district }}</div>
                </div>
                <span class="rounded-md bg-slate-100 px-2 py-1 text-sm font-bold text-slate-700">{{ item.scenicSpot.rating }}</span>
              </div>
              <p class="mt-3 line-clamp-2 text-sm leading-6 text-slate-500">{{ item.scenicSpot.description }}</p>
              <div class="mt-4 flex flex-wrap gap-2">
                <span v-for="tag in item.matchedTags" :key="tag" class="rounded-md bg-teal-50 px-2 py-1 text-xs font-medium text-teal-800">{{ tag }}</span>
                <span v-if="!item.matchedTags.length" class="rounded-md bg-slate-100 px-2 py-1 text-xs text-slate-600">综合推荐</span>
              </div>
              <p class="mt-3 text-sm leading-6 text-slate-600">{{ item.reason }}</p>
              <div class="mt-4 flex items-center justify-between border-t border-slate-100 pt-3 text-sm text-slate-500">
                <span>门票 ¥{{ item.scenicSpot.ticket }}</span>
                <span>{{ item.scenicSpot.duration }}</span>
              </div>
            </div>
          </router-link>
        </div>
      </div>

      <aside class="space-y-4">
        <div class="rounded-md border border-slate-200 bg-white p-5">
          <h2 class="text-lg font-semibold">按预算找目的地</h2>
          <div class="mt-4">
            <div class="flex items-center justify-between">
              <span class="text-sm text-slate-500">单日预算</span>
              <span class="text-2xl font-bold">¥{{ budget }}</span>
            </div>
            <input v-model.number="budget" type="range" min="60" max="500" step="10" class="mt-4 w-full accent-teal-700">
          </div>
          <div class="mt-4 space-y-3">
            <div v-for="plan in affordablePlans" :key="plan.id" class="rounded-md bg-slate-50 p-3">
              <div class="font-semibold">{{ plan.title }}</div>
              <div class="mt-1 text-sm text-slate-500">{{ plan.route }}</div>
            </div>
          </div>
          <router-link to="/recommend" class="mt-4 block rounded-md bg-slate-900 px-4 py-2.5 text-center text-sm font-semibold text-white hover:bg-slate-800">
            详细预算推荐
          </router-link>
        </div>

        <div class="rounded-md border border-slate-200 bg-white p-5">
          <h2 class="text-lg font-semibold">继续你的旅行</h2>
          <div class="mt-4 grid gap-3">
            <router-link to="/diary" class="rounded-md bg-slate-50 p-4 text-sm font-semibold hover:bg-slate-100">写一篇旅行日记</router-link>
            <router-link to="/profile" class="rounded-md bg-slate-50 p-4 text-sm font-semibold hover:bg-slate-100">查看个人中心</router-link>
            <router-link to="/achievements" class="rounded-md bg-slate-50 p-4 text-sm font-semibold hover:bg-slate-100">查看旅行成就</router-link>
          </div>
        </div>
      </aside>
    </section>

    <section class="rounded-md border border-slate-200 bg-white p-5">
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h2 class="text-2xl font-bold">精选路线</h2>
        </div>
        <router-link to="/route" class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">
          打开地图
        </router-link>
      </div>

      <div class="mt-5 grid gap-4 lg:grid-cols-3">
        <article v-for="route in routes.slice(0, 3)" :key="route.id" class="rounded-md border border-slate-200 p-4">
          <h3 class="font-semibold">{{ route.title }}</h3>
          <p class="mt-2 line-clamp-2 text-sm leading-6 text-slate-500">{{ route.stops.join(' / ') }}</p>
          <div class="mt-4 flex items-center justify-between border-t border-slate-100 pt-3 text-sm text-slate-500">
            <span>{{ route.distance }}</span>
            <span>{{ route.time }}</span>
            <span>¥{{ route.cost }}</span>
          </div>
        </article>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { budgetPlans as fallbackBudgetPlans, routePlans as fallbackRoutes, scenicSpots as fallbackSpots } from '@/data/demoData'
import { tourismApi } from '@/services/tourismApi'
import { handleSpotImageError, spotImageUrl } from '@/utils/images'

const STORAGE_KEY = 'tourism_user_profile'
const router = useRouter()

const searchQuery = ref('')
const budget = ref(180)
const routes = ref(fallbackRoutes)
const plans = ref(fallbackBudgetPlans)
const recommendations = ref([])
const hasUserProfile = ref(false)
const activeProfile = ref(null)

const quickSearches = [
  { title: '第一次来北京', copy: '经典地标和中轴线', query: '中轴线' },
  { title: '雨天也能玩', copy: '博物馆和室内展览', query: '博物馆' },
  { title: '适合拍照', copy: '日落、公园、城市漫步', query: '摄影' },
  { title: '低预算路线', copy: '免费景点和步行路线', query: '低预算' }
]

const featuredRoute = computed(() => routes.value[0])
const affordablePlans = computed(() => plans.value.filter(plan => plan.budget <= budget.value).slice(0, 2))
const recommendationSubtitle = computed(() => {
  if (hasUserProfile.value) return '根据你的偏好问卷，按标签匹配、类型、评分、预算和人流综合排序。'
  return '结合热门主题、预算区间和游玩节奏，为你筛选适合的目的地。'
})

const submitSearch = () => {
  goSearch(searchQuery.value)
}

const goSearch = (query) => {
  const q = query.trim()
  router.push({ path: '/search', query: q ? { q } : {} })
}

const defaultProfile = () => ({
  preferredCategories: [],
  preferredTags: [],
  budgetLevel: 'medium',
  crowdPreference: 'any',
  intensity: 'medium'
})

const normalizeProfile = (value = {}) => ({
  ...defaultProfile(),
  ...value,
  preferredCategories: Array.isArray(value.preferredCategories) ? value.preferredCategories : [],
  preferredTags: Array.isArray(value.preferredTags) ? value.preferredTags : []
})

const hasMeaningfulProfile = (value) => Boolean(
  value?.preferredTags?.length ||
  value?.preferredCategories?.length ||
  (value?.budgetLevel && value.budgetLevel !== 'medium') ||
  (value?.crowdPreference && value.crowdPreference !== 'any') ||
  (value?.intensity && value.intensity !== 'medium')
)

const readLocalUserProfile = () => {
  const raw = localStorage.getItem(STORAGE_KEY)
  if (!raw) return null
  try {
    return normalizeProfile(JSON.parse(raw))
  } catch (error) {
    localStorage.removeItem(STORAGE_KEY)
    return null
  }
}

const readUserProfile = async () => {
  const local = readLocalUserProfile()
  if (local && hasMeaningfulProfile(local)) return local

  try {
    const data = await tourismApi.getProfilePreferences()
    const remote = data.exists && data.profile ? normalizeProfile(data.profile) : null
    if (remote && hasMeaningfulProfile(remote)) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(remote))
      return remote
    }
    if (local && hasMeaningfulProfile(local)) return local
    return remote
  } catch (error) {
    return local
  }
}

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

const budgetMaxTicket = (value) => ({
  low: 60,
  medium: 120,
  high: 300
})[value?.budgetLevel] || 120

const durationHours = (value) => {
  const match = String(value || '').match(/[\d.]+/)
  return match ? Number(match[0]) : 2
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

const preferenceScore = (spot, profile) => {
  const prefs = normalizeProfile(profile)
  const text = spotText(spot)
  const categories = prefs.preferredCategories.filter(category =>
    (categoryAliases[category] || [category]).some(alias => text.includes(alias))
  )
  const tags = prefs.preferredTags.filter(tag => text.includes(tag))
  const ticket = Number(spot.ticket || 0)
  const hours = durationHours(spot.duration)
  const crowd = String(spot.crowd || '')
  let score = Number(spot.rating || 0) * 10

  score += categories.length * 18
  score += tags.length * 14
  score += ticket <= budgetMaxTicket(prefs) ? 12 : -Math.min(18, Math.ceil((ticket - budgetMaxTicket(prefs)) / 10))

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

const recommendationReason = (spot, profile, matches) => {
  const prefs = normalizeProfile(profile)
  const parts = []
  if (matches.categories.length) parts.push(`匹配你的「${matches.categories.join('、')}」类型偏好`)
  if (matches.tags.length) parts.push(`命中「${matches.tags.join('、')}」标签`)
  if (Number(spot.ticket || 0) <= budgetMaxTicket(prefs)) parts.push('门票符合当前预算')
  if (prefs.crowdPreference === 'avoid_crowded') parts.push('更适合避开拥挤的人流选择')
  if (prefs.crowdPreference === 'popular') parts.push('兼顾热门程度和评分表现')
  if (prefs.intensity === 'light') parts.push('游玩节奏轻松')
  if (prefs.intensity === 'high') parts.push('适合更充实的行程')
  return `${(parts.length ? parts.slice(0, 3) : ['综合评分、成本和游玩节奏更均衡']).join('，')}。`
}

const normalizeRecommendation = (item) => {
  const scenicSpot = item.scenic_spot || item.scenicSpot || item
  const profile = activeProfile.value || defaultProfile()
  const localMatch = preferenceScore(scenicSpot, profile)
  const backendScore = Number(item.score ?? scenicSpot.score ?? 0)
  const score = backendScore
    ? Math.round(localMatch.score * 0.85 + Math.min(100, backendScore) * 0.15)
    : localMatch.score
  return {
    scenicSpot,
    score,
    matchedTags: unique([...localMatch.categories, ...localMatch.tags, ...spotTags(scenicSpot)]).slice(0, 3),
    reason: recommendationReason(scenicSpot, profile, localMatch)
  }
}

const fallbackRecommendations = () =>
  fallbackSpots
    .map((spot) => normalizeRecommendation({ scenic_spot: spot }))
    .sort((left, right) => right.score - left.score)
    .slice(0, 6)

const loadRecommendations = async () => {
  const profile = await readUserProfile()
  activeProfile.value = normalizeProfile(profile || {})
  hasUserProfile.value = hasMeaningfulProfile(activeProfile.value)

  try {
    const payload = hasUserProfile.value ? { ...activeProfile.value, limit: 6 } : { limit: 6 }
    const data = await tourismApi.personalizedRecommendations(payload)
    const items = (data.recommendations || []).map(normalizeRecommendation)
    recommendations.value = (items.length ? items : fallbackRecommendations())
      .sort((left, right) => right.score - left.score)
      .slice(0, 6)
  } catch (error) {
    recommendations.value = fallbackRecommendations()
  }
}

onMounted(async () => {
  await loadRecommendations()

  try {
    const [routeData, budgetData] = await Promise.all([
      tourismApi.routes(),
      tourismApi.budgetPlans({ budget: 500 })
    ])
    routes.value = routeData.items?.length ? routeData.items : fallbackRoutes
    plans.value = budgetData.items?.length ? budgetData.items : fallbackBudgetPlans
  } catch (error) {
    routes.value = fallbackRoutes
    plans.value = fallbackBudgetPlans
  }
})
</script>
