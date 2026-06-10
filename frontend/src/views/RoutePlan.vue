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

        <template v-if="route">
          <div class="mt-4 grid grid-cols-3 gap-3">
            <div class="rounded-md bg-slate-50 p-3">
              <div class="text-xs text-slate-500">{{ tourMode ? 'TSP 距离' : '距离' }}</div>
              <div class="mt-1 text-lg font-bold">{{ route.distance }}</div>
            </div>
            <div class="rounded-md bg-slate-50 p-3">
              <div class="text-xs text-slate-500">{{ tourMode ? 'TSP 时长' : '时长' }}</div>
              <div class="mt-1 text-lg font-bold">{{ route.time }}</div>
            </div>
            <div class="rounded-md bg-slate-50 p-3">
              <div class="text-xs text-slate-500">{{ tourMode ? '算法' : '预估费用' }}</div>
              <div class="mt-1 text-base font-bold">{{ tourMode ? (route.algorithm || 'TSP') : ('¥' + route.cost) }}</div>
            </div>
          </div>

          <!-- TSP visit order -->
          <div v-if="tourMode && route.visitOrder" class="mt-3 rounded-md bg-teal-50 px-3 py-2 text-sm text-teal-800">
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
          添加起点、途经点和目的地后会生成路线。后端会优先调用高德路线服务；如果接口不可用，前端会展示演示路线。
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
import L from 'leaflet'
import { tourismApi } from '@/services/tourismApi'

const mapContainer = ref(null)
const route = ref(null)
const loading = ref(false)
const error = ref('')
const newWaypoint = ref('')
const waypoints = ref([])
const tourMode = ref(false)
const useCongestion = ref(false)
const timeOfDay = ref(12)

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

const placeCoordinates = {
  前门大街: [39.8994, 116.3977],
  前门: [39.8994, 116.3977],
  天安门广场: [39.9055, 116.3976],
  天安门: [39.9087, 116.3975],
  故宫博物院: [39.9163, 116.3972],
  故宫: [39.9163, 116.3972],
  景山公园: [39.9251, 116.3967],
  国家博物馆: [39.9052, 116.4016],
  中国国家博物馆: [39.9052, 116.4016],
  王府井: [39.9148, 116.4112],
  王府井步行街: [39.9148, 116.4112],
  北海公园: [39.9255, 116.3896],
  鼓楼: [39.9402, 116.3958],
  什刹海: [39.9373, 116.3862],
  后海: [39.9417, 116.3828],
  天坛公园: [39.8822, 116.4066],
  天坛: [39.8822, 116.4066],
  雍和宫: [39.9471, 116.4173],
  南锣鼓巷: [39.9337, 116.4038],
  颐和园: [39.9999, 116.2755],
  圆明园: [40.0087, 116.3102],
  奥林匹克森林公园: [40.0164, 116.3899],
  奥森: [40.0164, 116.3899],
  三里屯: [39.9346, 116.4540],
  工体: [39.9294, 116.4410],
  '798艺术区': [39.9846, 116.4953],
  '798': [39.9846, 116.4953]
}

onMounted(async () => {
  await nextTick()
  map = L.map(mapContainer.value, { zoomControl: false }).setView([39.916, 116.397], 13)
  L.control.zoom({ position: 'bottomright' }).addTo(map)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: 'OpenStreetMap'
  }).addTo(map)
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

  // TSP tour mode: send all points to /api/v1/routes/tour
  if (tourMode.value) {
    try {
      const allTexts = allStopTexts()
      const allCoords = allTexts.map((name, i) => coordinateForPlace(name, i))
      // Build nodeIds from known coordinates (approximate - use index as node ID)
      const nodeIds = allTexts.map((_, i) => i + 1)

      const tourResult = await tourismApi.tourRoute({
        nodeIds,
        travelMode: form.travelMode,
        optimization: form.optimization
      })

      const tourStops = tourResult.visitOrder
        ? tourResult.visitOrder.map((idx) => allTexts[idx - 1] || `节点 ${idx}`)
        : allTexts

      const coords = tourResult.visitOrder
        ? tourResult.visitOrder.map((idx) => allCoords[idx - 1] || [39.916, 116.397])
        : allCoords

      route.value = {
        id: 0,
        route_id: 'tsp-tour-route',
        title: `TSP 环游路线`,
        stops: tourStops,
        requestedPlaces: coords.map((c, i) => ({ latitude: c[0], longitude: c[1], name: tourStops[i] || '' })),
        coordinates: coords,
        distance: `${(tourResult.tspDistance || 0 / 1000).toFixed(1)} km`,
        time: `${Math.max(1, Math.round((tourResult.tspDuration || 0) / 60))} 分钟`,
        cost: 0,
        algorithm: tourResult.algorithm || 'TSP',
        visitOrder: tourResult.visitOrder || [],
        transport: modeLabel(),
        segments: []
      }
      drawRoute()
    } catch {
      error.value = 'TSP 环游规划暂不可用'
    } finally {
      loading.value = false
    }
    return
  }

  // Congestion-aware mode
  if (useCongestion.value) {
    try {
      const nodeMap = {
        '前门大街': 1, '故宫博物院': 2, '天安门广场': 3, '景山公园': 4,
        '北海公园': 5, '天坛': 6, '颐和园': 7, '圆明园': 8
      }
      let startId = nodeMap[form.startText] || 1
      let endId = nodeMap[form.endText] || 2

      const congestionResult = await tourismApi.congestionRoute({
        start_id: startId,
        end_id: endId,
        travel_mode: form.travelMode === 'driving' ? 'car' : form.travelMode === 'transit' ? 'subway' : form.travelMode,
        hour: timeOfDay.value
      })

      const coords = []
      const stops = []
      if (congestionResult.path) {
        for (const pid of congestionResult.path) {
          const key = Object.keys(placeCoordinates).find(k => {
            for (const [nodeName, nodeId] of Object.entries(nodeMap)) {
              if (nodeId === pid) return k.includes(nodeName) || nodeName.includes(k)
            }
            return false
          })
          if (key) {
            coords.push(placeCoordinates[key])
            stops.push(key)
          }
        }
      }
      if (!coords.length) coords.push([39.916, 116.397], [39.928, 116.403])
      if (!stops.length) stops.push(form.startText, form.endText)

      route.value = {
        id: 0,
        route_id: 'congestion-route',
        title: `拥挤度感知路线 (${congestionResult.overall_congestion || '未知'})`,
        stops,
        coordinates: coords.length ? coords : [[39.916, 116.397], [39.928, 116.403]],
        distance: `${(congestionResult.total_distance || 0 / 1000).toFixed(1)} km`,
        time: `${Math.max(1, Math.round((congestionResult.total_duration || 0) / 60))} 分钟`,
        cost: 0,
        algorithm: `拥挤度感知 · ${modeLabel()}`,
        transport: modeLabel(),
        segments: congestionResult.congestion_segments ? Object.values(congestionResult.congestion_segments).map(s => ({
          title: `段${s.from}-${s.to}`,
          congestion: s.congestion_label || '未知',
          congestionColor: s.congestion_color || '#84cc16'
        })) : []
      }
      drawRoute()
    } catch {
      error.value = '拥挤度感知路由暂不可用'
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
    route.value = buildFallbackRoute()
    error.value = ''
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

const coordinateForPlace = (name, index) => {
  const key = Object.keys(placeCoordinates).find(item => name.includes(item) || item.includes(name))
  if (key) return placeCoordinates[key]

  const base = [39.916, 116.397]
  let hash = 0
  for (let i = 0; i < name.length; i += 1) hash = ((hash << 5) - hash + name.charCodeAt(i)) | 0
  const angle = ((Math.abs(hash) % 360) * Math.PI) / 180
  const radius = 0.01 + (index % 4) * 0.006
  return [
    base[0] + Math.sin(angle) * radius,
    base[1] + Math.cos(angle) * radius
  ]
}

const distanceMeters = (from, to) => {
  const earthRadius = 6371000
  const toRad = value => (value * Math.PI) / 180
  const dLat = toRad(to[0] - from[0])
  const dLng = toRad(to[1] - from[1])
  const lat1 = toRad(from[0])
  const lat2 = toRad(to[0])
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2
  return earthRadius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

const interpolateSegment = (from, to) => {
  const latFirst = Math.abs(to[0] - from[0]) > Math.abs(to[1] - from[1])
  const corner = latFirst ? [to[0], from[1]] : [from[0], to[1]]
  return [from, corner, to]
}

const modeLabel = () => ({
  walk: '步行',
  bike: '骑行',
  driving: '驾车',
  transit: '地铁公交'
}[form.travelMode] || '步行')

const speedMetersPerSecond = () => ({
  walk: 1.2,
  bike: 4.2,
  driving: 8,
  transit: 6
}[form.travelMode] || 1.2)

const buildFallbackRoute = () => {
  const stops = allStopTexts()
  const places = stops.map((name, index) => {
    const [latitude, longitude] = coordinateForPlace(name, index)
    return { name, latitude, longitude }
  })

  const coordinates = []
  const segments = []
  let totalDistance = 0
  let totalDuration = 0

  for (let i = 0; i + 1 < places.length; i += 1) {
    const from = places[i]
    const to = places[i + 1]
    const fromCoord = [from.latitude, from.longitude]
    const toCoord = [to.latitude, to.longitude]
    const distance = distanceMeters(fromCoord, toCoord) * (form.optimization === 'distance' ? 0.92 : 1.08)
    const duration = Math.max(180, Math.round(distance / speedMetersPerSecond()))
    totalDistance += distance
    totalDuration += duration
    const segmentCoords = interpolateSegment(fromCoord, toCoord)
    coordinates.push(...(coordinates.length ? segmentCoords.slice(1) : segmentCoords))
    segments.push({
      from: `从 ${from.name} 前往 ${to.name}`,
      to: to.name,
      transport: modeLabel(),
      distance,
      duration,
      congestion: 0
    })
  }

  return {
    id: 0,
    route_id: 'planned-route',
    title: `${stops[0]} 到 ${stops[stops.length - 1]}`,
    stops,
    requestedPlaces: places,
    segments,
    coordinates,
    distance: `${(totalDistance / 1000).toFixed(1)} km`,
    time: `${Math.max(1, Math.round(totalDuration / 60))} 分钟`,
    cost: form.travelMode === 'walk' ? 0 : Math.max(3, Math.round((totalDistance / 1000) * 2)),
    intensity: totalDistance > 3500 ? '中等' : '轻松',
    transport: modeLabel(),
    total_distance_meters: Math.round(totalDistance),
    total_duration_seconds: totalDuration
  }
}

const drawRoute = () => {
  if (!map) return
  if (routeLayer) routeLayer.remove()
  routeLayer = L.layerGroup()

  const coords = route.value?.coordinates || []
  if (!coords.length) {
    routeLayer.addTo(map)
    return
  }

  L.polyline(coords, { color: routeLineColor.value, weight: useCongestion.value ? 7 : 5, opacity: 0.9 }).addTo(routeLayer)

  const markers = route.value?.requestedPlaces?.length
    ? route.value.requestedPlaces.map(place => [place.latitude, place.longitude, place.name])
    : route.value.stops.map((stop, index) => {
        const coord = coords[Math.min(index, coords.length - 1)]
        return [coord[0], coord[1], stop]
      })

  markers.forEach(([latitude, longitude, name], index) => {
    L.circleMarker([latitude, longitude], {
      radius: index === 0 || index === markers.length - 1 ? 9 : 7,
      color: '#0f172a',
      fillColor: '#ffffff',
      fillOpacity: 1,
      weight: 3
    }).bindTooltip(name).addTo(routeLayer)
  })

  routeLayer.addTo(map)
  fitRoute()
}

const fitRoute = () => {
  if (!map) return
  const coords = route.value?.coordinates || []
  if (coords.length) map.fitBounds(coords, { padding: [36, 36] })
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
