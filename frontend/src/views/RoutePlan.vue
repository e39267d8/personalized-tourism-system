<template>
  <div class="grid gap-6 xl:grid-cols-[0.8fr_1.2fr]">
    <section class="space-y-6">
      <div class="rounded-md border border-slate-200 bg-white p-5">
        <h1 class="text-2xl font-bold text-slate-950">路线规划</h1>
        <p class="mt-2 text-sm leading-6 text-slate-500">用图节点和边模拟 Dijkstra 结果，演示多目标、交通方式和预算约束。</p>

        <div class="mt-6 space-y-4">
          <div>
            <label class="text-sm font-semibold text-slate-700">路线模板</label>
            <select v-model.number="selectedRouteId" class="mt-2 w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm focus:border-teal-700 focus:outline-none">
              <option v-for="route in routes" :key="route.id" :value="route.id">{{ route.title }}</option>
            </select>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="text-sm font-semibold text-slate-700">交通方式</label>
              <select v-model="transport" class="mt-2 w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm focus:border-teal-700 focus:outline-none">
                <option>步行</option>
                <option>骑行</option>
                <option>地铁</option>
                <option>混合</option>
              </select>
            </div>
            <div>
              <label class="text-sm font-semibold text-slate-700">优化目标</label>
              <select v-model="goal" class="mt-2 w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm focus:border-teal-700 focus:outline-none">
                <option>时间优先</option>
                <option>距离优先</option>
                <option>预算优先</option>
                <option>均衡</option>
              </select>
            </div>
          </div>

          <div>
            <div class="flex items-center justify-between">
              <label class="text-sm font-semibold text-slate-700">拥挤容忍度</label>
              <span class="text-sm font-bold text-slate-950">{{ crowdTolerance }}</span>
            </div>
            <input v-model.number="crowdTolerance" type="range" min="1" max="4" step="1" class="mt-3 w-full accent-teal-700">
          </div>
        </div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-semibold text-slate-950">规划结果</h2>
          <span class="rounded-md bg-teal-50 px-2.5 py-1 text-sm font-semibold text-teal-800">可演示</span>
        </div>
        <div class="mt-4 grid grid-cols-3 gap-3">
          <div class="rounded-md bg-slate-50 p-3">
            <div class="text-xs text-slate-500">距离</div>
            <div class="mt-1 text-lg font-bold">{{ selectedRoute.distance }}</div>
          </div>
          <div class="rounded-md bg-slate-50 p-3">
            <div class="text-xs text-slate-500">时长</div>
            <div class="mt-1 text-lg font-bold">{{ selectedRoute.time }}</div>
          </div>
          <div class="rounded-md bg-slate-50 p-3">
            <div class="text-xs text-slate-500">预算</div>
            <div class="mt-1 text-lg font-bold">¥{{ adjustedCost }}</div>
          </div>
        </div>

        <div class="mt-5 space-y-3">
          <div v-for="(stop, index) in selectedRoute.stops" :key="stop" class="flex gap-3">
            <div class="grid h-8 w-8 flex-none place-items-center rounded-md bg-slate-900 text-sm font-bold text-white">{{ index + 1 }}</div>
            <div class="min-w-0 flex-1">
              <div class="font-semibold text-slate-950">{{ stop }}</div>
              <div class="text-sm text-slate-500">{{ index === 0 ? '出发点' : index === selectedRoute.stops.length - 1 ? '终点' : '途经节点' }}</div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="space-y-6">
      <div class="overflow-hidden rounded-md border border-slate-200 bg-white">
        <div class="flex items-center justify-between border-b border-slate-200 p-5">
          <div>
            <h2 class="text-lg font-semibold text-slate-950">地图预览</h2>
            <p class="mt-1 text-sm text-slate-500">演示路线会随模板切换。</p>
          </div>
          <button @click="fitRoute" class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">定位路线</button>
        </div>
        <div ref="mapContainer" class="h-[520px] w-full"></div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <h2 class="text-lg font-semibold text-slate-950">路线解释</h2>
        <div class="mt-4 grid gap-3 md:grid-cols-3">
          <div class="rounded-md bg-slate-50 p-4">
            <div class="text-sm font-semibold">算法</div>
            <p class="mt-1 text-sm text-slate-500">Dijkstra 最短路径，可替换真实后端结果。</p>
          </div>
          <div class="rounded-md bg-slate-50 p-4">
            <div class="text-sm font-semibold">约束</div>
            <p class="mt-1 text-sm text-slate-500">交通方式、拥挤度、预算目标。</p>
          </div>
          <div class="rounded-md bg-slate-50 p-4">
            <div class="text-sm font-semibold">可扩展</div>
            <p class="mt-1 text-sm text-slate-500">后续可接高德路线、实时拥堵和用户位置。</p>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import L from 'leaflet'
import { routePlans as fallbackRoutes } from '@/data/demoData'
import { tourismApi } from '@/services/tourismApi'

const selectedRouteId = ref(1)
const transport = ref('混合')
const goal = ref('均衡')
const crowdTolerance = ref(2)
const mapContainer = ref(null)
const routes = ref(fallbackRoutes)

let map
let routeLayer

const fallbackRouteCoordinates = {
  1: [[39.899318, 116.397957], [39.908692, 116.397477], [39.918058, 116.397026], [39.925048, 116.396621]],
  2: [[39.905103, 116.401015], [39.908780, 116.401216], [39.912657, 116.411013]],
  3: [[39.940269, 116.393776], [39.937661, 116.390855], [39.925455, 116.389535], [39.925048, 116.396621]]
}

const selectedRoute = computed(() => routes.value.find(route => route.id === selectedRouteId.value) || routes.value[0] || fallbackRoutes[0])
const selectedRouteCoordinates = computed(() => {
  if (selectedRoute.value?.coordinates?.length) return selectedRoute.value.coordinates
  return fallbackRouteCoordinates[selectedRouteId.value] || []
})
const adjustedCost = computed(() => selectedRoute.value.cost + (transport.value === '地铁' ? 12 : transport.value === '骑行' ? 8 : 0))

onMounted(async () => {
  try {
    const response = await tourismApi.routes()
    routes.value = response.items?.length ? response.items : fallbackRoutes
    if (!routes.value.some(route => route.id === selectedRouteId.value) && routes.value[0]) {
      selectedRouteId.value = routes.value[0].id
    }
  } catch (error) {
    routes.value = fallbackRoutes
  }
  await nextTick()
  map = L.map(mapContainer.value, { zoomControl: false }).setView([39.916, 116.397], 13)
  L.control.zoom({ position: 'bottomright' }).addTo(map)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: 'OpenStreetMap'
  }).addTo(map)
  drawRoute()
})

watch(selectedRouteId, () => drawRoute())
watch(routes, () => drawRoute(), { deep: true })

const drawRoute = () => {
  if (!map) return
  if (routeLayer) routeLayer.remove()
  const coords = selectedRouteCoordinates.value
  if (!coords.length) return
  routeLayer = L.layerGroup()
  L.polyline(coords, { color: '#0f766e', weight: 5, opacity: 0.9 }).addTo(routeLayer)
  coords.forEach((coord, index) => {
    L.circleMarker(coord, {
      radius: 8,
      color: '#0f172a',
      fillColor: '#ffffff',
      fillOpacity: 1,
      weight: 3
    }).bindTooltip(selectedRoute.value.stops[index] || `节点 ${index + 1}`).addTo(routeLayer)
  })
  routeLayer.addTo(map)
  fitRoute()
}

const fitRoute = () => {
  const coords = selectedRouteCoordinates.value
  if (map && coords.length) map.fitBounds(coords, { padding: [36, 36] })
}
</script>
