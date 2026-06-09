<template>
  <section class="rounded-md border border-slate-200 bg-white">
    <div class="flex flex-wrap items-start justify-between gap-3 border-b border-slate-200 p-5">
      <div>
        <h2 class="text-lg font-semibold text-slate-950">室内导航</h2>
        <p class="mt-1 text-sm leading-6 text-slate-500">
          {{ selectedBuilding ? selectedBuilding.description || '室内拓扑图与最短路径规划。' : '室内拓扑图与最短路径规划。' }}
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-2 text-sm">
        <span class="rounded-md bg-slate-100 px-2.5 py-1 font-semibold text-slate-700">{{ indoorStatusLabel }}</span>
        <span v-if="selectedBuilding" class="rounded-md bg-teal-50 px-2.5 py-1 font-semibold text-teal-800">
          {{ providerStatusLabel(selectedBuilding.provider) }}
        </span>
      </div>
    </div>

    <div v-if="error" class="m-5 rounded-md border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
      {{ error }}
    </div>

    <div v-if="loading" class="m-5 rounded-md border border-dashed border-slate-300 p-5 text-sm text-slate-500">
      正在读取室内导航数据...
    </div>

    <div v-else-if="!buildings.length" class="m-5 rounded-md border border-dashed border-slate-300 p-5 text-sm leading-6 text-slate-500">
      当前景点未接入室内导航。
    </div>

    <template v-else>
      <div class="grid gap-0 lg:grid-cols-[1.2fr_0.8fr]">
        <div class="border-b border-slate-200 p-5 lg:border-b-0 lg:border-r">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <div class="text-sm font-semibold text-slate-950">{{ selectedBuilding?.name || '室内建筑' }}</div>
              <div class="mt-1 text-xs text-slate-500">
                {{ floors.length }} 层 · {{ features.length }} 个节点 · {{ edges.length }} 条边
              </div>
            </div>

            <select
              v-if="buildings.length > 1"
              v-model="selectedBuildingId"
              class="h-10 rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
            >
              <option v-for="building in buildings" :key="building.id" :value="String(building.id)">
                {{ building.name }}
              </option>
            </select>
          </div>

          <div class="mt-4 flex flex-wrap gap-2">
            <button
              v-for="floor in floors"
              :key="floor.id"
              type="button"
              class="h-9 rounded-md border px-3 text-sm font-semibold"
              :class="floorButtonClass(floor.floorCode)"
              @click="activeFloor = floor.floorCode"
            >
              {{ floor.floorCode }}
            </button>
          </div>

          <div v-if="hasIncompleteGraph" class="mt-4 rounded-md border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
            室内图数据不完整，暂不能规划路线。
          </div>

          <div class="mt-4 overflow-hidden rounded-md border border-slate-200 bg-slate-50">
            <svg
              class="block aspect-[4/3] w-full bg-white"
              viewBox="0 0 100 100"
              role="img"
              :aria-label="`${activeFloor || '当前楼层'}室内拓扑图`"
            >
              <defs>
                <marker
                  id="indoor-arrow"
                  markerHeight="5"
                  markerWidth="5"
                  orient="auto"
                  refX="4"
                  refY="2.5"
                >
                  <path d="M0,0 L5,2.5 L0,5 Z" fill="#94a3b8" />
                </marker>
              </defs>

              <rect x="3" y="3" width="94" height="94" rx="3" fill="#f8fafc" stroke="#e2e8f0" />

              <g v-for="edge in displayEdges" :key="edge.displayKey">
                <line
                  :x1="pointForFeature(edge.from).x"
                  :y1="pointForFeature(edge.from).y"
                  :x2="pointForFeature(edge.to).x"
                  :y2="pointForFeature(edge.to).y"
                  :stroke="isRouteEdge(edge) ? '#0f766e' : '#cbd5e1'"
                  :stroke-width="isRouteEdge(edge) ? 2.4 : 1.4"
                  :stroke-dasharray="edge.edgeType === 'stairs' || edge.edgeType === 'elevator' ? '3 2' : ''"
                  stroke-linecap="round"
                />
              </g>

              <g v-for="marker in crossFloorMarkers" :key="marker.key">
                <line
                  :x1="pointForFeature(marker.feature).x"
                  :y1="pointForFeature(marker.feature).y"
                  :x2="pointForFeature(marker.feature).x + marker.dx"
                  :y2="pointForFeature(marker.feature).y - 10"
                  stroke="#0f766e"
                  stroke-width="1.6"
                  stroke-dasharray="2 2"
                  marker-end="url(#indoor-arrow)"
                />
                <rect
                  :x="pointForFeature(marker.feature).x + marker.dx - 8"
                  :y="pointForFeature(marker.feature).y - 18"
                  width="16"
                  height="6"
                  rx="2"
                  fill="#ccfbf1"
                  stroke="#5eead4"
                />
                <text
                  :x="pointForFeature(marker.feature).x + marker.dx"
                  :y="pointForFeature(marker.feature).y - 13.5"
                  text-anchor="middle"
                  fill="#134e4a"
                  font-size="3"
                  font-weight="700"
                >
                  {{ marker.label }}
                </text>
              </g>

              <g
                v-for="feature in activeFloorFeatures"
                :key="feature.id"
                class="cursor-pointer"
                @click="selectGraphFeature(feature)"
              >
                <circle
                  :cx="pointForFeature(feature).x"
                  :cy="pointForFeature(feature).y"
                  :r="nodeRadius(feature)"
                  :fill="nodeFill(feature)"
                  :stroke="nodeStroke(feature)"
                  :stroke-width="isRouteNode(feature.id) ? 2.4 : 1.4"
                />
                <circle
                  v-if="String(feature.id) === String(startFeatureId) || String(feature.id) === String(endFeatureId)"
                  :cx="pointForFeature(feature).x"
                  :cy="pointForFeature(feature).y"
                  r="5.8"
                  fill="none"
                  :stroke="String(feature.id) === String(startFeatureId) ? '#16a34a' : '#dc2626'"
                  stroke-width="1.3"
                />
                <text
                  :x="pointForFeature(feature).x"
                  :y="pointForFeature(feature).y + 8"
                  text-anchor="middle"
                  pointer-events="none"
                  fill="#334155"
                  font-size="3"
                  font-weight="700"
                >
                  {{ shortLabel(feature.name) }}
                </text>
              </g>
            </svg>

            <div class="flex flex-wrap items-center gap-3 border-t border-slate-200 bg-white px-4 py-3 text-xs text-slate-600">
              <span v-for="item in legendItems" :key="item.type" class="inline-flex items-center gap-1.5">
                <span class="h-2.5 w-2.5 rounded-full" :style="{ backgroundColor: item.color }"></span>
                {{ item.label }}
              </span>
            </div>
          </div>
        </div>

        <div class="p-5">
          <div class="grid gap-4">
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
              <div class="text-sm font-semibold text-slate-700">策略</div>
              <div class="mt-2 grid grid-cols-2 overflow-hidden rounded-md border border-slate-300 text-sm font-semibold">
                <button
                  v-for="item in strategyOptions"
                  :key="item.value"
                  type="button"
                  class="h-10"
                  :class="strategy === item.value ? 'bg-slate-900 text-white' : 'bg-white text-slate-700 hover:bg-slate-50'"
                  @click="strategy = item.value"
                >
                  {{ item.label }}
                </button>
              </div>
            </div>

            <div>
              <label class="text-sm font-semibold text-slate-700">起点</label>
              <input
                v-model="startQuery"
                type="search"
                class="mt-2 h-10 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
                :placeholder="selectedStartFeature ? selectedStartFeature.name : '搜索入口、房间或设施'"
              >
              <div class="mt-2 flex flex-wrap gap-2">
                <button
                  v-for="feature in startCandidates"
                  :key="feature.id"
                  type="button"
                  class="rounded-md border px-2.5 py-1.5 text-xs font-semibold"
                  :class="String(feature.id) === String(startFeatureId) ? 'border-teal-700 bg-teal-50 text-teal-800' : 'border-slate-200 bg-white text-slate-700 hover:bg-slate-50'"
                  @click="setRouteEndpoint('start', feature)"
                >
                  {{ feature.name }} · {{ feature.floorCode }}
                </button>
              </div>
            </div>

            <div>
              <label class="text-sm font-semibold text-slate-700">终点</label>
              <input
                v-model="endQuery"
                type="search"
                class="mt-2 h-10 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
                :placeholder="selectedEndFeature ? selectedEndFeature.name : '搜索展厅、卫生间或服务点'"
              >
              <div class="mt-2 flex flex-wrap gap-2">
                <button
                  v-for="feature in endCandidates"
                  :key="feature.id"
                  type="button"
                  class="rounded-md border px-2.5 py-1.5 text-xs font-semibold"
                  :class="String(feature.id) === String(endFeatureId) ? 'border-rose-700 bg-rose-50 text-rose-800' : 'border-slate-200 bg-white text-slate-700 hover:bg-slate-50'"
                  @click="setRouteEndpoint('end', feature)"
                >
                  {{ feature.name }} · {{ feature.floorCode }}
                </button>
              </div>
            </div>

            <button
              type="button"
              class="h-11 rounded-md bg-teal-700 px-4 text-sm font-semibold text-white hover:bg-teal-800 disabled:cursor-not-allowed disabled:bg-slate-400"
              :disabled="routeLoading || !canPlanRoute"
              @click="planRoute"
            >
              {{ routeLoading ? '规划中...' : '规划室内路线' }}
            </button>
          </div>

          <div v-if="route" class="mt-5 border-t border-slate-200 pt-5">
            <div class="grid grid-cols-3 gap-3 text-sm">
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
                <div class="mt-1 font-bold text-slate-950">{{ algorithmLabel(route.algorithm) }}</div>
              </div>
            </div>

            <div class="mt-4 flex flex-wrap gap-2 text-xs font-semibold">
              <span
                v-for="feature in routePath"
                :key="feature.id"
                class="rounded-md border border-slate-200 bg-white px-2 py-1 text-slate-700"
              >
                {{ feature.name }} · {{ feature.floorCode }}
              </span>
            </div>

            <ol class="mt-4 space-y-2">
              <li
                v-for="step in route.steps"
                :key="`${step.order}-${step.fromFeatureId}-${step.toFeatureId}`"
                class="border-l-4 border-teal-600 bg-slate-50 px-3 py-2 text-sm leading-6 text-slate-700"
              >
                <span class="font-semibold text-slate-950">{{ step.order }}.</span>
                {{ stepText(step) }}
                <span class="text-slate-400"> · {{ step.distanceMeters }} m · {{ durationLabel(step.durationSeconds) }}</span>
              </li>
            </ol>

            <div class="mt-4 rounded-md border border-slate-200 bg-white p-3 text-xs leading-5 text-slate-500">
              策略={{ strategyLabel(route.strategy) }} · 提供方={{ providerStatusLabel(route.configuredProvider) }} · 兜底={{ fallbackLabel(route.fallbackUsed) }}
            </div>
          </div>
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
const edges = ref([])
const featureTypes = ref([])
const selectedBuildingId = ref('')
const activeFloor = ref('')
const selectedType = ref('')
const startFeatureId = ref('')
const endFeatureId = ref('')
const startQuery = ref('')
const endQuery = ref('')
const strategy = ref('time')
const route = ref(null)

const strategyOptions = [
  { value: 'time', label: '时间优先' },
  { value: 'distance', label: '距离优先' }
]

const legendItems = [
  { type: 'entrance', label: '入口', color: '#22c55e' },
  { type: 'exhibition', label: '展厅', color: '#0ea5e9' },
  { type: 'service', label: '服务', color: '#f59e0b' },
  { type: 'toilet', label: '卫生间', color: '#8b5cf6' },
  { type: 'vertical', label: '楼梯/电梯', color: '#ef4444' },
  { type: 'route', label: '路线', color: '#0f766e' }
]

const selectedBuilding = computed(() => {
  return buildings.value.find(item => String(item.id) === String(selectedBuildingId.value)) || null
})

const featureById = computed(() => {
  return new Map(features.value.map(feature => [String(feature.id), feature]))
})

const selectedStartFeature = computed(() => featureById.value.get(String(startFeatureId.value)) || null)
const selectedEndFeature = computed(() => featureById.value.get(String(endFeatureId.value)) || null)

const routePath = computed(() => route.value?.path || [])

const routeNodeIds = computed(() => new Set(routePath.value.map(feature => String(feature.id))))

const routeFloorCodes = computed(() => {
  const codes = new Set(routePath.value.map(feature => feature.floorCode).filter(Boolean))
  return codes
})

const routeEdgeKeys = computed(() => {
  const keys = new Set()
  for (const step of route.value?.steps || []) {
    keys.add(`${step.fromFeatureId}-${step.toFeatureId}`)
    keys.add(`${step.toFeatureId}-${step.fromFeatureId}`)
  }
  return keys
})

const activeFloorFeatures = computed(() => {
  return features.value.filter(feature => feature.floorCode === activeFloor.value)
})

const displayEdges = computed(() => {
  const seen = new Set()
  const items = []
  for (const edge of edges.value) {
    const from = featureById.value.get(String(edge.fromFeatureId))
    const to = featureById.value.get(String(edge.toFeatureId))
    if (!from || !to) continue
    if (from.floorCode !== activeFloor.value || to.floorCode !== activeFloor.value) continue
    const low = Math.min(Number(edge.fromFeatureId), Number(edge.toFeatureId))
    const high = Math.max(Number(edge.fromFeatureId), Number(edge.toFeatureId))
    const displayKey = `${low}-${high}-${edge.edgeType}`
    if (seen.has(displayKey)) continue
    seen.add(displayKey)
    items.push({ ...edge, from, to, displayKey })
  }
  return items
})

const crossFloorMarkers = computed(() => {
  const markers = []
  for (const step of route.value?.steps || []) {
    if (step.fromFloorCode === step.toFloorCode) continue
    const from = featureById.value.get(String(step.fromFeatureId))
    const to = featureById.value.get(String(step.toFeatureId))
    if (from?.floorCode === activeFloor.value) {
      markers.push({
        key: `${step.order}-from`,
        feature: from,
        label: `至 ${step.toFloorCode}`,
        dx: 9
      })
    }
    if (to?.floorCode === activeFloor.value) {
      markers.push({
        key: `${step.order}-to`,
        feature: to,
        label: `自 ${step.fromFloorCode}`,
        dx: -9
      })
    }
  }
  return markers
})

const indoorStatusLabel = computed(() => {
  if (loading.value) return '读取中'
  if (!buildings.value.length) return '未接入'
  if (hasIncompleteGraph.value) return '图数据不完整'
  return `${buildings.value.length} 栋建筑`
})

const hasIncompleteGraph = computed(() => {
  return Boolean(selectedBuildingId.value) && (!features.value.length || !edges.value.length)
})

const canPlanRoute = computed(() => {
  if (hasIncompleteGraph.value) return false
  if (!selectedBuildingId.value || !startFeatureId.value || !endFeatureId.value) return false
  if (String(startFeatureId.value) === String(endFeatureId.value)) return false
  const ids = featureById.value
  return ids.has(String(startFeatureId.value)) && ids.has(String(endFeatureId.value))
})

const startCandidates = computed(() => candidateFeatures(startQuery.value, 'start'))
const endCandidates = computed(() => candidateFeatures(endQuery.value, 'end'))

const clamp = (value, min, max) => Math.min(max, Math.max(min, value))

const pointForFeature = (feature) => {
  return {
    x: clamp(Number(feature?.x || 0), 8, 92),
    y: clamp(Number(feature?.y || 0), 9, 88)
  }
}

const shortLabel = (name) => {
  const text = String(name || '')
  return text.length > 16 ? `${text.slice(0, 15)}...` : text
}

const featureTypeLabel = (type) => {
  return featureTypes.value.find(item => item.type === type)?.label || type || '节点'
}

const featureSearchText = (feature) => {
  return [
    feature.name,
    feature.type,
    featureTypeLabel(feature.type),
    feature.floorCode,
    feature.floorName
  ].join(' ').toLowerCase()
}

function candidateFeatures(query, role) {
  const text = String(query || '').trim().toLowerCase()
  const selectedId = role === 'start' ? startFeatureId.value : endFeatureId.value
  const oppositeId = role === 'start' ? endFeatureId.value : startFeatureId.value
  const preferredTypes = role === 'start'
    ? ['entrance', 'hallway', 'stairs', 'elevator', 'service']
    : ['exhibition', 'room', 'toilet', 'service', 'cafe']

  return features.value
    .filter(feature => String(feature.id) !== String(oppositeId))
    .filter(feature => !selectedType.value || feature.type === selectedType.value || String(feature.id) === String(selectedId))
    .filter(feature => !text || featureSearchText(feature).includes(text))
    .sort((left, right) => {
      const selectedScore = Number(String(right.id) === String(selectedId)) - Number(String(left.id) === String(selectedId))
      if (selectedScore) return selectedScore
      const floorScore = Number(right.floorCode === activeFloor.value) - Number(left.floorCode === activeFloor.value)
      if (floorScore) return floorScore
      const leftType = preferredTypes.indexOf(left.type)
      const rightType = preferredTypes.indexOf(right.type)
      return (leftType === -1 ? 99 : leftType) - (rightType === -1 ? 99 : rightType) || left.name.localeCompare(right.name)
    })
    .slice(0, 6)
}

const nodeFill = (feature) => {
  if (String(feature.id) === String(startFeatureId.value)) return '#dcfce7'
  if (String(feature.id) === String(endFeatureId.value)) return '#fee2e2'
  if (isRouteNode(feature.id)) return '#ccfbf1'
  if (feature.type === 'entrance') return '#22c55e'
  if (feature.type === 'exhibition') return '#0ea5e9'
  if (feature.type === 'service') return '#f59e0b'
  if (feature.type === 'toilet') return '#8b5cf6'
  if (feature.type === 'stairs' || feature.type === 'elevator') return '#ef4444'
  if (feature.type === 'hallway') return '#64748b'
  return '#94a3b8'
}

const nodeStroke = (feature) => {
  if (String(feature.id) === String(startFeatureId.value)) return '#16a34a'
  if (String(feature.id) === String(endFeatureId.value)) return '#dc2626'
  if (isRouteNode(feature.id)) return '#0f766e'
  return '#ffffff'
}

const nodeRadius = (feature) => {
  if (String(feature.id) === String(startFeatureId.value) || String(feature.id) === String(endFeatureId.value)) return 4.4
  if (isRouteNode(feature.id)) return 4.1
  return feature.type === 'stairs' || feature.type === 'elevator' ? 3.9 : 3.5
}

const isRouteNode = (id) => routeNodeIds.value.has(String(id))

const isRouteEdge = (edge) => {
  return routeEdgeKeys.value.has(`${edge.fromFeatureId}-${edge.toFeatureId}`)
}

const floorButtonClass = (floorCode) => {
  if (activeFloor.value === floorCode) return 'border-slate-900 bg-slate-900 text-white'
  if (routeFloorCodes.value.has(floorCode)) return 'border-teal-300 bg-teal-50 text-teal-800'
  return 'border-slate-300 bg-white text-slate-700 hover:bg-slate-50'
}

const edgeTypeText = (type) => {
  if (type === 'stairs') return '楼梯'
  if (type === 'elevator') return '电梯'
  if (type === 'corridor') return '通道'
  return type || '通道'
}

const providerStatusLabel = (provider) => {
  if (provider === 'local_indoor_graph') return '本地图计算引擎'
  if (provider === 'amap_indoor') return '高德室内地图'
  return provider || '未知提供方'
}

const algorithmLabel = (algorithm) => {
  if (algorithm === 'indoor-dijkstra') return 'Dijkstra 最短路径'
  if (algorithm === 'amap-indoor-routePath') return '高德室内路线'
  return algorithm || '未返回算法'
}

const strategyLabel = (value) => {
  return strategyOptions.find(item => item.value === value)?.label || value || '默认策略'
}

const fallbackLabel = (value) => value ? '是' : '否'

const stepText = (step) => {
  if (step.fromFloorCode !== step.toFloorCode) {
    return `通过${edgeTypeText(step.edgeType)}从 ${step.fromName}（${step.fromFloorCode}）到 ${step.toName}（${step.toFloorCode}）`
  }
  return `从 ${step.fromName} 前往 ${step.toName}`
}

const durationLabel = (seconds) => {
  const value = Number(seconds || 0)
  if (value < 60) return `${value} 秒`
  const minutes = Math.round(value / 60)
  return `${minutes} 分钟`
}

const chooseDefaultFeatures = () => {
  if (!features.value.length) {
    startFeatureId.value = ''
    endFeatureId.value = ''
    return
  }

  const start = features.value.find(item => item.type === 'entrance') || features.value[0]
  if (!featureById.value.has(String(startFeatureId.value))) startFeatureId.value = String(start.id)

  const target = features.value.find(item => String(item.id) !== String(startFeatureId.value) && ['exhibition', 'room', 'service', 'toilet'].includes(item.type))
    || features.value.find(item => String(item.id) !== String(startFeatureId.value))
  if (!featureById.value.has(String(endFeatureId.value)) || String(endFeatureId.value) === String(startFeatureId.value)) {
    endFeatureId.value = target ? String(target.id) : ''
  }
}

const ensureActiveFloor = () => {
  if (!floors.value.length) {
    activeFloor.value = ''
    return
  }
  if (floors.value.some(floor => floor.floorCode === activeFloor.value)) return
  const defaultFloor = selectedBuilding.value?.defaultFloorCode
  activeFloor.value = floors.value.find(floor => floor.floorCode === defaultFloor)?.floorCode || floors.value[0].floorCode
}

const setRouteEndpoint = (role, feature) => {
  if (role === 'start') {
    startFeatureId.value = String(feature.id)
    startQuery.value = ''
  } else {
    endFeatureId.value = String(feature.id)
    endQuery.value = ''
  }
  activeFloor.value = feature.floorCode || activeFloor.value
  route.value = null
}

const selectGraphFeature = (feature) => {
  if (!startFeatureId.value || String(feature.id) === String(endFeatureId.value)) {
    setRouteEndpoint('start', feature)
    return
  }
  setRouteEndpoint('end', feature)
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
    edges.value = data.edges || []
    ensureActiveFloor()
    chooseDefaultFeatures()
  } catch (requestError) {
    floors.value = []
    features.value = []
    featureTypes.value = []
    edges.value = []
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
  edges.value = []
  selectedBuildingId.value = ''
  activeFloor.value = ''
  selectedType.value = ''
  startFeatureId.value = ''
  endFeatureId.value = ''
  startQuery.value = ''
  endQuery.value = ''
  try {
    const data = await tourismApi.indoorBuildings(props.scenicSpotId)
    buildings.value = data.items || []
    selectedBuildingId.value = buildings.value[0] ? String(buildings.value[0].id) : ''
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
    const data = await tourismApi.planIndoorRoute(selectedBuildingId.value, {
      startFeatureId: Number(startFeatureId.value),
      endFeatureId: Number(endFeatureId.value),
      strategy: strategy.value
    })
    route.value = data
    const first = data.path?.[0]
    if (first?.floorCode) activeFloor.value = first.floorCode
  } catch (requestError) {
    error.value = requestError.response?.data?.message || '室内路线规划失败'
  } finally {
    routeLoading.value = false
  }
}

watch(() => props.scenicSpotId, loadBuildings, { immediate: true })

watch(selectedBuildingId, async (next, previous) => {
  if (!next || next === previous) return
  floors.value = []
  features.value = []
  featureTypes.value = []
  edges.value = []
  activeFloor.value = ''
  startFeatureId.value = ''
  endFeatureId.value = ''
  await loadFeatures()
})

watch([selectedType, strategy], () => {
  route.value = null
})

watch([startFeatureId, endFeatureId], () => {
  route.value = null
})
</script>
