<template>
  <div class="grid gap-6 xl:grid-cols-[0.82fr_1.18fr]">
    <section class="space-y-6">
      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-start justify-between gap-4">
          <div>
            <h1 class="text-2xl font-bold text-slate-950">路线规划</h1>
          </div>
          <span class="rounded-md bg-teal-50 px-3 py-1 text-sm font-semibold text-teal-800">智能规划</span>
        </div>

        <!-- 日记复刻模式横幅 -->
        <div v-if="replayInfo" class="mt-4 flex items-start gap-2.5 rounded-md border border-teal-200 bg-teal-50 px-4 py-3">
          <svg class="mt-0.5 w-4 h-4 flex-none text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"/></svg>
          <div class="min-w-0 text-sm text-teal-800">
            <span class="font-semibold">正在重走日记路线</span>
            <template v-if="replayInfo.title">：《{{ replayInfo.title }}》</template>
            <div class="mt-0.5 text-xs text-teal-600">已按日记叙述顺序填入途经点，可自行调整后重新生成</div>
          </div>
        </div>

        <form class="mt-6 space-y-5" @submit.prevent="planRoute">
          <div>
            <label class="text-sm font-semibold text-slate-700">城市</label>
            <input
              v-model.trim="form.city"
              class="mt-2 h-11 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
              placeholder="北京、上海、杭州"
            >
          </div>

          <div v-if="!tourMode" class="space-y-3">
            <div class="rounded-md border border-slate-200 bg-slate-50 p-3">
              <div class="mb-2 text-xs font-semibold text-slate-500">出发点</div>
              <input
                v-model.trim="form.startText"
                class="h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
                placeholder="例如：前门大街"
              >
            </div>

            <div v-for="(waypoint, index) in waypoints" :key="waypoint.id" class="rounded-md border border-slate-200 bg-white p-3">
              <div class="mb-2 flex items-center justify-between gap-2">
                <div class="text-xs font-semibold text-slate-500">途经点 {{ index + 1 }}</div>
                <div class="flex items-center gap-1">
                  <button type="button" class="rounded-md px-2 py-1 text-xs font-semibold text-slate-500 hover:bg-slate-100" @click="moveWaypoint(index, -1)">上移</button>
                  <button type="button" class="rounded-md px-2 py-1 text-xs font-semibold text-slate-500 hover:bg-slate-100" @click="moveWaypoint(index, 1)">下移</button>
                  <button type="button" class="rounded-md px-2 py-1 text-xs font-semibold text-rose-600 hover:bg-rose-50" @click="removeWaypoint(index)">删除</button>
                </div>
              </div>
              <input
                v-model.trim="waypoint.name"
                class="h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
                placeholder="例如：天安门广场"
              >
            </div>

            <div class="flex gap-2">
              <input
                v-model.trim="newWaypoint"
                class="h-10 min-w-0 flex-1 rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
                placeholder="添加途经点，例如：国家博物馆"
                @keydown.enter.prevent="addWaypoint"
              >
              <button type="button" class="h-10 rounded-md border border-slate-300 px-4 text-sm font-semibold text-slate-700 hover:bg-slate-100" @click="addWaypoint">添加</button>
            </div>

            <div class="rounded-md border border-slate-200 bg-slate-50 p-3">
              <div class="mb-2 text-xs font-semibold text-slate-500">目的地</div>
              <input
                v-model.trim="form.endText"
                class="h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
                placeholder="例如：故宫博物院"
              >
            </div>
          </div>

          <div v-else class="space-y-3">
            <div class="rounded-md border border-slate-200 bg-slate-50 p-3">
              <div class="mb-2 text-xs font-semibold text-slate-500">当前位置 / 出发点</div>
              <input
                v-model.trim="form.startText"
                class="h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
                placeholder="例如：前门大街、北京大学东门"
              >
            </div>

            <div class="rounded-md border border-teal-100 bg-teal-50 px-3 py-2 text-xs leading-5 text-teal-800">
              目标地点可填写景点或学校名称；“第几个到达”只计算目标地点，不包含出发点和最后返回出发点。留空则由系统自动安排。
            </div>

            <div v-for="(target, index) in tourTargets" :key="target.id" class="rounded-md border border-slate-200 bg-white p-3">
              <div class="mb-2 flex items-center justify-between gap-2">
                <div class="text-xs font-semibold text-slate-500">目标地点 {{ index + 1 }}</div>
                <button type="button" class="rounded-md px-2 py-1 text-xs font-semibold text-rose-600 hover:bg-rose-50" @click="removeTourTarget(index)">删除</button>
              </div>
              <div class="grid gap-2 sm:grid-cols-[1fr_8.5rem]">
                <input
                  v-model.trim="target.name"
                  class="h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
                  placeholder="例如：故宫博物院"
                >
                <input
                  v-model.number="target.order"
                  type="number"
                  min="1"
                  :max="tourTargets.length"
                  class="h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
                  placeholder="第几个到达"
                >
              </div>
            </div>

            <div class="flex gap-2">
              <input
                v-model.trim="newWaypoint"
                class="h-10 min-w-0 flex-1 rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
                placeholder="添加目标地点，例如：国家博物馆"
                @keydown.enter.prevent="addWaypoint"
              >
              <button type="button" class="h-10 rounded-md border border-slate-300 px-4 text-sm font-semibold text-slate-700 hover:bg-slate-100" @click="addWaypoint">添加</button>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="text-sm font-semibold text-slate-700">交通方式</label>
              <select v-model="form.travelMode" class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm focus:border-teal-700 focus:outline-none">
                <option value="walk">步行</option>
                <option value="bike">骑行</option>
                <option value="driving">驾车</option>
                <option value="transit">地铁公交</option>
              </select>
            </div>
            <div>
              <label class="text-sm font-semibold text-slate-700">优化目标</label>
              <select v-model="form.optimization" class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm focus:border-teal-700 focus:outline-none">
                <option value="balanced">均衡</option>
                <option value="time">时间优先</option>
                <option value="distance">距离优先</option>
              </select>
            </div>
          </div>

          <!-- 环游模式开关 -->
          <div class="flex items-center gap-2 py-1">
            <input
              id="tourMode"
              v-model="tourMode"
              type="checkbox"
              class="w-4 h-4 rounded border-slate-300 text-teal-700 focus:ring-teal-500"
            />
            <label for="tourMode" class="text-sm font-semibold text-slate-700 cursor-pointer">环游模式</label>
            <span class="text-xs text-slate-400">自动安排多个地点的游览顺序，并回到起点</span>
          </div>

          <!-- Congestion-aware routing toggle -->
          <div class="flex items-center gap-2 py-1">
            <input
              id="congestionMode"
              v-model="useCongestion"
              type="checkbox"
              :disabled="tourMode"
              class="w-4 h-4 rounded border-slate-300 text-teal-700 focus:ring-teal-500"
            />
            <label for="congestionMode" class="text-sm font-semibold text-slate-700 cursor-pointer">拥挤度感知</label>
            <span class="text-xs text-slate-400">{{ tourMode ? '环游模式会优先优化多目标访问顺序' : '实时避开拥堵路段' }}</span>
          </div>
          <div v-if="useCongestion" class="grid grid-cols-2 gap-3">
            <div>
              <label class="text-sm font-semibold text-slate-700">出行时段</label>
              <select v-model="timeOfDay" class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm focus:border-teal-700 focus:outline-none">
                <option v-for="t in timeOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
              </select>
            </div>
            <div>
              <label class="text-sm font-semibold text-slate-700">预计拥挤度</label>
              <div class="mt-2 h-10 flex items-center gap-2">
                <span class="w-3 h-3 rounded-full" :style="{ backgroundColor: congestionColor }"></span>
                <span class="text-sm font-medium" :style="{ color: congestionColor }">{{ congestionLabel }}</span>
              </div>
            </div>
          </div>
          <!-- 行为画像来源提示：拥挤度由系统自有用户行为数据修正 -->
          <div v-if="useCongestion && route?.congestionSource === 'behavior+time'" class="rounded-md bg-teal-50 px-3 py-2 text-xs text-teal-700">
            本次拥挤度已结合系统内用户行为画像（打卡 / 路线规划 / 游记的时段分布），共修正 {{ route.behaviorBoostedEdges }} 条路段
          </div>

          <button class="w-full rounded-md bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:bg-slate-400" :disabled="loading">
            {{ loading ? '规划中...' : '生成路线' }}
          </button>
        </form>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-center justify-between gap-3">
          <h2 class="text-lg font-semibold text-slate-950">规划结果</h2>
          <span v-if="route" class="rounded-md bg-slate-100 px-2.5 py-1 text-sm font-semibold text-slate-700">{{ route.transport }}</span>
        </div>

        <div v-if="error" class="mt-4 rounded-md border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700">{{ error }}</div>

        <!-- 交通方式自动降级提示：所选模式无可达路线，已回退到混合模式 -->
        <div v-if="route && route.usedTransportFallback" class="mt-4 rounded-md border border-amber-200 bg-amber-50 px-4 py-2.5 text-sm text-amber-700 flex items-center gap-2">
          <svg class="w-4 h-4 flex-none text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
          当前路网中所选交通方式无可达路线，已自动回退为混合模式出行
        </div>
        <div v-if="route && route.fallbackNotice" class="mt-4 rounded-md border border-amber-200 bg-amber-50 px-4 py-2.5 text-sm text-amber-700 flex items-start gap-2">
          <svg class="mt-0.5 w-4 h-4 flex-none text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
          <span>{{ route.fallbackNotice }}</span>
        </div>

        <template v-if="route">
          <div class="mt-4 grid grid-cols-3 gap-3">
            <div class="rounded-md bg-slate-50 p-3">
              <div class="text-xs text-slate-500">{{ tourMode && !route.routeServiceFallback ? '环游距离' : '距离' }}</div>
              <div class="mt-1 text-lg font-bold">{{ route.distance }}</div>
            </div>
            <div class="rounded-md bg-slate-50 p-3">
              <div class="text-xs text-slate-500">{{ tourMode && !route.routeServiceFallback ? '环游时长' : '时长' }}</div>
              <div class="mt-1 text-lg font-bold">{{ route.time }}</div>
            </div>
            <div class="rounded-md bg-slate-50 p-3">
              <div class="text-xs text-slate-500">{{ tourMode && !route.routeServiceFallback ? '路线类型' : '预估费用' }}</div>
              <div class="mt-1 text-base font-bold">{{ tourMode && !route.routeServiceFallback ? (route.routeType || '环游路线') : ('¥' + route.cost) }}</div>
            </div>
          </div>

          <!-- 环游访问顺序 -->
          <div v-if="tourMode && !route.routeServiceFallback && route.visitOrder" class="mt-3 rounded-md bg-teal-50 px-3 py-2 text-sm text-teal-800">
            访问顺序: {{ route.visitOrder.join(' → ') }} → 返回出发点
          </div>

          <div class="mt-5 space-y-3">
            <div v-for="(stop, index) in route.stops" :key="`${stop}-${index}`" class="flex gap-3">
              <div class="grid h-8 w-8 flex-none place-items-center rounded-md bg-slate-900 text-sm font-bold text-white">{{ index + 1 }}</div>
              <div class="min-w-0 flex-1">
                <div class="font-semibold text-slate-950">{{ stop }}</div>
                <div class="text-sm text-slate-500">{{ requestedStopLabel(index) }}</div>
              </div>
            </div>
          </div>
        </template>

        <div v-else-if="!error" class="mt-4 rounded-md border border-dashed border-slate-300 p-6 text-sm text-slate-500">
          添加起点、途经点和目的地后会生成真实道路路线；路线服务不可用或本地路网质量不足时会显示明确错误。
        </div>
      </div>
    </section>

    <section class="space-y-6">
      <div class="overflow-hidden rounded-md border border-slate-200 bg-white">
        <div class="flex items-center justify-between border-b border-slate-200 p-5">
          <div>
            <h2 class="text-lg font-semibold text-slate-950">地图路线</h2>
            <p class="mt-1 text-sm text-slate-500">根据输入地点生成路线折线和停靠点。</p>
          </div>
          <button type="button" @click="fitRoute" class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">定位路线</button>
        </div>
        <div ref="mapContainer" class="h-[520px] w-full"></div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <h2 class="text-lg font-semibold text-slate-950">导航步骤</h2>
        <div v-if="route?.segments?.length" class="mt-4 divide-y divide-slate-100">
          <div v-for="(segment, index) in route.segments" :key="`${segment.from}-${index}`" class="py-3">
            <div class="flex items-center justify-between gap-3">
              <div class="font-semibold text-slate-950">{{ cleanInstruction(segment.from) }}</div>
              <span class="rounded-md bg-teal-50 px-2 py-1 text-xs font-semibold text-teal-800">{{ segment.transport }}</span>
            </div>
            <div class="mt-1 text-sm text-slate-500">
              {{ formatDistance(segment.distance) }} · {{ formatDuration(segment.duration) }}
            </div>
          </div>
        </div>
        <div v-else class="mt-4 rounded-md bg-slate-50 p-4 text-sm text-slate-500">生成路线后会显示每一步导航说明。</div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, reactive, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import L from 'leaflet'
import { tourismApi } from '@/services/tourismApi'

const pageRoute = useRoute()
const mapContainer = ref(null)
const route = ref(null)
const loading = ref(false)
const error = ref('')
const newWaypoint = ref('')
const waypoints = ref([])
const tourTargets = ref([])
const tourMode = ref(false)
const useCongestion = ref(false)
const timeOfDay = ref(12)
// 日记复刻模式：从日记详情页「重走这条路线」跳转而来
const replayInfo = ref(null)

const timeOptions = [
  { value: 7, label: '早高峰 (7:00)' },
  { value: 9, label: '上午 (9:00)' },
  { value: 12, label: '中午 (12:00)' },
  { value: 14, label: '下午 (14:00)' },
  { value: 17, label: '晚高峰 (17:00)' },
  { value: 19, label: '晚上 (19:00)' },
  { value: 22, label: '深夜 (22:00)' },
]

const congestionLabel = computed(() => {
  const h = timeOfDay.value
  if (h >= 7 && h <= 9) return '中度拥堵'
  if (h >= 17 && h <= 19) return '重度拥堵'
  if (h >= 22 || h <= 5) return '畅通'
  if (h >= 9 && h <= 11) return '轻微拥堵'
  return '轻度拥堵'
})

const congestionColor = computed(() => {
  const h = timeOfDay.value
  if (h >= 17 && h <= 19) return '#ef4444'
  if (h >= 7 && h <= 9) return '#f97316'
  if (h >= 9 && h <= 11) return '#eab308'
  if (h >= 22 || h <= 5) return '#22c55e'
  return '#84cc16'
})

// Route polyline color: follows congestion level when congestion mode is on
const routeLineColor = computed(() => {
  if (route.value?.routeServiceFallback) return '#0f766e'
  if (!useCongestion.value) return '#0f766e'
  return congestionColor.value
})

const form = reactive({
  city: '北京',
  startText: '前门大街',
  endText: '故宫博物院',
  travelMode: 'walk',
  optimization: 'balanced'
})

let map
let routeLayer
let routePolyline
let routeMarkers = []
let focusPulseTimer = null

onMounted(async () => {
  await nextTick()
  map = L.map(mapContainer.value, { zoomControl: false }).setView([39.916, 116.397], 13)
  L.control.zoom({ position: 'bottomright' }).addTo(map)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: 'OpenStreetMap'
  }).addTo(map)

  // 日记复刻模式：用日记景点预填表单并自动规划
  const stopsParam = typeof pageRoute.query.stops === 'string' ? pageRoute.query.stops : ''
  const stops = stopsParam.split('|').map(name => name.trim()).filter(Boolean)
  if (stops.length >= 2) {
    replayInfo.value = {
      diaryId: pageRoute.query.replayDiary || '',
      title: typeof pageRoute.query.replayTitle === 'string' ? pageRoute.query.replayTitle : ''
    }
    if (typeof pageRoute.query.city === 'string' && pageRoute.query.city) {
      form.city = pageRoute.query.city
    }
    form.startText = stops[0]
    form.endText = stops[stops.length - 1]
    waypoints.value = stops.slice(1, -1).map((name, index) => ({ id: Date.now() + index, name }))
    planRoute()
  }
})

const addWaypoint = () => {
  if (!newWaypoint.value) return
  if (tourMode.value) {
    tourTargets.value.push({ id: Date.now() + Math.random(), name: newWaypoint.value, order: '' })
  } else {
    waypoints.value.push({ id: Date.now() + Math.random(), name: newWaypoint.value })
  }
  newWaypoint.value = ''
}

const removeWaypoint = (index) => {
  waypoints.value.splice(index, 1)
}

const removeTourTarget = (index) => {
  tourTargets.value.splice(index, 1)
}

const moveWaypoint = (index, direction) => {
  const nextIndex = index + direction
  if (nextIndex < 0 || nextIndex >= waypoints.value.length) return
  const next = [...waypoints.value]
  const [item] = next.splice(index, 1)
  next.splice(nextIndex, 0, item)
  waypoints.value = next
}

const waypointTexts = () => {
  const seen = new Set([form.startText.trim(), form.endText.trim()])
  return waypoints.value
    .map(item => item.name.trim())
    .filter(item => {
      if (!item || seen.has(item)) return false
      seen.add(item)
      return true
    })
}

const tourTargetRows = () => {
  const seen = new Set([form.startText.trim()])
  return tourTargets.value
    .map(item => ({
      ...item,
      name: String(item.name || '').trim(),
      order: item.order === '' || item.order === null || Number.isNaN(Number(item.order))
        ? null
        : Number(item.order)
    }))
    .filter(item => {
      if (!item.name || seen.has(item.name)) return false
      seen.add(item.name)
      return true
    })
}

const ensureTourTargetsFromRouteFields = () => {
  if (tourTargets.value.length) return
  const names = [
    ...waypoints.value.map(item => item.name).filter(Boolean),
    form.endText
  ].map(name => String(name || '').trim()).filter(Boolean)
  tourTargets.value = names.map((name, index) => ({ id: Date.now() + index, name, order: '' }))
}

const validateTourInput = (targets) => {
  if (!form.startText.trim()) return '请输入当前位置 / 出发点。'
  if (targets.length < 2) return '环游模式至少需要两个目标地点。'
  const usedOrders = new Set()
  for (const target of targets) {
    if (target.order === null) continue
    if (!Number.isInteger(target.order) || target.order < 1 || target.order > targets.length) {
      return `“${target.name}”的到达序号必须在 1 到 ${targets.length} 之间。`
    }
    if (usedOrders.has(target.order)) return `第 ${target.order} 个到达的位置被重复指定。`
    usedOrders.add(target.order)
  }
  return ''
}

watch(tourMode, (enabled) => {
  error.value = ''
  route.value = null
  if (enabled) {
    ensureTourTargetsFromRouteFields()
    useCongestion.value = false
  } else if (tourTargets.value.length) {
    const names = tourTargets.value.map(item => String(item.name || '').trim()).filter(Boolean)
    waypoints.value = names.slice(0, -1).map((name, index) => ({ id: Date.now() + index, name }))
    if (names.length) form.endText = names[names.length - 1]
  }
  drawRoute()
})

const planRoute = async () => {
  if (!tourMode.value && (!form.startText || !form.endText)) {
    error.value = '请输入出发点和目的地。'
    return
  }

  loading.value = true
  error.value = ''

  // 环游模式：把输入地点解析为本地路网节点，后端生成多点访问顺序
  if (tourMode.value) {
    const targets = tourTargetRows()
    const validationMessage = validateTourInput(targets)
    if (validationMessage) {
      error.value = validationMessage
      loading.value = false
      return
    }
    const texts = tourStopTexts(targets)
    try {
      const nodes = await loadRouteNodes()
      const startNode = resolveGraphNode(nodes, form.startText)
      const resolvedTargets = targets.map(target => ({ ...target, node: resolveGraphNode(nodes, target.name) }))
      const missing = [
        !startNode && form.startText,
        ...resolvedTargets.filter(item => !item.node).map(item => item.name)
      ].filter(Boolean)
      if (missing.length) {
        route.value = await routeServiceFallbackForStops(
          texts,
          '环游模式',
          graphNodeMissingMessage('环游模式', missing),
          '已按当前输入顺序显示真实道路路线'
        )
        drawRoute()
        return
      }

      const tourResult = await tourismApi.tourRoute({
        startNodeId: startNode.id,
        targetNodeIds: resolvedTargets.map(item => item.node.id),
        fixedOrders: resolvedTargets
          .filter(item => item.order !== null)
          .map(item => ({ nodeId: item.node.id, order: item.order })),
        travelMode: localGraphTravelMode(),
        optimization: form.optimization
      })

      // 分层渲染：多点访问顺序由后端决定；若本地路网已通过质量检查且包含真实道路，
      // 优先使用本地几何，否则再交给路线服务按用户停靠点生成折线。
      const visitNames = tourResult.visitOrder || []
      const displayStops = visitNames.length >= 2 ? [...visitNames, visitNames[0]] : visitNames
      const routeNodesByName = [startNode, ...resolvedTargets.map(item => item.node)]
      const displayPlaces = displayStops
        .map(name => {
          const node = routeNodesByName.find(item =>
            item.name === name || item.nodeName === name || name.includes(item.name) || item.name.includes(name)
          )
          if (!node) return null
          return { latitude: node.latitude, longitude: node.longitude, name }
        })
        .filter(Boolean)
      const localRouteUsable = hasLocalRoadGeometry(tourResult)
      const amapRoute = localRouteUsable ? null : await amapGeometryForStops(displayStops)
      if (!localRouteUsable && !amapRoute) {
        throw new Error(localRouteGeometryIssue(tourResult))
      }

      route.value = {
        ...(amapRoute || tourResult),
        title: '环游路线',
        routeType: '环游路线',
        visitOrder: visitNames,
        returnToStart: true,
        fixedOrders: tourResult.fixedOrders || [],
        stops: displayStops,
        transport: amapRoute?.transport || tourResult.transport || modeLabel(),
        usedTransportFallback: amapRoute ? false : tourResult.usedTransportFallback,
        requestedPlaces: displayPlaces.length === displayStops.length ? displayPlaces : []
      }
      drawRoute()
    } catch (requestError) {
      try {
        route.value = await routeServiceFallbackForStops(
          texts,
          '环游模式',
          routeErrorMessage(requestError, '环游规划失败'),
          '已按当前输入顺序显示真实道路路线'
        )
        drawRoute()
      } catch (fallbackError) {
        route.value = null
        error.value = fallbackError.message
        drawRoute()
      }
    } finally {
      loading.value = false
    }
    return
  }

  // 拥挤度感知模式：解析起终点为本地路网节点，后端跑拥挤度加权 Dijkstra
  if (useCongestion.value) {
    const texts = allStopTexts()
    try {
      const nodes = await loadRouteNodes()
      const startNode = resolveGraphNode(nodes, form.startText)
      const endNode = resolveGraphNode(nodes, form.endText)
      const missing = [!startNode && form.startText, !endNode && form.endText].filter(Boolean)
      if (missing.length) {
        route.value = await routeServiceFallbackForStops(
          texts,
          '拥挤度感知',
          graphNodeMissingMessage('拥挤度感知', missing),
          '已按当前输入顺序显示真实道路路线'
        )
        drawRoute()
        return
      }

      const congestionResult = await tourismApi.congestionRoute({
        start_id: startNode.id,
        end_id: endNode.id,
        travel_mode: localGraphTravelMode(),
        optimization: form.optimization,
        hour: timeOfDay.value
      })

      route.value = {
        ...congestionResult,
        title: `拥挤度感知路线（${congestionResult.crowd_label || '中等'}敏感时段）`,
        routeType: '拥挤度感知路线',
        transport: congestionResult.transport || modeLabel(),
        // 拥挤度模式直接展示本地图算法选中的路径；如果再把中间节点交给外部路线服务
        // 二次重算，入口/换乘点这类非 scenic 节点会被抹掉，视觉上就像
        // “不同时间段/不同优化目标完全一样”。
        congestionSource: congestionResult.congestionSource,
        behaviorBoostedEdges: congestionResult.behaviorBoostedEdges,
        usedTransportFallback: congestionResult.usedTransportFallback
      }
      drawRoute()
    } catch (requestError) {
      try {
        route.value = await routeServiceFallbackForStops(
          texts,
          '拥挤度感知',
          routeErrorMessage(requestError, '拥挤度感知路由失败'),
          '已按当前输入顺序显示真实道路路线'
        )
        drawRoute()
      } catch (fallbackError) {
        route.value = null
        error.value = fallbackError.message
        drawRoute()
      }
    } finally {
      loading.value = false
    }
    return
  }

  // Standard route mode
  try {
    route.value = await tourismApi.planRoute({
      city: form.city,
      startText: form.startText,
      endText: form.endText,
      waypointTexts: waypointTexts(),
      travelMode: form.travelMode,
      optimization: form.optimization
    })
    drawRoute()
  } catch (planError) {
    route.value = null
    error.value = planError.response?.data?.message || '路线规划失败，未生成演示路线。请检查地点、交通方式或稍后重试。'
    drawRoute()
  } finally {
    loading.value = false
  }
}

const allStopTexts = () => [
  form.startText.trim(),
  ...waypointTexts(),
  form.endText.trim()
].filter(Boolean)

const tourStopTexts = (targets = tourTargetRows()) => [
  form.startText.trim(),
  ...targets.map(item => item.name),
  form.startText.trim()
].filter(Boolean)

const routeErrorMessage = (requestError, fallbackText) =>
  requestError?.response?.data?.message || requestError?.message || fallbackText

let lastRouteServiceError = ''

const routeServiceFallbackForStops = async (stopTexts, modeName, reason, routeLabel) => {
  lastRouteServiceError = ''
  const routeServiceRoute = await amapGeometryForStops(stopTexts)
  if (!routeServiceRoute) {
    const detail = lastRouteServiceError ? `原因：${lastRouteServiceError}` : '请确认后端服务已启动，并检查地点名称。'
    throw new Error(`${modeName}暂时无法生成完整路线。${detail}`)
  }
  const fallbackLabel =
    form.travelMode === 'transit' && stopTexts.length > 2
      ? '地铁公交模式已按起终点显示真实道路路线'
      : routeLabel
  return {
    ...routeServiceRoute,
    title: `${modeName}备选路线`,
    routeType: '备选路线',
    routeServiceFallback: true,
    fallbackNotice: `当前模式无法直接生成完整路线，已为你切换为可展示的备选路线。${fallbackLabel ? ` ${fallbackLabel}。` : ''}`,
    originalPlanningError: reason,
    usedTransportFallback: false
  }
}

// ---- 本地路网节点解析（环游 / 拥挤度模式共用）----
// 这两个模式跑在本地 graph_nodes/graph_edges 图上，必须把用户输入的地点
// 解析成真实节点 ID，而不是凭空构造（否则后端按假 ID 计算或直接报错）。
let routeNodesCache = null

const loadRouteNodes = async () => {
  if (routeNodesCache) return routeNodesCache
  const data = await tourismApi.routeNodes()
  routeNodesCache = (data.items || []).filter(node => (node.name || node.nodeName) && node.type !== 'junction')
  return routeNodesCache
}

const routeNodeTypeBonus = (type) => ({
  scenic: 40,
  school: 40,
  entrance: 30,
  building: 15,
  facility: 5,
  junction: 0
}[type] || 0)

const resolveGraphNode = (nodes, text) => {
  const query = String(text || '').trim()
  if (!query) return null
  let best = null
  let bestScore = 0
  for (const node of nodes) {
    const name = String(node.name || '')
    const nodeName = String(node.nodeName || '')
    let score = -1
    if (name === query) score = 320
    else if (nodeName === query) score = 260
    else if (name.startsWith(query)) score = 170
    else if (nodeName.startsWith(query)) score = 150
    else if (query.startsWith(name) && name.length >= 2) score = 130
    else if (nodeName && query.startsWith(nodeName) && nodeName.length >= 2) score = 120
    else if (name.includes(query)) score = 100
    else if (nodeName.includes(query)) score = 90
    if (score < 0) continue
    score += routeNodeTypeBonus(node.type)
    if (score > bestScore) {
      best = node
      bestScore = score
    }
  }
  return best
}

const graphNodeMissingMessage = (modeName, missing) => {
  const samples = (routeNodesCache || [])
    .filter(node => node.type === 'scenic')
    .slice(0, 8)
    .map(node => node.name)
    .join('、')
  return `${modeName}基于本地路网计算，以下地点不在路网中：${missing.join('、')}。`
    + (samples ? `可尝试路网内的地点，如：${samples}` : '')
}

// 本地图的交通方式映射。演示路网以步行边为主（地铁/骑行边零星），
// transit/driving 在算法层直接用混合模式（空串=不过滤），避免"无可达
// 路线已回退"的误报横幅；几何层仍按用户所选模式向路线服务取真实路线。
const localGraphTravelMode = () => {
  if (form.travelMode === 'driving' || form.travelMode === 'transit') return ''
  return form.travelMode
}

const maxLocalConnectorMeters = 80

const localEdgeSource = (edge) => String(edge?.source ?? '')
const localEdgeDistance = (edge) => Number(edge?.distance || 0)

const isTrustedLocalGeometryEdge = (edge) => {
  const source = localEdgeSource(edge)
  if (source === 'osm' || source === 'osm_stitch') return true
  if (source === 'global_connector') return localEdgeDistance(edge) <= maxLocalConnectorMeters
  return false
}

const hasLocalRoadGeometry = (result) => {
  const coordinates = Array.isArray(result?.coordinates) ? result.coordinates : []
  const pathEdges = Array.isArray(result?.pathEdges) ? result.pathEdges : []
  const realRoadEdges = Number(result?.routeQuality?.realRoadEdges || 0)
  return coordinates.length >= 2 &&
    realRoadEdges > 0 &&
    pathEdges.length > 0 &&
    pathEdges.every(isTrustedLocalGeometryEdge)
}

const localRouteGeometryIssue = (result) => {
  const pathEdges = Array.isArray(result?.pathEdges) ? result.pathEdges : []
  const hasDemoEdge = pathEdges.some(edge => !localEdgeSource(edge))
  const hasLongConnector = pathEdges.some(edge =>
    localEdgeSource(edge) === 'global_connector' &&
    localEdgeDistance(edge) > maxLocalConnectorMeters
  )
  if (hasDemoEdge || hasLongConnector) {
    return '当前本地路网仍包含演示连接段，未直接绘制为真实道路路线。'
  }
  return '当前本地路网路线暂不满足真实道路展示条件。'
}

const sameStopText = (left, right) =>
  String(left || '').trim() === String(right || '').trim()

const numericRouteDistance = (item) => {
  const direct = Number(item?.total_distance_meters)
  if (Number.isFinite(direct) && direct > 0) return direct
  const text = String(item?.distance || '').trim().toLowerCase()
  const match = text.match(/(\d+(?:\.\d+)?)/)
  if (!match) return 0
  const value = Number(match[1])
  if (!Number.isFinite(value)) return 0
  if (text.includes('km') || text.includes('公里')) return value * 1000
  return value
}

const numericRouteDuration = (item) => {
  const direct = Number(item?.total_duration_seconds)
  if (Number.isFinite(direct) && direct > 0) return direct
  const text = String(item?.time || '').trim()
  let seconds = 0
  const hour = text.match(/(\d+(?:\.\d+)?)\s*(小时|hour|h)/i)
  const minute = text.match(/(\d+(?:\.\d+)?)\s*(分钟|minute|min|m)/i)
  const second = text.match(/(\d+(?:\.\d+)?)\s*(秒|second|sec|s)/i)
  if (hour) seconds += Number(hour[1]) * 3600
  if (minute) seconds += Number(minute[1]) * 60
  if (second) seconds += Number(second[1])
  return Number.isFinite(seconds) ? seconds : 0
}

const mergeRequestedPlaces = (routes) => {
  const places = []
  routes.forEach((item, index) => {
    const legPlaces = Array.isArray(item?.requestedPlaces) ? item.requestedPlaces : []
    if (index === 0 && legPlaces[0]) places.push(legPlaces[0])
    const lastPlace = legPlaces[legPlaces.length - 1]
    if (lastPlace) places.push(lastPlace)
  })
  return places.length >= 2 ? places : []
}

const mergeRouteServiceSegments = (routes, stops) => {
  const coordinates = []
  const segments = []
  let totalDistance = 0
  let totalDuration = 0
  let totalCost = 0

  routes.forEach(item => {
    totalDistance += numericRouteDistance(item)
    totalDuration += numericRouteDuration(item)
    totalCost += Number(item?.cost || 0)
    if (Array.isArray(item?.segments)) segments.push(...item.segments)
    if (Array.isArray(item?.coordinates)) {
      item.coordinates.forEach((point, index) => {
        if (!Array.isArray(point) || point.length < 2) return
        const previous = coordinates[coordinates.length - 1]
        if (index > 0 || !previous || previous[0] !== point[0] || previous[1] !== point[1]) {
          coordinates.push(point)
        }
      })
    }
  })

  if (!coordinates.length) return null
  return {
    ...routes[routes.length - 1],
    id: 0,
    route_id: 'amap-loop-route',
    title: routes[0]?.title || '环游路线',
    stops,
    requestedPlaces: mergeRequestedPlaces(routes),
    segments,
    coordinates,
    distance: formatDistance(totalDistance),
    time: formatDuration(totalDuration),
    cost: Math.round(totalCost),
    total_distance_meters: Math.round(totalDistance),
    total_duration_seconds: Math.round(totalDuration),
    usedAmap: true,
    usedTransportFallback: false
  }
}

const planTextRoute = (startText, endText, waypointTexts = []) => tourismApi.planRoute({
  city: form.city || '北京',
  startText,
  endText,
  waypointTexts,
  travelMode: form.travelMode,
  optimization: form.optimization
})

const amapGeometryForClosedLoop = async (stops) => {
  const routes = []
  for (let index = 0; index < stops.length - 1; index += 1) {
    const startText = stops[index]
    const endText = stops[index + 1]
    if (sameStopText(startText, endText)) continue
    routes.push(await planTextRoute(startText, endText))
  }
  if (!routes.length) return null
  return mergeRouteServiceSegments(routes, stops)
}

// 分层渲染的几何层：把算法层（TSP/拥挤度 Dijkstra）决定的停靠点序列
// 交给路线服务按所选交通方式取真实道路折线。路线服务不可用时返回 null，
// 调用方会优先展示通过后端质量闸门的本地路线；本地算法不可展示时可用
// 真实路线服务兜底，但必须显式标记为兜底结果，不再生成演示线。
// 地铁公交模式特殊处理：公交方案由线路决定，"途经点"语义不成立且
// 相邻停靠点太近时公交方案可能不可用——只用起终点直达。
const amapGeometryForStops = async (stopTexts) => {
  if (!stopTexts || stopTexts.length < 2) return null
  const isTransit = form.travelMode === 'transit'
  const stops = stopTexts.map(item => String(item || '').trim()).filter(Boolean)
  if (stops.length < 2) return null
  const isClosedLoop = stops.length > 2 && sameStopText(stops[0], stops[stops.length - 1])
  if (isTransit && isClosedLoop) return null
  try {
    if (isClosedLoop) return await amapGeometryForClosedLoop(stops)
    const routeStops = isTransit ? [stops[0], stops[stops.length - 1]] : stops
    if (sameStopText(routeStops[0], routeStops[routeStops.length - 1])) return null
    return await planTextRoute(routeStops[0], routeStops[routeStops.length - 1], routeStops.slice(1, -1))
  } catch (requestError) {
    lastRouteServiceError = routeErrorMessage(requestError, '真实道路路线服务暂时不可用')
    return null
  }
}

const modeLabel = () => ({
  walk: '步行',
  bike: '骑行',
  driving: '驾车',
  transit: '地铁公交'
}[form.travelMode] || '步行')

const drawRoute = () => {
  if (!map) return
  if (routeLayer) routeLayer.remove()
  routeLayer = L.layerGroup()
  routePolyline = null
  routeMarkers = []

  const coords = route.value?.coordinates || []
  if (!coords.length) {
    routeLayer.addTo(map)
    return
  }

  const useCongestionStyle = useCongestion.value && !route.value?.routeServiceFallback
  routePolyline = L.polyline(coords, {
    color: routeLineColor.value,
    weight: useCongestionStyle ? 7 : 5,
    opacity: 0.9
  }).addTo(routeLayer)

  const markers = route.value?.requestedPlaces?.length
    ? route.value.requestedPlaces.map(place => [place.latitude, place.longitude, place.name])
    : route.value.stops.map((stop, index) => {
        const coord = coords[Math.min(index, coords.length - 1)]
        return [coord[0], coord[1], stop]
      })

  markers.forEach(([latitude, longitude, name], index) => {
    const marker = L.circleMarker([latitude, longitude], {
      radius: index === 0 || index === markers.length - 1 ? 9 : 7,
      color: '#0f172a',
      fillColor: '#ffffff',
      fillOpacity: 1,
      weight: 3
    }).bindTooltip(name).addTo(routeLayer)
    routeMarkers.push(marker)
  })

  routeLayer.addTo(map)
  fitRoute({ pulse: false })
}

const pulseRouteFocus = () => {
  if (!routePolyline) return
  if (focusPulseTimer) {
    clearTimeout(focusPulseTimer)
    focusPulseTimer = null
  }
  const baseWeight = useCongestion.value && !route.value?.routeServiceFallback ? 7 : 5
  const baseColor = routeLineColor.value
  routePolyline.setStyle({ color: '#0284c7', weight: baseWeight + 2, opacity: 1 })
  routeMarkers.forEach((marker, index) => {
    if (index === 0 || index === routeMarkers.length - 1) marker.openTooltip()
  })
  focusPulseTimer = setTimeout(() => {
    if (routePolyline) {
      routePolyline.setStyle({ color: baseColor, weight: baseWeight, opacity: 0.9 })
    }
    routeMarkers.forEach(marker => marker.closeTooltip())
    focusPulseTimer = null
  }, 1200)
}

const fitRoute = ({ pulse = true } = {}) => {
  if (!map) return
  const coords = route.value?.coordinates || []
  if (!coords.length) return
  map.invalidateSize()
  map.flyToBounds(L.latLngBounds(coords), { padding: [36, 36], duration: 0.6, maxZoom: 16 })
  if (pulse) pulseRouteFocus()
}

const requestedStopLabel = (index) => {
  if (!route.value) return ''
  if (index === 0) return '出发点'
  if (route.value.returnToStart && index === route.value.stops.length - 1) return '返回出发点'
  if (index === route.value.stops.length - 1) return '目的地'
  if (tourMode.value) return `第 ${index} 个目标`
  return '你添加的途经点'
}

const cleanInstruction = (value) => String(value || '按路线前进').replace(/<[^>]+>/g, '')

const formatDistance = (meters) => {
  const value = Number(meters || 0)
  return value >= 1000 ? `${(value / 1000).toFixed(1)} km` : `${Math.round(value)} m`
}

const formatDuration = (seconds) => {
  const value = Number(seconds || 0)
  if (value < 60) return `${Math.round(value)} 秒`
  return `${Math.round(value / 60)} 分钟`
}
</script>
