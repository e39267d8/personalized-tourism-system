<template>
  <section class="rounded-md border border-slate-200 bg-white p-5">
    <div class="flex flex-wrap items-start justify-between gap-3">
      <div>
        <h2 class="text-lg font-semibold text-slate-950">室内导航</h2>
        <p class="mt-1 text-sm leading-6 text-slate-500">
          {{ selectedBuilding ? selectedBuilding.description || '选择楼层、起点和终点生成室内路线。' : '选择楼层、起点和终点生成室内路线。' }}
        </p>
      </div>
      <span class="rounded-md bg-slate-100 px-2.5 py-1 text-sm font-semibold text-slate-700">
        {{ indoorStatusLabel }}
      </span>
    </div>

    <div v-if="error" class="mt-4 rounded-md border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
      {{ error }}
    </div>

    <div v-if="loading" class="mt-4 rounded-md border border-dashed border-slate-300 p-5 text-sm text-slate-500">
      正在读取室内导航数据...
    </div>

    <div v-else-if="!buildings.length" class="mt-4 rounded-md border border-dashed border-slate-300 p-5 text-sm leading-6 text-slate-500">
      当前景点还没有接入室内导航建筑。系统会保持空状态，不影响景点详情和景区内部导航。
    </div>

    <template v-else>
      <div class="mt-4 grid gap-4 md:grid-cols-2">
        <div>
          <label class="text-sm font-semibold text-slate-700">建筑</label>
          <select
            v-model="selectedBuildingId"
            class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
          >
            <option v-for="building in buildings" :key="building.id" :value="String(building.id)">
              {{ building.name }}
            </option>
          </select>
        </div>

        <div>
          <label class="text-sm font-semibold text-slate-700">楼层</label>
          <select
            v-model="selectedFloor"
            class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
          >
            <option value="">全部楼层</option>
            <option v-for="floor in floors" :key="floor.id" :value="floor.floorCode">
              {{ floor.floorName }} ({{ floor.floorCode }})
            </option>
          </select>
        </div>

        <div>
          <label class="text-sm font-semibold text-slate-700">设施类型</label>
          <select
            v-model="selectedType"
            class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
          >
            <option value="">全部类型</option>
            <option v-for="type in featureTypes" :key="type.type" :value="type.type">
              {{ type.label }} ({{ type.count }})
            </option>
          </select>
        </div>

        <div>
          <label class="text-sm font-semibold text-slate-700">策略</label>
          <select
            v-model="strategy"
            class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
          >
            <option value="time">时间优先</option>
            <option value="distance">距离优先</option>
          </select>
        </div>

        <div>
          <label class="text-sm font-semibold text-slate-700">起点</label>
          <select
            v-model="startFeatureId"
            class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
          >
            <option v-for="feature in visibleFeatures" :key="feature.id" :value="String(feature.id)">
              {{ feature.name }} · {{ feature.floorCode }}
            </option>
          </select>
        </div>

        <div>
          <label class="text-sm font-semibold text-slate-700">终点</label>
          <select
            v-model="endFeatureId"
            class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
          >
            <option v-for="feature in visibleFeatures" :key="feature.id" :value="String(feature.id)">
              {{ feature.name }} · {{ feature.floorCode }}
            </option>
          </select>
        </div>
      </div>

      <button
        type="button"
        class="mt-4 w-full rounded-md bg-teal-700 px-4 py-2.5 text-sm font-semibold text-white hover:bg-teal-800 disabled:cursor-not-allowed disabled:bg-slate-400"
        :disabled="routeLoading || !canPlanRoute"
        @click="planRoute"
      >
        {{ routeLoading ? '规划中...' : '规划室内路线' }}
      </button>

      <div v-if="selectedBuilding" class="mt-4 grid gap-3 text-sm sm:grid-cols-3">
        <div class="rounded-md bg-slate-50 p-3">
          <div class="text-xs text-slate-500">Provider</div>
          <div class="mt-1 font-semibold text-slate-900">{{ selectedBuilding.provider }}</div>
        </div>
        <div class="rounded-md bg-slate-50 p-3">
          <div class="text-xs text-slate-500">楼层/点位</div>
          <div class="mt-1 font-semibold text-slate-900">{{ selectedBuilding.floorCount }} / {{ selectedBuilding.featureCount }}</div>
        </div>
        <div class="rounded-md bg-slate-50 p-3">
          <div class="text-xs text-slate-500">高德室内</div>
          <div class="mt-1 font-semibold text-slate-900">{{ selectedBuilding.hasIndoorMap ? '已标记' : '本地图兜底' }}</div>
        </div>
      </div>

      <div v-if="route" class="mt-5 rounded-md bg-slate-50 p-4">
        <div class="grid gap-3 sm:grid-cols-4">
          <div>
            <div class="text-xs text-slate-500">距离</div>
            <div class="mt-1 font-bold text-slate-950">{{ route.distanceMeters }} m</div>
          </div>
          <div>
            <div class="text-xs text-slate-500">耗时</div>
            <div class="mt-1 font-bold text-slate-950">{{ durationLabel(route.durationSeconds) }}</div>
          </div>
          <div>
            <div class="text-xs text-slate-500">算法</div>
            <div class="mt-1 font-bold text-slate-950">{{ route.algorithm }}</div>
          </div>
          <div>
            <div class="text-xs text-slate-500">Fallback</div>
            <div class="mt-1 font-bold text-slate-950">{{ route.fallbackUsed ? '是' : '否' }}</div>
          </div>
        </div>

        <ol class="mt-4 space-y-2">
          <li
            v-for="step in route.steps"
            :key="`${step.order}-${step.fromFeatureId}-${step.toFeatureId}`"
            class="rounded-md border border-slate-200 bg-white p-3 text-sm leading-6 text-slate-700"
          >
            <span class="font-semibold text-slate-950">{{ step.order }}.</span>
            {{ step.instruction }}
            <span class="text-slate-400"> · {{ step.distanceMeters }} m · {{ durationLabel(step.durationSeconds) }}</span>
          </li>
        </ol>

        <div class="mt-4 rounded-md border border-slate-200 bg-white p-3 text-xs leading-5 text-slate-500">
          provider={{ route.provider }}，configuredProvider={{ route.configuredProvider }}，strategy={{ route.strategy }}
        </div>
      </div>
    </template>
  </section>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import { tourismApi } from '@/services/tourismApi'

const props = defineProps({
  scenicSpotId: {
    type: Number,
    required: true
  }
})

const loading = ref(false)
const routeLoading = ref(false)
const error = ref('')
const buildings = ref([])
const floors = ref([])
const features = ref([])
const featureTypes = ref([])
const selectedBuildingId = ref('')
const selectedFloor = ref('')
const selectedType = ref('')
const startFeatureId = ref('')
const endFeatureId = ref('')
const strategy = ref('time')
const route = ref(null)

const selectedBuilding = computed(() => {
  return buildings.value.find(item => String(item.id) === String(selectedBuildingId.value)) || null
})

const visibleFeatures = computed(() => {
  return features.value.filter(feature => {
    if (selectedFloor.value && feature.floorCode !== selectedFloor.value) return false
    if (selectedType.value && feature.type !== selectedType.value) return false
    return true
  })
})

const canPlanRoute = computed(() => {
  if (!selectedBuildingId.value || !startFeatureId.value || !endFeatureId.value) return false
  if (String(startFeatureId.value) === String(endFeatureId.value)) return false
  const ids = new Set(visibleFeatures.value.map(item => String(item.id)))
  return ids.has(String(startFeatureId.value)) && ids.has(String(endFeatureId.value))
})

const indoorStatusLabel = computed(() => {
  if (loading.value) return '读取中'
  if (!buildings.value.length) return '未接入'
  return `${buildings.value.length} 栋建筑`
})

const durationLabel = (seconds) => {
  const value = Number(seconds || 0)
  if (value < 60) return `${value} s`
  const minutes = Math.round(value / 60)
  return `${minutes} min`
}

const chooseDefaultFeatures = () => {
  const pool = visibleFeatures.value
  if (!pool.length) {
    startFeatureId.value = ''
    endFeatureId.value = ''
    return
  }
  if (!pool.some(item => String(item.id) === String(startFeatureId.value))) {
    startFeatureId.value = String(pool.find(item => item.type === 'entrance')?.id || pool[0].id)
  }
  if (!pool.some(item => String(item.id) === String(endFeatureId.value)) || String(endFeatureId.value) === String(startFeatureId.value)) {
    const target = pool.find(item => String(item.id) !== String(startFeatureId.value) && ['exhibition', 'toilet', 'service', 'cafe'].includes(item.type))
      || pool.find(item => String(item.id) !== String(startFeatureId.value))
    endFeatureId.value = target ? String(target.id) : ''
  }
}

const loadFeatures = async () => {
  if (!selectedBuildingId.value) return
  error.value = ''
  route.value = null
  try {
    const data = await tourismApi.indoorFeatures(selectedBuildingId.value)
    floors.value = data.floors || []
    features.value = data.items || []
    featureTypes.value = data.types || []
    chooseDefaultFeatures()
  } catch (requestError) {
    floors.value = []
    features.value = []
    featureTypes.value = []
    error.value = requestError.response?.data?.message || '室内设施数据暂不可用'
  }
}

const loadBuildings = async () => {
  loading.value = true
  error.value = ''
  route.value = null
  buildings.value = []
  floors.value = []
  features.value = []
  featureTypes.value = []
  selectedBuildingId.value = ''
  selectedFloor.value = ''
  selectedType.value = ''
  startFeatureId.value = ''
  endFeatureId.value = ''
  try {
    const data = await tourismApi.indoorBuildings(props.scenicSpotId)
    buildings.value = data.items || []
    const nextBuildingId = buildings.value[0] ? String(buildings.value[0].id) : ''
    if (nextBuildingId === selectedBuildingId.value) {
      selectedBuildingId.value = nextBuildingId
      if (nextBuildingId) await loadFeatures()
    } else {
      selectedBuildingId.value = nextBuildingId
    }
  } catch (requestError) {
    error.value = requestError.response?.data?.message || '室内导航建筑数据暂不可用'
  } finally {
    loading.value = false
  }
}

const planRoute = async () => {
  if (!canPlanRoute.value) return
  routeLoading.value = true
  error.value = ''
  route.value = null
  try {
    route.value = await tourismApi.planIndoorRoute(selectedBuildingId.value, {
      startFeatureId: Number(startFeatureId.value),
      endFeatureId: Number(endFeatureId.value),
      strategy: strategy.value
    })
  } catch (requestError) {
    error.value = requestError.response?.data?.message || '室内路线规划失败'
  } finally {
    routeLoading.value = false
  }
}

watch(() => props.scenicSpotId, loadBuildings, { immediate: true })

watch(selectedBuildingId, async (next, previous) => {
  if (!next || next === previous) return
  selectedFloor.value = ''
  selectedType.value = ''
  startFeatureId.value = ''
  endFeatureId.value = ''
  await loadFeatures()
})

watch([selectedFloor, selectedType], () => {
  route.value = null
  chooseDefaultFeatures()
})

watch([startFeatureId, endFeatureId, strategy], () => {
  route.value = null
})
</script>
