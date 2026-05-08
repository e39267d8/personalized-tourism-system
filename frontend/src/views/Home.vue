<template>
  <div class="space-y-10">
    <section class="relative overflow-hidden rounded-md bg-slate-950 text-white">
      <img
        class="absolute inset-0 h-full w-full object-cover opacity-60"
        src="https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=1800&q=85"
        alt="北京城市旅行"
      >
      <div class="absolute inset-0 bg-gradient-to-r from-slate-950 via-slate-950/70 to-slate-950/10"></div>

      <div class="relative grid min-h-[520px] content-end px-5 py-8 sm:px-8 lg:grid-cols-[0.95fr_0.75fr] lg:items-end lg:gap-10">
        <div class="pb-4">
          <p class="text-sm font-semibold uppercase tracking-[0.2em] text-teal-200">Beijing Travel Planner</p>
          <h1 class="mt-4 max-w-3xl text-4xl font-bold leading-tight tracking-tight sm:text-6xl">
            找到适合你的北京一日路线
          </h1>
          <p class="mt-5 max-w-2xl text-base leading-7 text-slate-200">
            搜索景点，比较预算，规划路线，写下旅行记录。TourPilot 把目的地、路线和个人旅行档案放在一个清晰的网站里。
          </p>

          <form class="mt-7 max-w-2xl rounded-md bg-white p-2 shadow-xl" @submit.prevent="submitSearch">
            <div class="flex flex-col gap-2 sm:flex-row">
              <input
                v-model="searchQuery"
                class="h-12 flex-1 rounded-md border border-slate-200 px-4 text-sm text-slate-950 outline-none focus:border-teal-700"
                placeholder="搜索故宫、博物馆、citywalk、低预算..."
                type="search"
              >
              <button class="rounded-md bg-teal-700 px-5 py-3 text-sm font-semibold text-white hover:bg-teal-800">
                开始搜索
              </button>
            </div>
          </form>
        </div>

        <div class="hidden rounded-md bg-white/95 p-5 text-slate-950 shadow-xl lg:block">
          <div class="text-sm font-semibold text-slate-500">今天推荐</div>
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
            查看路线
          </router-link>
        </div>
      </div>
    </section>

    <section class="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
      <button
        v-for="item in quickSearches"
        :key="item.query"
        @click="goSearch(item.query)"
        class="rounded-md border border-slate-200 bg-white p-4 text-left transition hover:-translate-y-0.5 hover:border-teal-700 hover:shadow-sm"
      >
        <div class="font-semibold">{{ item.title }}</div>
        <p class="mt-1 text-sm text-slate-500">{{ item.copy }}</p>
      </button>
    </section>

    <section class="grid gap-6 lg:grid-cols-[1.35fr_0.65fr]">
      <div>
        <div class="flex flex-wrap items-end justify-between gap-4">
          <div>
            <h2 class="text-2xl font-bold">热门目的地</h2>
            <p class="mt-2 text-sm text-slate-500">按评分、标签和旅行场景挑选适合你的景点。</p>
          </div>
          <router-link to="/search" class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">
            查看全部
          </router-link>
        </div>

        <div class="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          <router-link
            v-for="spot in spots.slice(0, 6)"
            :key="spot.id"
            :to="`/spots/${spot.id}`"
            class="group overflow-hidden rounded-md border border-slate-200 bg-white transition hover:-translate-y-0.5 hover:border-teal-700 hover:shadow-sm"
          >
            <div class="relative">
              <img :src="spot.image" :alt="spot.name" class="h-44 w-full object-cover transition group-hover:scale-[1.02]">
              <div class="absolute right-3 top-3 rounded-md bg-white/95 px-2 py-1 text-sm font-bold text-amber-700">{{ spot.rating }}</div>
            </div>
            <div class="p-4">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <h3 class="font-semibold text-slate-950">{{ spot.name }}</h3>
                  <div class="mt-1 text-sm text-slate-500">{{ spot.category }} · {{ spot.district }}</div>
                </div>
              </div>
              <p class="mt-3 line-clamp-2 text-sm leading-6 text-slate-500">{{ spot.description }}</p>
              <div class="mt-4 flex items-center justify-between border-t border-slate-100 pt-3 text-sm text-slate-500">
                <span>门票 ¥{{ spot.ticket }}</span>
                <span>{{ spot.duration }}</span>
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
            详细规划
          </router-link>
        </div>

        <div class="rounded-md border border-slate-200 bg-white p-5">
          <h2 class="text-lg font-semibold">继续你的旅行</h2>
          <div class="mt-4 grid gap-3">
            <router-link to="/diary" class="rounded-md bg-slate-50 p-4 text-sm font-semibold hover:bg-slate-100">写一篇旅行日记</router-link>
            <router-link to="/profile" class="rounded-md bg-slate-50 p-4 text-sm font-semibold hover:bg-slate-100">查看个人旅行档案</router-link>
            <router-link to="/achievements" class="rounded-md bg-slate-50 p-4 text-sm font-semibold hover:bg-slate-100">查看旅行成就</router-link>
          </div>
        </div>
      </aside>
    </section>

    <section class="rounded-md border border-slate-200 bg-white p-5">
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h2 class="text-2xl font-bold">精选路线</h2>
          <p class="mt-2 text-sm text-slate-500">把几个景点串成一条能实际执行的行程。</p>
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

const router = useRouter()

const searchQuery = ref('')
const budget = ref(180)
const spots = ref(fallbackSpots)
const routes = ref(fallbackRoutes)
const plans = ref(fallbackBudgetPlans)

const quickSearches = [
  { title: '第一次来北京', copy: '经典地标和中轴线', query: '中轴线' },
  { title: '雨天也能玩', copy: '博物馆和室内展览', query: '博物馆' },
  { title: '适合拍照', copy: '日落、公园、citywalk', query: '摄影' },
  { title: '低预算路线', copy: '免费景点和步行路线', query: '低预算' }
]

const featuredRoute = computed(() => routes.value[0])
const affordablePlans = computed(() => plans.value.filter(plan => plan.budget <= budget.value).slice(0, 2))

const submitSearch = () => {
  goSearch(searchQuery.value)
}

const goSearch = (query) => {
  const q = query.trim()
  router.push({ path: '/search', query: q ? { q } : {} })
}

onMounted(async () => {
  try {
    const [scenic, routeData, budgetData] = await Promise.all([
      tourismApi.scenicSpots(),
      tourismApi.routes(),
      tourismApi.budgetPlans({ budget: 500 })
    ])
    spots.value = scenic.items?.length ? scenic.items : fallbackSpots
    routes.value = routeData.items?.length ? routeData.items : fallbackRoutes
    plans.value = budgetData.items?.length ? budgetData.items : fallbackBudgetPlans
  } catch (error) {
    spots.value = fallbackSpots
    routes.value = fallbackRoutes
    plans.value = fallbackBudgetPlans
  }
})
</script>
