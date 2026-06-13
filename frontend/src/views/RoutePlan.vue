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

          <div class="space-y-3">
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

          <!-- TSP tour mode toggle -->
          <div class="flex items-center gap-2 py-1">
            <input
              id="tourMode"
              v-model="tourMode"
              type="checkbox"
              class="w-4 h-4 rounded border-slate-300 text-teal-700 focus:ring-teal-500"
            />
            <label for="tourMode" class="text-sm font-semibold text-slate-700 cursor-pointer">环游模式 (TSP)</label>
            <span class="text-xs text-slate-400">多点间最短回路，自动回到起点</span>
          </div>

          <!-- Congestion-aware routing toggle -->
          <div class="flex items-center gap-2 py-1">
            <input
              id="congestionMode"
              v-model="useCongestion"
              type="checkbox"
              class="w-4 h-4 rounded border-slate-300 text-teal-700 focus:ring-teal-500"
            />
            <label for="congestionMode" class="text-sm font-semibold text-slate-700 cursor-pointer">拥挤度感知</label>
            <span class="text-xs text-slate-400">实时避开拥堵路段</span>
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
              <div class="text-xs text-slate-500">{{ tourMode && !route.routeServiceFallback ? 'TSP 距离' : '距离' }}</div>
              <div class="mt-1 text-lg font-bold">{{ route.distance }}</div>
            </div>
            <div class="rounded-md bg-slate-50 p-3">
              <div class="text-xs text-slate-500">{{ tourMode && !route.routeServiceFallback ? 'TSP 时长' : '时长' }}</div>
              <div class="mt-1 text-lg font-bold">{{ route.time }}</div>
            </div>
            <div class="rounded-md bg-slate-50 p-3">
              <div class="text-xs text-slate-500">{{ tourMode && !route.routeServiceFallback ? '算法' : '预估费用' }}</div>
              <div class="mt-1 text-base font-bold">{{ tourMode && !route.routeServiceFallback ? (route.algorithm || 'TSP') : ('¥' + route.cost) }}</div>
            </div>
          </div>

          <!-- TSP visit order -->
          <div v-if="tourMode && !route.routeServiceFallback && route.visitOrder" class="mt-3 rounded-md bg-teal-50 px-3 py-2 text-sm text-teal-800">
            访问顺序: {{ route.visitOrder.join(' → ') }}
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
import { computed, nextTick, onMounted, reactive, ref } from 'vue'
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
  waypoints.value.push({ id: Date.now() + Math.random(), name: newWaypoint.value })
  newWaypoint.value = ''
}

const removeWaypoint = (index) => {
  waypoints.value.splice(index, 1)
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

const planRoute = async () => {
  if (!form.startText || !form.endText) {
    error.value = '请输入出发点和目的地。'
    return
  }

  loading.value = true
  error.value = ''

  // TSP 环游模式：把输入地点解析为本地路网节点，后端跑真实 TSP + Dijkstra
  if (tourMode.value) {
    const texts = allStopTexts()
    try {
      if (texts.length < 2) {
        error.value = '环游模式至少需要两个地点。'
        return
      }
      const nodes = await loadRouteNodes()
      const resolved = texts.map(text => ({ text, node: resolveGraphNode(nodes, text) }))
      const missing = resolved.filter(item => !item.node).map(item => item.text)
      if (missing.length) {
        route.value = await routeServiceFallbackForStops(
          texts,
          'TSP 环游',
          graphNodeMissingMessage('环游模式', missing),
          '已按当前输入顺序显示真实道路路线'
        )
        drawRoute()
        return
      }

      const tourResult = await tourismApi.tourRoute({
        nodeIds: resolved.map(item => item.node.id),
        travelMode: localGraphTravelMode(),
        optimization: form.optimization
      })

      // 分层渲染：TSP 只决定访问顺序，真实道路折线交给路线服务按所选交通方式规划
      // （本地图的边没有道路几何，直接画会穿楼；环游闭环 = 末尾补回起点）
      const visitNames = tourResult.visitOrder || []
      const loopStops = visitNames.length >= 2 ? [...visitNames, visitNames[0]] : visitNames
      const amapRoute = await amapGeometryForStops(loopStops)

      route.value = {
        ...(amapRoute || tourResult),
        title: 'TSP 环游路线',
        algorithm: tourResult.algorithm || 'TSP',
        visitOrder: visitNames,
        transport: amapRoute?.transport || tourResult.transport || modeLabel(),
        usedTransportFallback: amapRoute ? false : tourResult.usedTransportFallback,
        requestedPlaces: amapRoute?.requestedPlaces?.length
          ? amapRoute.requestedPlaces
          : resolved.map(item => ({
              latitude: item.node.latitude,
              longitude: item.node.longitude,
              name: item.node.name
            }))
      }
      drawRoute()
    } catch (requestError) {
      try {
        route.value = await routeServiceFallbackForStops(
          texts,
          'TSP 环游',
          routeErrorMessage(requestError, 'TSP 环游规划失败'),
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
        algorithm: `拥挤度感知 Dijkstra · ${modeLabel()}`,
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

const routeErrorMessage = (requestError, fallbackText) =>
  requestError?.response?.data?.message || requestError?.message || fallbackText

const routeServiceFallbackForStops = async (stopTexts, modeName, reason, routeLabel) => {
  const routeServiceRoute = await amapGeometryForStops(stopTexts)
  if (!routeServiceRoute) {
    throw new Error(`${modeName}未生成可展示路线（${reason}），且路线服务兜底也不可用。`)
  }
  const fallbackLabel =
    form.travelMode === 'transit' && stopTexts.length > 2
      ? '地铁公交模式已按起终点显示真实道路路线'
      : routeLabel
  return {
    ...routeServiceRoute,
    title: `${modeName}兜底路线`,
    algorithm: '真实道路路线服务',
    routeServiceFallback: true,
    fallbackNotice: `${modeName}本地算法未生成可展示路线（${reason}），${fallbackLabel}；该路线不代表${modeName}算法结果。`,
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
  routeNodesCache = (data.items || []).filter(node => node.name && node.type !== 'junction')
  return routeNodesCache
}

const resolveGraphNode = (nodes, text) => {
  const query = String(text || '').trim()
  if (!query) return null
  let best = null
  let bestScore = 0
  for (const node of nodes) {
    let score = -1
    if (node.name === query || node.nodeName === query) score = 100
    else if (node.name.includes(query) || query.includes(node.name)) score = 60
    else if (node.nodeName && (node.nodeName.includes(query) || query.includes(node.nodeName))) score = 50
    if (score < 0) continue
    if (node.type === 'scenic') score += 20
    else if (node.type === 'entrance') score += 10
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

// 分层渲染的几何层：把算法层（TSP/拥挤度 Dijkstra）决定的停靠点序列
// 交给路线服务按所选交通方式取真实道路折线。路线服务不可用时返回 null，
// 调用方会优先展示通过后端质量闸门的本地路线；本地算法不可展示时可用
// 真实路线服务兜底，但必须显式标记为兜底结果，不再生成演示线。
// 地铁公交模式特殊处理：公交方案由线路决定，"途经点"语义不成立且
// 相邻停靠点太近时公交方案可能不可用——只用起终点直达。
const amapGeometryForStops = async (stopTexts) => {
  if (!stopTexts || stopTexts.length < 2) return null
  const isTransit = form.travelMode === 'transit'
  const stops = isTransit ? [stopTexts[0], stopTexts[stopTexts.length - 1]] : stopTexts
  const request = (travelMode) => tourismApi.planRoute({
    city: form.city || '北京',
    startText: stops[0],
    endText: stops[stops.length - 1],
    waypointTexts: stops.slice(1, -1),
    travelMode,
    optimization: form.optimization
  })
  try {
    return await request(form.travelMode)
  } catch {
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
  if (index === route.value.stops.length - 1) return '目的地'
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
