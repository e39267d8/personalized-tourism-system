<template>
  <div class="space-y-6">
    <section class="grid gap-6 xl:grid-cols-[0.8fr_1.2fr]">
      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-start justify-between gap-4">
          <div>
            <h1 class="text-2xl font-bold text-slate-950">预算决定目的地</h1>
            <p class="mt-2 text-sm leading-6 text-slate-500">输入可接受预算，系统按门票、交通、餐饮和体力成本筛选路线。</p>
          </div>
          <span class="rounded-md bg-teal-50 px-2.5 py-1 text-sm font-semibold text-teal-800">创新功能</span>
        </div>

        <div class="mt-6">
          <div class="flex items-center justify-between">
            <label class="text-sm font-semibold text-slate-700">单日预算</label>
            <span class="text-2xl font-bold text-slate-950">¥{{ budget }}</span>
          </div>
          <input v-model.number="budget" type="range" min="60" max="500" step="10" class="mt-4 w-full accent-teal-700">
          <div class="mt-2 flex justify-between text-xs text-slate-400">
            <span>节省</span>
            <span>均衡</span>
            <span>舒适</span>
          </div>
        </div>

        <div class="mt-6">
          <label class="text-sm font-semibold text-slate-700">旅行偏好</label>
          <div class="mt-3 grid grid-cols-2 gap-2">
            <button
              v-for="option in preferenceOptions"
              :key="option"
              @click="togglePreference(option)"
              :class="[
                'rounded-md border px-3 py-2 text-sm font-medium transition',
                preferences.includes(option)
                  ? 'border-slate-900 bg-slate-900 text-white'
                  : 'border-slate-300 bg-white text-slate-600 hover:bg-slate-100'
              ]"
            >
              {{ option }}
            </button>
          </div>
        </div>

        <div class="mt-6 rounded-md bg-slate-50 p-4">
          <div class="text-sm font-semibold text-slate-950">当前策略</div>
          <p class="mt-2 text-sm leading-6 text-slate-600">{{ strategyCopy }}</p>
        </div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 class="text-lg font-semibold text-slate-950">推荐路线</h2>
            <p class="mt-1 text-sm text-slate-500">预算内优先展示，可用作答辩演示入口。</p>
          </div>
          <div class="rounded-md border border-slate-200 px-3 py-2 text-sm text-slate-600">
            匹配 {{ filteredPlans.length }} 条
          </div>
        </div>

        <div class="mt-5 grid gap-4">
          <article
            v-for="plan in filteredPlans"
            :key="plan.id"
            class="rounded-md border border-slate-200 p-4"
          >
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div>
                <div class="text-sm font-semibold text-teal-700">{{ plan.label }}</div>
                <h3 class="mt-1 text-xl font-bold text-slate-950">{{ plan.title }}</h3>
                <p class="mt-2 text-sm leading-6 text-slate-500">{{ plan.route }}</p>
              </div>
              <div class="rounded-md bg-amber-50 px-3 py-2 text-right">
                <div class="text-xs font-medium text-amber-700">预计成本</div>
                <div class="text-2xl font-bold text-amber-900">¥{{ plan.budget }}</div>
              </div>
            </div>
            <div class="mt-4 grid gap-3 sm:grid-cols-3">
              <div v-for="item in plan.includes" :key="item" class="rounded-md bg-slate-50 px-3 py-2 text-sm text-slate-600">{{ item }}</div>
            </div>
            <div class="mt-4 text-sm text-slate-600">{{ plan.tradeoff }}</div>
          </article>

          <div v-if="!filteredPlans.length" class="rounded-md border border-dashed border-slate-300 p-8 text-center">
            <div class="text-lg font-semibold text-slate-950">当前预算太紧</div>
            <p class="mt-2 text-sm text-slate-500">建议提高预算到 ¥80 以上，或只保留免费景点和步行路线。</p>
          </div>
        </div>
      </div>
    </section>

    <section class="rounded-md border border-slate-200 bg-white p-5">
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h2 class="text-lg font-semibold text-slate-950">景点候选池</h2>
          <p class="mt-1 text-sm text-slate-500">按偏好、评分、门票、拥挤度综合排序。</p>
        </div>
        <div class="flex gap-2">
          <button
            v-for="tab in tabs"
            :key="tab"
            @click="activeTab = tab"
            :class="[
              'rounded-md px-3 py-2 text-sm font-medium',
              activeTab === tab ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            ]"
          >
            {{ tab }}
          </button>
        </div>
      </div>

        <div class="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <article v-for="spot in rankedSpots" :key="spot.id" class="overflow-hidden rounded-md border border-slate-200">
          <img :src="spot.image" :alt="spot.name" class="h-40 w-full object-cover">
          <div class="p-4">
            <div class="flex items-start justify-between gap-3">
              <div>
                <h3 class="font-semibold text-slate-950">{{ spot.name }}</h3>
                <div class="mt-1 text-sm text-slate-500">{{ spot.category }} · {{ spot.district }}</div>
              </div>
              <span class="rounded-md bg-slate-100 px-2 py-1 text-sm font-bold text-slate-700">{{ spot.rating }}</span>
            </div>
            <p class="mt-3 line-clamp-2 text-sm leading-6 text-slate-500">{{ spot.description }}</p>
            <div class="mt-4 flex flex-wrap gap-2">
              <span v-for="tag in spot.tags" :key="tag" class="rounded-md bg-teal-50 px-2 py-1 text-xs font-medium text-teal-800">{{ tag }}</span>
            </div>
            <div class="mt-4 flex items-center justify-between border-t border-slate-100 pt-3 text-sm text-slate-500">
              <span>门票 ¥{{ spot.ticket }}</span>
              <span>{{ spot.duration }} · 拥挤 {{ spot.crowd }}</span>
            </div>
          </div>
        </article>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { budgetPlans, scenicSpots } from '@/data/demoData'
import { tourismApi } from '@/services/tourismApi'

const budget = ref(180)
const activeTab = ref('智能排序')
const tabs = ['智能排序', '低预算', '室内', '摄影']
const preferenceOptions = ['历史文化', '博物馆', 'citywalk', '摄影', '亲子', '夜游']
const preferences = ref(['历史文化', 'citywalk'])
const plans = ref(budgetPlans)
const spots = ref(scenicSpots)

const togglePreference = (option) => {
  preferences.value = preferences.value.includes(option)
    ? preferences.value.filter(item => item !== option)
    : [...preferences.value, option]
}

const filteredPlans = computed(() => plans.value.filter(plan => plan.budget <= budget.value))

const strategyCopy = computed(() => {
  if (budget.value < 100) return '优先免费景点、步行路线和低成本餐饮，适合学生小型演示。'
  if (budget.value < 250) return '保留核心门票和适度餐饮，是最适合课程答辩的均衡方案。'
  return '允许更舒适的交通和餐饮安排，系统会降低拥挤转场和体力消耗。'
})

const rankedSpots = computed(() => {
  let list = [...spots.value]
  if (activeTab.value === '低预算') list = list.filter(spot => spot.ticket <= 20)
  if (activeTab.value === '室内') list = list.filter(spot => spot.category === '博物馆')
  if (activeTab.value === '摄影') list = list.filter(spot => spot.tags.includes('摄影') || spot.category === '观景摄影')
  return list.sort((a, b) => b.rating - a.rating)
})

const loadFromApi = async () => {
  try {
    const [budgetData, scenicData] = await Promise.all([
      tourismApi.budgetPlans({ budget: budget.value }),
      tourismApi.scenicSpots()
    ])
    plans.value = budgetData.items?.length ? budgetData.items : budgetPlans
    spots.value = scenicData.items?.length ? scenicData.items : scenicSpots
  } catch (error) {
    plans.value = budgetPlans
    spots.value = scenicSpots
  }
}

onMounted(loadFromApi)
watch(budget, loadFromApi)
</script>
