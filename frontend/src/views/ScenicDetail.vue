<template>
  <div class="space-y-6">
    <router-link to="/search" class="inline-flex rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">
      返回搜索
    </router-link>

    <section class="overflow-hidden rounded-md border border-slate-200 bg-white">
      <div class="grid lg:grid-cols-[1.15fr_0.85fr]">
        <img
          :src="spotImageUrl(spot)"
          :alt="spot.name"
          class="h-72 w-full object-cover lg:h-full"
          @error="event => handleSpotImageError(event, spot)"
        >
        <div class="p-6">
          <div class="flex flex-wrap items-center gap-2">
            <span class="rounded-md bg-teal-50 px-2.5 py-1 text-sm font-semibold text-teal-800">{{ spot.category }}</span>
            <span class="rounded-md bg-amber-50 px-2.5 py-1 text-sm font-bold text-amber-800">评分 {{ spot.rating }}</span>
          </div>
          <h1 class="mt-4 text-3xl font-bold tracking-tight">{{ spot.name }}</h1>
          <p class="mt-3 text-sm leading-7 text-slate-600">{{ spot.description }}</p>

          <div class="mt-5 grid gap-3 sm:grid-cols-2">
            <div class="rounded-md bg-slate-50 p-4">
              <div class="text-xs text-slate-500">开放时间</div>
              <div class="mt-1 font-semibold">{{ spot.openingHours || '以景区公告为准' }}</div>
            </div>
            <div class="rounded-md bg-slate-50 p-4">
              <div class="text-xs text-slate-500">建议游玩</div>
              <div class="mt-1 font-semibold">{{ spot.duration }}</div>
            </div>
            <div class="rounded-md bg-slate-50 p-4">
              <div class="text-xs text-slate-500">门票</div>
              <div class="mt-1 font-semibold">¥{{ spot.ticket }}</div>
            </div>
            <div class="rounded-md bg-slate-50 p-4">
              <div class="text-xs text-slate-500">拥挤度</div>
              <div class="mt-1 font-semibold">{{ spot.crowd }}</div>
            </div>
          </div>

          <div class="mt-5 flex flex-wrap gap-2">
            <span v-for="tag in spot.tags" :key="tag" class="rounded-md bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-600">{{ tag }}</span>
          </div>

          <div class="mt-6 flex flex-wrap gap-3">
            <router-link to="/route" class="rounded-md bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800">
              加入路线规划
            </router-link>
            <router-link :to="{ path: '/diary', query: { spot: spot.name } }" class="rounded-md border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">
              写旅行日记
            </router-link>
            <button
              type="button"
              class="rounded-md bg-teal-700 px-4 py-2 text-sm font-semibold text-white hover:bg-teal-800 disabled:cursor-not-allowed disabled:bg-slate-400"
              :disabled="checkinLoading"
              @click="checkinSpot"
            >
              {{ checkinLoading ? '收集中...' : '收集旅行印章' }}
            </button>
          </div>
          <div
            v-if="checkinMessage"
            class="mt-3 rounded-md border px-3 py-2 text-sm"
            :class="checkinError ? 'border-amber-200 bg-amber-50 text-amber-800' : 'border-teal-200 bg-teal-50 text-teal-800'"
          >
            {{ checkinMessage }}
            <div v-if="checkinVerification" class="mt-1 text-xs opacity-80">
              验证方式：{{ checkinVerification }}
            </div>
            <div v-if="checkinUnlocked.length" class="mt-2 flex flex-wrap gap-2">
              <span v-for="item in checkinUnlocked" :key="item.code" class="rounded-md bg-white/80 px-2 py-1 text-xs font-semibold">
                新解锁：{{ item.name }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
      <div class="overflow-hidden rounded-md border border-slate-200 bg-white">
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-slate-200 p-5">
          <div>
            <h2 class="text-lg font-semibold text-slate-950">景区设施导航</h2>
            <p class="mt-1 text-sm text-slate-500">查看景区内部道路、建筑和服务设施，并规划步行路线。</p>
          </div>
          <button type="button" class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100" @click="fitInternalMap(true)">
            定位地图
          </button>
        </div>
        <div class="relative">
          <div
            ref="internalMapContainer"
            class="internal-map h-[420px] w-full"
            :class="{ 'cursor-crosshair': selectedStartMode === 'map' && amapReady }"
          ></div>
          <div class="pointer-events-none absolute left-3 top-3 rounded-md border border-white/80 bg-white/90 px-3 py-2 text-xs font-semibold text-slate-700 shadow-sm">
            {{ mapStatusLabel }}
          </div>
          <div
            v-if="selectedStartMode === 'map'"
            class="pointer-events-none absolute left-3 top-14 rounded-md border border-slate-200 bg-white/90 px-3 py-2 text-xs font-semibold text-slate-700 shadow-sm"
          >
            {{ selectedStartPoint ? `起点 ${selectedStartPointLabel}` : '点击地图选择起点' }}
          </div>
          <div v-if="amapError" class="absolute inset-x-4 bottom-4 rounded-md border border-amber-200 bg-white/95 p-3 text-sm leading-6 text-amber-800 shadow-sm">
            {{ amapError }}。自动入口和下拉起点仍可规划路线，地图点选需要地图服务加载成功。
          </div>
        </div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-center justify-between gap-3">
          <h2 class="text-lg font-semibold text-slate-950">设施查询</h2>
          <div class="flex items-center gap-2">
            <span v-if="facilitySortedByWalk" class="rounded-md bg-teal-50 px-2.5 py-1 text-xs font-semibold text-teal-700" title="按 Dijkstra 最短路径距离排序">步行距离排序</span>
            <span class="rounded-md bg-slate-100 px-2.5 py-1 text-sm font-semibold text-slate-700">{{ routableFacilities.length }}/{{ facilities.length }} 可导航</span>
          </div>
        </div>

        <!-- 等时圈图例：从入口步行可达时间分层（地图标记同色） -->
        <div v-if="facilitySortedByWalk" class="mt-3 flex flex-wrap items-center gap-x-3 gap-y-1 rounded-md bg-slate-50 px-3 py-2">
          <span class="text-xs font-semibold text-slate-600">入口步行等时圈</span>
          <span v-for="band in WALK_TIME_BANDS" :key="band.label" class="flex items-center gap-1 text-xs text-slate-600">
            <span class="h-2.5 w-2.5 rounded-full" :style="{ backgroundColor: band.color }"></span>
            {{ band.label }}
          </span>
        </div>

        <div v-if="internalError" class="mt-4 rounded-md border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
          {{ internalError }}
        </div>

        <template v-if="facilities.length">
          <label class="mt-4 flex items-center justify-between gap-3 rounded-md border border-slate-200 bg-slate-50 p-3 text-sm text-slate-700">
            <span>
              <span class="block font-semibold text-slate-900">显示全部设施</span>
              <span class="mt-0.5 block text-xs text-slate-500">默认只显示可以规划路线的设施。</span>
            </span>
            <input v-model="showAllFacilities" type="checkbox" class="h-4 w-4 accent-teal-700">
          </label>

          <div class="mt-4">
            <label class="text-sm font-semibold text-slate-700">设施类型</label>
            <select v-model="selectedFacilityType" class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700">
              <option value="">全部设施</option>
              <option v-for="type in visibleFacilityTypes" :key="type.type" :value="type.type">
                {{ type.label }}（{{ type.count }}）
              </option>
            </select>
          </div>

          <div class="mt-4">
            <label class="text-sm font-semibold text-slate-700">起点</label>
            <div class="mt-2 grid grid-cols-3 overflow-hidden rounded-md border border-slate-300 text-sm font-semibold">
              <button
                v-for="mode in startModes"
                :key="mode.value"
                type="button"
                class="h-10 border-r border-slate-300 px-2 last:border-r-0"
                :class="[
                  selectedStartMode === mode.value ? 'bg-slate-900 text-white' : 'bg-white text-slate-700 hover:bg-slate-50',
                  mode.value === 'map' && !amapReady ? 'cursor-not-allowed opacity-50' : ''
                ]"
                :disabled="mode.value === 'map' && !amapReady"
                @click="setStartMode(mode.value)"
              >
                {{ mode.label }}
              </button>
            </div>
            <select
              v-if="selectedStartMode === 'node'"
              v-model="selectedStartNodeId"
              class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
            >
              <option value="">自动选择最近入口</option>
              <option v-for="node in startNodeOptions" :key="node.id" :value="node.id">{{ node.name }}</option>
            </select>
            <div v-else-if="selectedStartMode === 'map'" class="mt-2 rounded-md border border-dashed border-slate-300 bg-slate-50 p-3 text-sm leading-6 text-slate-600">
              <div class="font-semibold text-slate-800">{{ selectedStartPoint ? '已选择地图起点' : '请在地图上点击起点' }}</div>
              <div v-if="selectedStartPoint" class="mt-1">{{ selectedStartPointLabel }}</div>
              <button
                v-if="selectedStartPoint"
                type="button"
                class="mt-2 rounded-md border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-100"
                @click="clearMapStart"
              >
                重新点选
              </button>
            </div>
            <div v-else class="mt-2 rounded-md bg-slate-50 p-3 text-sm text-slate-600">
              系统会使用景区入口或路网默认起点。
            </div>
          </div>

          <div class="mt-4">
            <label class="text-sm font-semibold text-slate-700">目的设施</label>
            <select v-model="selectedFacilityId" class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700">
              <option v-for="facility in destinationFacilities" :key="facility.id" :value="facility.id">
                {{ facility.name }} · {{ facility.typeLabel }}{{ facility.walkDistance >= 0 ? ` · ${facility.walkDistance}m · 步行约${Math.max(1, Math.round(facility.walkDistance / 72))}分钟` : '' }}
              </option>
            </select>
            <p v-if="!destinationFacilities.length" class="mt-2 text-sm text-amber-700">
              当前筛选下没有可导航设施，请切换设施类型。
            </p>
          </div>

          <button type="button" class="mt-4 w-full rounded-md bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:bg-slate-400" :disabled="internalLoading || !canPlanInternalRoute" @click="planInternalRoute">
            {{ internalLoading ? '规划中...' : '规划到该设施' }}
          </button>

          <div v-if="internalRoute" class="mt-5 rounded-md bg-slate-50 p-4">
            <div class="grid grid-cols-2 gap-3">
              <div>
                <div class="text-xs text-slate-500">距离</div>
                <div class="mt-1 font-bold text-slate-950">{{ internalRoute.distance }}</div>
              </div>
              <div>
                <div class="text-xs text-slate-500">预计耗时</div>
                <div class="mt-1 font-bold text-slate-950">{{ internalRoute.time }}</div>
              </div>
            </div>
            <div class="mt-3 rounded-md border border-teal-100 bg-white p-3 text-sm leading-6 text-slate-700">
              {{ routeSummary }}
            </div>
            <details v-if="debugRouteSummary" class="mt-3 rounded-md border border-slate-200 bg-white p-3 text-xs leading-5 text-slate-500">
              <summary class="cursor-pointer text-sm font-semibold text-slate-700">调试信息</summary>
              <pre class="mt-2 max-h-48 overflow-auto whitespace-pre-wrap break-words">{{ debugRouteSummary }}</pre>
            </details>
          </div>
        </template>

        <div v-else class="mt-4 rounded-md border border-dashed border-slate-300 p-5 text-sm leading-6 text-slate-500">
          当前景点还没有导入内部设施和道路数据。运行内部地图导入脚本后，这里会显示厕所、餐饮、入口、建筑和步行路线。
        </div>
      </div>
    </section>

    <IndoorNavigationPanel :scenic-spot-id="props.id" />

    <section class="grid gap-6 lg:grid-cols-[0.75fr_1.25fr]">
      <div class="space-y-6">
        <div class="rounded-md border border-slate-200 bg-white p-5">
          <h2 class="text-lg font-semibold">位置信息</h2>
          <div class="mt-3 text-sm leading-7 text-slate-600">
            <div>城市：{{ spot.district || '北京' }}</div>
            <div>地址：{{ spot.address || '暂无详细地址' }}</div>
          </div>
        </div>

        <!-- 热门时段：系统自有行为数据（打卡/路线规划/游记）聚合的人气画像 -->
        <div v-if="popularTimes" class="rounded-md border border-slate-200 bg-white p-5">
          <div class="flex items-center justify-between gap-2">
            <h2 class="text-lg font-semibold">热门时段</h2>
            <span
              class="rounded-md px-2 py-0.5 text-xs font-semibold"
              :class="popularTimes.source === 'behavior+model' ? 'bg-teal-50 text-teal-700' : 'bg-slate-100 text-slate-500'"
            >{{ popularTimes.source === 'behavior+model' ? '用户行为数据' : '典型模型' }}</span>
          </div>
          <div class="mt-4 flex items-end gap-[3px]" style="height: 72px">
            <div
              v-for="item in visiblePopularHours"
              :key="item.hour"
              class="group relative flex-1 rounded-t"
              :class="item.hour === currentHour ? 'bg-teal-600' : item.level >= 80 ? 'bg-teal-400' : 'bg-slate-200'"
              :style="{ height: Math.max(4, item.level * 0.72) + 'px' }"
              :title="`${item.hour}:00 人气 ${item.level}%`"
            ></div>
          </div>
          <div class="mt-1.5 flex justify-between text-[10px] text-slate-400">
            <span>6:00</span><span>10:00</span><span>14:00</span><span>18:00</span><span>22:00</span>
          </div>
          <p class="mt-3 text-xs text-slate-500">
            <template v-if="popularTimes.source === 'behavior+model'">
              基于本系统 {{ popularTimes.samples?.checkins || 0 }} 次打卡、{{ popularTimes.samples?.diaries || 0 }} 篇游记等行为数据，
              数据越多画像越准。
            </template>
            <template v-else>
              当前行为数据较少，展示典型游客曲线；随着打卡和路线规划增多会自动切换为真实画像。
            </template>
            <template v-if="(popularTimes.peakHours || []).length">
              高峰：{{ popularTimes.peakHours.map(h => h + ':00').join('、') }}
            </template>
          </p>
        </div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-semibold">游客评价</h2>
          <span class="text-sm text-slate-500">{{ reviews.length }} 条</span>
        </div>

        <div class="mt-4 space-y-3">
          <article v-for="review in reviews" :key="review.id" class="rounded-md border border-slate-200 p-4">
            <div class="flex items-center justify-between gap-3">
              <div class="font-semibold">{{ review.author }}</div>
              <div class="text-sm font-bold text-amber-700">{{ review.rating }} 分</div>
            </div>
            <p class="mt-2 text-sm leading-6 text-slate-600">{{ review.content || '这位用户暂时没有填写文字评价。' }}</p>
            <div class="mt-3 text-xs text-slate-400">{{ review.createdAt }} · {{ review.helpfulCount }} 人觉得有帮助</div>
          </article>
        </div>

        <div v-if="!reviews.length" class="mt-4 rounded-md border border-dashed border-slate-300 p-6 text-center text-sm text-slate-500">
          暂无评价，期待第一位旅行者留下体验。
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import IndoorNavigationPanel from '@/components/IndoorNavigationPanel.vue'
import { scenicSpots as fallbackSpots } from '@/data/demoData'
import { getAmapConfigStatus, loadAmap } from '@/services/amapLoader'
import { tourismApi } from '@/services/tourismApi'
import { toAmapLngLat, toBackendLatLng } from '@/utils/coordinates'
import { handleSpotImageError, spotImageUrl } from '@/utils/images'

const props = defineProps({
  id: {
    type: Number,
    required: true
  }
})

const fallbackSpot = fallbackSpots.find(item => item.id === props.id) || fallbackSpots[0]
const spot = ref({ ...fallbackSpot, tags: fallbackSpot.tags || [] })
const reviews = ref([])
const facilities = ref([])
const facilityTypes = ref([])
const facilitySortedByWalk = ref(false)  // 是否按实际步行距离（Dijkstra）排序
const popularTimes = ref(null)  // 热门时段画像（行为数据/模型）
const currentHour = new Date().getHours()
// 图表只展示 6:00-22:00（夜间小时无信息量）
const visiblePopularHours = computed(() =>
  (popularTimes.value?.hours || []).filter(item => item.hour >= 6 && item.hour <= 22))
const internalMap = ref({ nodes: [], edges: [] })
const internalRoute = ref(null)
const internalError = ref('')
const internalLoading = ref(false)
const selectedFacilityType = ref('')
const selectedFacilityId = ref('')
const selectedStartMode = ref('auto')
const selectedStartNodeId = ref('')
const selectedStartPoint = ref(null)
const showAllFacilities = ref(false)
const amapReady = ref(false)
const amapError = ref('')
const internalMapContainer = ref(null)
const checkinLoading = ref(false)
const checkinMessage = ref('')
const checkinError = ref(false)
const checkinVerification = ref('')
const checkinUnlocked = ref([])

const startModes = [
  { value: 'auto', label: '自动入口' },
  { value: 'node', label: '下拉选择' },
  { value: 'map', label: '地图点选' }
]

let AMapApi
let map
let roadOverlays = []
let facilityOverlays = []
let startOverlays = []
let routeOverlays = []

const visibleFacilityPool = computed(() => {
  return showAllFacilities.value ? facilities.value : routableFacilities.value
})

const visibleFacilities = computed(() => {
  const items = selectedFacilityType.value
    ? visibleFacilityPool.value.filter(item => item.type === selectedFacilityType.value)
    : visibleFacilityPool.value
  return [...items].sort((left, right) => Number(Boolean(right.routable)) - Number(Boolean(left.routable)))
})

const routableFacilities = computed(() => facilities.value.filter(item => item.routable))

const destinationFacilities = computed(() => visibleFacilities.value.filter(item => item.routable))

const visibleFacilityTypes = computed(() => {
  const labelByType = new Map(facilityTypes.value.map(type => [type.type, type.label]))
  const counts = new Map()
  for (const facility of visibleFacilityPool.value) {
    if (!facility.type) continue
    counts.set(facility.type, (counts.get(facility.type) || 0) + 1)
    if (!labelByType.has(facility.type)) labelByType.set(facility.type, facility.typeLabel || facility.type)
  }
  return [...counts.entries()]
    .map(([type, count]) => ({ type, count, label: labelByType.get(type) || type }))
    .sort((left, right) => left.label.localeCompare(right.label))
})

const selectedFacility = computed(() => {
  return facilities.value.find(item => String(item.id) === String(selectedFacilityId.value)) || null
})

const startNodeOptions = computed(() => {
  const priority = { entrance: 0, scenic: 1, facility: 2, building: 3, junction: 4 }
  return [...(internalMap.value.nodes || [])]
    .filter(node => node.id && node.name && node.type !== 'junction')
    .sort((left, right) => (priority[left.type] ?? 9) - (priority[right.type] ?? 9) || left.name.localeCompare(right.name))
    .slice(0, 80)
})

const selectedStartPointLabel = computed(() => {
  if (!selectedStartPoint.value) return ''
  return `${selectedStartPoint.value.latitude.toFixed(6)}, ${selectedStartPoint.value.longitude.toFixed(6)}`
})

const canPlanInternalRoute = computed(() => {
  if (!selectedFacilityId.value) return false
  if (selectedFacility.value && !selectedFacility.value.routable) return false
  if (!destinationFacilities.value.some(item => String(item.id) === String(selectedFacilityId.value))) return false
  if (selectedStartMode.value === 'map') return Boolean(selectedStartPoint.value)
  return true
})

const mapStatusLabel = computed(() => {
  if (amapReady.value) return '地图服务'
  if (amapError.value) return '地图配置不可用'
  return '地图加载中'
})

const routeSummary = computed(() => {
  if (!internalRoute.value || !selectedFacility.value) return ''
  const startText = selectedStartMode.value === 'node'
    ? (startNodeOptions.value.find(node => String(node.id) === String(selectedStartNodeId.value))?.name || '所选起点')
    : selectedStartMode.value === 'map'
      ? '地图点选起点'
      : '景区入口'
  return `从${startText}步行约 ${internalRoute.value.distance}，预计 ${internalRoute.value.time} 到达 ${selectedFacility.value.name}。`
})

const debugRouteSummary = computed(() => {
  if (!internalRoute.value) return ''
  const details = {
    routeQuality: internalRoute.value.routeQuality || null,
    pathEdges: internalRoute.value.pathEdges || []
  }
  if (!details.routeQuality && !details.pathEdges.length) return ''
  return JSON.stringify(details, null, 2)
})

const initInternalMap = async () => {
  if (map || !internalMapContainer.value) return
  const configStatus = getAmapConfigStatus()
  if (!configStatus.ready) {
    amapError.value = '地图服务配置不可用，请联系管理员检查配置'
    return
  }

  try {
    AMapApi = await loadAmap()
    map = new AMapApi.Map(internalMapContainer.value, {
      viewMode: '2D',
      zoom: 15,
      center: [116.39747, 39.908823],
      resizeEnable: true
    })
    map.addControl(new AMapApi.Scale())
    map.addControl(new AMapApi.ToolBar({ position: { right: '12px', bottom: '12px' } }))
    map.on('click', handleInternalMapClick)
    amapReady.value = true
    amapError.value = ''
    drawInternalMap(true)
  } catch (error) {
    amapReady.value = false
    amapError.value = error?.message || '地图服务加载失败'
  }
}

function handleInternalMapClick(event) {
  if (selectedStartMode.value !== 'map') return
  selectedStartPoint.value = toBackendLatLng(event.lnglat)
  selectedStartNodeId.value = ''
  internalRoute.value = null
  internalError.value = ''
  drawStartMarker()
  drawInternalRoute()
}

const setStartMode = (mode) => {
  if (mode === 'map' && !amapReady.value) {
    internalError.value = '地图点选起点需要先配置并加载地图服务'
    return
  }
  selectedStartMode.value = mode
  internalRoute.value = null
  internalError.value = ''
  if (mode === 'auto') {
    selectedStartNodeId.value = ''
    selectedStartPoint.value = null
  } else if (mode === 'node') {
    selectedStartPoint.value = null
  } else if (mode === 'map') {
    selectedStartNodeId.value = ''
  }
  drawStartMarker()
  drawInternalRoute()
}

const clearMapStart = () => {
  selectedStartPoint.value = null
  internalRoute.value = null
  internalError.value = ''
  drawStartMarker()
  drawInternalRoute()
}

const loadDetail = async () => {
  try {
    const [detail, reviewData] = await Promise.all([
      tourismApi.scenicSpot(props.id),
      tourismApi.scenicSpotReviews(props.id)
    ])
    spot.value = { ...detail, tags: detail.tags || [] }
    reviews.value = reviewData.items || []
  } catch (error) {
    const local = fallbackSpots.find(item => item.id === props.id) || fallbackSpots[0]
    spot.value = { ...local, tags: local.tags || [] }
    reviews.value = []
  }
  loadPopularTimes()
  await loadInternalNavigation()
}

// 热门时段画像（独立加载，失败时隐藏卡片）
const loadPopularTimes = async () => {
  try {
    popularTimes.value = await tourismApi.scenicPopularTimes(props.id)
  } catch {
    popularTimes.value = null
  }
}

function browserLocation() {
  return new Promise(resolve => {
    if (typeof navigator === 'undefined' || !navigator.geolocation) {
      resolve(null)
      return
    }
    navigator.geolocation.getCurrentPosition(
      position => {
        resolve({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude
        })
      },
      () => resolve(null),
      { enableHighAccuracy: true, timeout: 4000, maximumAge: 60000 }
    )
  })
}

const checkinSpot = async () => {
  checkinLoading.value = true
  checkinMessage.value = ''
  checkinError.value = false
  checkinVerification.value = ''
  checkinUnlocked.value = []
  try {
    const location = await browserLocation()
    const payload = location ? { latitude: location.latitude, longitude: location.longitude } : {}
    const result = await tourismApi.checkinScenicSpot(props.id, payload)
    checkinMessage.value = result.message || '旅行印章已收集，成就进度已更新'
    checkinVerification.value = result.verificationLabel || (result.verification === 'gps' ? 'GPS 定位验证' : '演示打卡')
    checkinUnlocked.value = result.unlockedAchievements || []
  } catch (error) {
    checkinError.value = true
    checkinMessage.value = error.response?.data?.message || '打卡失败，请登录后重试'
  } finally {
    checkinLoading.value = false
  }
}

const loadInternalNavigation = async () => {
  internalError.value = ''
  internalRoute.value = null
  selectedFacilityId.value = ''
  selectedStartMode.value = 'auto'
  selectedStartNodeId.value = ''
  selectedStartPoint.value = null
  facilitySortedByWalk.value = false
  try {
    // 先加载地图，获取入口节点 ID，再用 Dijkstra 实际步行距离排序设施
    const mapData = await tourismApi.scenicInternalMap(props.id)
    internalMap.value = {
      nodes: mapData.nodes || [],
      edges: mapData.edges || []
    }

    // 找入口节点（type='entrance' 优先，没有则取第一个节点）
    const entranceNode = mapData.nodes?.find(n => n.type === 'entrance') || mapData.nodes?.[0]
    const facilityParams = { limit: 200 }
    if (entranceNode?.id) facilityParams.from_node_id = entranceNode.id

    const facilityData = await tourismApi.scenicFacilities(props.id, facilityParams)
    facilities.value = facilityData.items || []
    facilityTypes.value = facilityData.types || []
    facilitySortedByWalk.value = !!(facilityData.sortedByWalkDistance && entranceNode?.id)

    ensureSelectedFacility()
    drawInternalMap(true)
  } catch (error) {
    facilities.value = []
    facilityTypes.value = []
    internalMap.value = { nodes: [], edges: [] }
    internalError.value = '内部导航数据暂不可用'
    drawInternalMap(true)
  }
}

// 等时圈分档：按实际步行路径距离换算时间（步速 1.2m/s = 72m/min）
const WALK_TIME_BANDS = [
  { maxMinutes: 5, color: '#16a34a', label: '≤5分钟' },
  { maxMinutes: 10, color: '#eab308', label: '≤10分钟' },
  { maxMinutes: 15, color: '#f97316', label: '≤15分钟' },
  { maxMinutes: Infinity, color: '#ef4444', label: '>15分钟' }
]

const walkMinutes = (facility) => {
  if (!(facility.walkDistance >= 0)) return null
  return facility.walkDistance / 72
}

const walkTimeBand = (facility) => {
  const minutes = walkMinutes(facility)
  if (minutes === null) return null
  return WALK_TIME_BANDS.find(band => minutes <= band.maxMinutes) || null
}

const markerColor = (facility) => {
  if (!facility.routable) return '#94a3b8'
  if (String(facility.id) === String(selectedFacilityId.value)) return '#0f766e'
  // 步行距离排序模式下按等时圈着色：地图一眼看出可达性分层
  if (facilitySortedByWalk.value) {
    const band = walkTimeBand(facility)
    if (band) return band.color
  }
  if (facility.type === 'toilet') return '#2563eb'
  if (facility.type === 'restaurant' || facility.type === 'cafe') return '#c2410c'
  if (facility.type === 'entrance') return '#7c3aed'
  if (facility.type === 'building') return '#475569'
  return '#0f172a'
}

const clearOverlayGroup = (overlays) => {
  if (map && overlays.length) map.remove(overlays)
  overlays.splice(0, overlays.length)
}

const clearAllMapOverlays = () => {
  clearOverlayGroup(roadOverlays)
  clearOverlayGroup(facilityOverlays)
  clearOverlayGroup(startOverlays)
  clearOverlayGroup(routeOverlays)
}

const makePolylinePath = (coordinates) => {
  return (coordinates || [])
    .filter(point => point?.length === 2)
    .map(point => toAmapLngLat({ latitude: point[0], longitude: point[1] }))
    .filter(Boolean)
}

const drawInternalMap = (shouldFit = false) => {
  if (!map || !AMapApi) return
  clearAllMapOverlays()

  for (const edge of internalMap.value.edges || []) {
    if (edge.source === 'generated') continue
    if (!edge.coordinates?.length) continue
    const path = makePolylinePath(edge.coordinates)
    if (!path.length) continue
    const line = new AMapApi.Polyline({
      path,
      strokeColor: '#64748b',
      strokeWeight: 3,
      strokeOpacity: 0.46,
      lineJoin: 'round',
      lineCap: 'round',
      zIndex: 20
    })
    roadOverlays.push(line)
  }

  for (const facility of visibleFacilities.value) {
    if (!facility.latitude || !facility.longitude) continue
    const center = toAmapLngLat(facility)
    if (!center) continue
    const marker = new AMapApi.CircleMarker({
      center,
      radius: String(facility.id) === String(selectedFacilityId.value) ? 9 : facility.routable ? 7 : 5,
      strokeColor: '#ffffff',
      strokeWeight: 2,
      fillColor: markerColor(facility),
      fillOpacity: facility.routable ? 0.95 : 0.38,
      zIndex: facility.routable ? 70 : 40
    })
    marker.on('mouseover', () => {
      marker.setOptions({ radius: String(facility.id) === String(selectedFacilityId.value) ? 10 : 8 })
    })
    marker.on('mouseout', () => {
      marker.setOptions({ radius: String(facility.id) === String(selectedFacilityId.value) ? 9 : facility.routable ? 7 : 5 })
    })
    marker.on('click', () => {
      if (!facility.routable) {
        internalError.value = '该设施暂不能规划步行路线'
        return
      }
      selectedFacilityId.value = String(facility.id)
      internalError.value = ''
      drawInternalMap()
      drawInternalRoute()
    })
    facilityOverlays.push(marker)

    const label = new AMapApi.Text({
      text: facility.name,
      position: center,
      anchor: 'bottom-center',
      offset: new AMapApi.Pixel(0, -12),
      style: {
        'background-color': 'rgba(255,255,255,0.9)',
        'border-color': 'rgba(203,213,225,0.9)',
        'border-radius': '4px',
        color: facility.routable ? '#0f172a' : '#64748b',
        'font-size': '12px',
        padding: '2px 6px'
      },
      zIndex: facility.routable ? 71 : 41
    })
    facilityOverlays.push(label)
  }

  if (roadOverlays.length) map.add(roadOverlays)
  if (facilityOverlays.length) map.add(facilityOverlays)
  drawStartMarker()
  drawInternalRoute()
  if (shouldFit) fitInternalMap(true)
}

const drawStartMarker = () => {
  if (!map || !AMapApi) return
  clearOverlayGroup(startOverlays)
  if (selectedStartMode.value !== 'map' || !selectedStartPoint.value) return

  const point = toAmapLngLat(selectedStartPoint.value)
  if (!point) return
  startOverlays.push(new AMapApi.CircleMarker({
    center: point,
    radius: 18,
    strokeColor: '#f59e0b',
    strokeWeight: 2,
    fillColor: '#fbbf24',
    fillOpacity: 0.18,
    zIndex: 85
  }))
  startOverlays.push(new AMapApi.CircleMarker({
    center: point,
    radius: 11,
    strokeColor: '#ffffff',
    strokeWeight: 4,
    fillColor: '#f59e0b',
    fillOpacity: 1,
    zIndex: 86
  }))
  map.add(startOverlays)
}

const routeCoordinates = () => {
  const edgeCoordinates = (internalRoute.value?.pathEdges || [])
    .flatMap(edge => edge.coordinates || [])
    .filter(point => point?.length === 2)
  if (edgeCoordinates.length) return edgeCoordinates
  if (internalRoute.value?.usedInternalFallback) return []
  return (internalRoute.value?.coordinates || []).filter(point => point?.length === 2)
}

const drawInternalRoute = () => {
  if (!map || !AMapApi) return
  clearOverlayGroup(routeOverlays)
  if (internalRoute.value?.usedInternalFallback) return

  const coords = routeCoordinates()
  const path = makePolylinePath(coords)
  if (!path.length) return
  const routeLine = new AMapApi.Polyline({
    path,
    strokeColor: '#0f766e',
    strokeWeight: 7,
    strokeOpacity: 0.95,
    lineJoin: 'round',
    lineCap: 'round',
    zIndex: 90
  })
  routeOverlays.push(routeLine)
  map.add(routeOverlays)
}

const fitInternalMap = (force = false) => {
  if (!map || !force) return
  const routeCoords = routeCoordinates()
  const startCoords = selectedStartPoint.value ? [toAmapLngLat(selectedStartPoint.value)] : []
  const facilityCoords = visibleFacilities.value
    .filter(item => item.latitude && item.longitude)
    .map(item => toAmapLngLat(item))
  const nodeCoords = (internalMap.value.nodes || [])
    .filter(item => item.latitude && item.longitude)
    .slice(0, 300)
    .map(item => toAmapLngLat(item))
  const routeAmapCoords = makePolylinePath(routeCoords)
  const coords = (routeAmapCoords.length ? routeAmapCoords : startCoords.length ? startCoords : facilityCoords.length ? facilityCoords : nodeCoords).filter(Boolean)
  if (!coords.length) return
  const lngs = coords.map(point => point[0])
  const lats = coords.map(point => point[1])
  const bounds = new AMapApi.Bounds(
    [Math.min(...lngs), Math.min(...lats)],
    [Math.max(...lngs), Math.max(...lats)]
  )
  map.setBounds(bounds, false, [32, 32, 32, 32], 17)
}

const planInternalRoute = async () => {
  if (!selectedFacilityId.value) return
  if (selectedFacility.value && !selectedFacility.value.routable) {
    internalError.value = '该设施未接入真实内部路网，暂不能规划步行路线'
    return
  }
  if (selectedStartMode.value === 'map' && !selectedStartPoint.value) {
    internalError.value = '请先在地图上点击选择起点'
    return
  }
  internalLoading.value = true
  internalError.value = ''
  try {
    const payload = {
      facilityId: Number(selectedFacilityId.value),
      optimization: 'balanced'
    }
    if (selectedStartMode.value === 'node') {
      payload.startNodeId = Number(selectedStartNodeId.value || 0)
    } else if (selectedStartMode.value === 'map' && selectedStartPoint.value) {
      payload.startLat = selectedStartPoint.value.latitude
      payload.startLng = selectedStartPoint.value.longitude
    }
    internalRoute.value = await tourismApi.planScenicInternalRoute(props.id, payload)
    drawInternalMap()
    fitInternalMap(true)
  } catch (error) {
    internalRoute.value = null
    internalError.value = error.response?.data?.message || '无法规划到该设施的内部路线'
    drawInternalRoute()
  } finally {
    internalLoading.value = false
  }
}

const ensureSelectedFacility = () => {
  const current = destinationFacilities.value.find(item => String(item.id) === String(selectedFacilityId.value))
  if (current) return
  selectedFacilityId.value = String(destinationFacilities.value[0]?.id || '')
}

watch([selectedFacilityType, showAllFacilities], () => {
  if (selectedFacilityType.value && !visibleFacilityTypes.value.some(type => type.type === selectedFacilityType.value)) {
    selectedFacilityType.value = ''
    return
  }
  ensureSelectedFacility()
  internalRoute.value = null
  drawInternalMap()
})

watch(destinationFacilities, ensureSelectedFacility)

watch(selectedStartNodeId, () => {
  if (selectedStartMode.value !== 'node') return
  internalRoute.value = null
  internalError.value = ''
  drawInternalRoute()
})

watch(() => props.id, loadDetail)

onMounted(async () => {
  await nextTick()
  await initInternalMap()
  await loadDetail()
})

onUnmounted(() => {
  clearAllMapOverlays()
  if (map) {
    map.destroy()
    map = null
  }
})
</script>

<style scoped>
.internal-map {
  background-color: #eef2f7;
  background-image:
    linear-gradient(rgba(148, 163, 184, 0.16) 1px, transparent 1px),
    linear-gradient(90deg, rgba(148, 163, 184, 0.16) 1px, transparent 1px);
  background-size: 36px 36px;
}
</style>
