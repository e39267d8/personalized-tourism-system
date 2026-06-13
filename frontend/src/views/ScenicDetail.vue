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
          <div class="flex flex-wrap items-center gap-2">
            <div class="inline-flex overflow-hidden rounded-md border border-slate-300 bg-white text-sm font-semibold">
              <button
                type="button"
                class="px-3 py-2"
                :class="internalViewMode === 'graph' ? 'bg-slate-900 text-white' : 'text-slate-700 hover:bg-slate-100'"
                @click="setInternalViewMode('graph')"
              >
                内部路网
              </button>
              <button
                type="button"
                class="border-l border-slate-300 px-3 py-2"
                :class="internalViewMode === 'map' ? 'bg-slate-900 text-white' : 'text-slate-700 hover:bg-slate-100'"
                @click="setInternalViewMode('map')"
              >
                地图服务
              </button>
            </div>
            <button
              v-if="internalViewMode === 'map'"
              type="button"
              class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100"
              @click="fitInternalMap(true)"
            >
              定位地图
            </button>
          </div>
        </div>
        <div class="grid gap-3 border-b border-slate-200 bg-slate-50 px-5 py-3 text-sm sm:grid-cols-4">
          <div>
            <div class="text-xs text-slate-500">内部节点</div>
            <div class="mt-0.5 font-semibold text-slate-900">{{ internalMapStats.nodes }} 个</div>
          </div>
          <div>
            <div class="text-xs text-slate-500">内部道路</div>
            <div class="mt-0.5 font-semibold text-slate-900">{{ internalMapStats.edges }} 条</div>
          </div>
          <div>
            <div class="text-xs text-slate-500">服务设施</div>
            <div class="mt-0.5 font-semibold text-slate-900">{{ internalMapStats.facilities }} 个</div>
          </div>
          <div>
            <div class="text-xs text-slate-500">可导航设施</div>
            <div class="mt-0.5 font-semibold text-slate-900">{{ internalMapStats.routableFacilities }} 个</div>
          </div>
        </div>
        <div
          v-if="internalViewMode === 'graph'"
          class="flex flex-wrap items-center justify-between gap-3 border-b border-slate-200 bg-white px-5 py-3"
        >
          <div class="flex flex-wrap items-center gap-2">
            <button
              type="button"
              class="rounded-md border px-3 py-1.5 text-sm font-semibold"
              :class="internalGraphScope === 'focus' ? 'border-slate-900 bg-slate-900 text-white' : 'border-slate-300 text-slate-700 hover:bg-slate-100'"
              @click="internalGraphScope = 'focus'"
            >
              聚焦路网
            </button>
            <button
              type="button"
              class="rounded-md border px-3 py-1.5 text-sm font-semibold"
              :class="internalGraphScope === 'full' ? 'border-slate-900 bg-slate-900 text-white' : 'border-slate-300 text-slate-700 hover:bg-slate-100'"
              @click="internalGraphScope = 'full'"
            >
              全量数据
            </button>
          </div>
          <label class="flex items-center gap-2 text-sm font-semibold text-slate-600">
            <input v-model="showGraphConnectors" type="checkbox" class="h-4 w-4 accent-teal-700">
            显示设施接入边
          </label>
        </div>
        <div class="relative">
          <div v-show="internalViewMode === 'graph'" class="internal-graph relative h-[420px] w-full overflow-hidden">
            <svg class="h-full w-full" :viewBox="internalGraphViewBox" preserveAspectRatio="xMidYMid meet" role="img" aria-label="内部道路图">
              <rect :width="GRAPH_WIDTH" :height="GRAPH_HEIGHT" fill="transparent" />
              <path
                v-if="internalGraphConnectorPath"
                :d="internalGraphConnectorPath"
                fill="none"
                stroke="#94a3b8"
                stroke-width="1.1"
                stroke-dasharray="4 7"
                stroke-linecap="round"
                stroke-linejoin="round"
                opacity="0.32"
                vector-effect="non-scaling-stroke"
              />
              <path
                v-if="internalGraphRoadPath"
                :d="internalGraphRoadPath"
                fill="none"
                stroke="#ffffff"
                stroke-width="7"
                stroke-linecap="round"
                stroke-linejoin="round"
                opacity="0.92"
                vector-effect="non-scaling-stroke"
              />
              <path
                v-if="internalGraphRoadPath"
                :d="internalGraphRoadPath"
                fill="none"
                stroke="#536173"
                stroke-width="2.6"
                stroke-linecap="round"
                stroke-linejoin="round"
                opacity="0.88"
                vector-effect="non-scaling-stroke"
              />
              <path
                v-if="internalGraphRoutePath"
                :d="internalGraphRoutePath"
                fill="none"
                stroke="#ffffff"
                stroke-width="11"
                stroke-linecap="round"
                stroke-linejoin="round"
                opacity="0.9"
                vector-effect="non-scaling-stroke"
              />
              <path
                v-if="internalGraphRoutePath"
                :d="internalGraphRoutePath"
                fill="none"
                stroke="#0f766e"
                stroke-width="5.8"
                stroke-linecap="round"
                stroke-linejoin="round"
                opacity="0.95"
                vector-effect="non-scaling-stroke"
              />
              <g
                v-for="item in internalGraphFacilities"
                :key="item.facility.id"
                :transform="`translate(${item.x} ${item.y})`"
                class="cursor-pointer"
                @click="selectInternalGraphFacility(item.facility)"
              >
                <title>{{ item.facility.name }}</title>
                <circle
                  v-if="String(item.facility.id) === String(selectedFacilityId)"
                  :r="graphFacilityRadius(item.facility) + 5"
                  fill="#0f766e"
                  opacity="0.13"
                />
                <circle
                  :r="graphFacilityRadius(item.facility)"
                  :fill="graphMarkerColor(item.facility)"
                  stroke="#ffffff"
                  :stroke-width="String(item.facility.id) === String(selectedFacilityId) ? 2.4 : 1.8"
                  :opacity="graphMarkerOpacity(item.facility)"
                />
              </g>
              <g v-if="selectedGraphFacilityPoint" :transform="`translate(${selectedGraphFacilityPoint.x} ${selectedGraphFacilityPoint.y})`">
                <rect
                  x="10"
                  y="-35"
                  :width="selectedGraphLabelWidth"
                  height="28"
                  rx="8"
                  fill="#ffffff"
                  stroke="#dbe4ee"
                  stroke-width="1"
                  opacity="0.96"
                />
                <text
                  x="22"
                  y="-16"
                  class="fill-slate-900 text-[15px] font-bold"
                >
                  {{ selectedGraphFacilityLabel }}
                </text>
              </g>
            </svg>
            <div class="pointer-events-none absolute left-3 top-3 rounded-md border border-white/80 bg-white/90 px-3 py-2 text-xs font-semibold text-slate-700 shadow-sm">
              {{ internalGraphScope === 'focus' ? '聚焦主路网' : '全量数据库路网' }}
            </div>
            <div class="pointer-events-none absolute right-3 top-3 flex flex-wrap gap-2 rounded-md border border-white/80 bg-white/90 px-3 py-2 text-xs font-semibold text-slate-700 shadow-sm">
              <span class="inline-flex items-center gap-1.5">
                <span class="h-0.5 w-5 rounded-full bg-slate-600"></span>
                真实道路
              </span>
              <span v-if="showGraphConnectors" class="inline-flex items-center gap-1.5">
                <span class="h-0.5 w-5 rounded-full border-t border-dashed border-slate-400"></span>
                设施接入
              </span>
              <span class="inline-flex items-center gap-1.5">
                <span class="h-1 w-5 rounded-full bg-teal-700"></span>
                规划路线
              </span>
            </div>
            <div
              v-if="!internalGraphRoadPath && !internalGraphConnectorPath"
              class="absolute inset-0 flex items-center justify-center text-sm font-semibold text-slate-500"
            >
              暂无可展示的内部路网数据
            </div>
            <div class="pointer-events-none absolute bottom-3 left-3 rounded-md border border-white/80 bg-white/90 px-3 py-2 text-xs font-semibold text-slate-600 shadow-sm">
              当前显示 {{ internalGraphDisplayStats.roadEdges }} 条真实道路 · {{ internalGraphDisplayStats.facilities }} 个设施点
            </div>
          </div>
          <div
            v-show="internalViewMode === 'map'"
            ref="internalMapContainer"
            class="internal-map h-[420px] w-full"
            :class="{ 'cursor-crosshair': selectedStartMode === 'map' && amapReady }"
          ></div>
          <div v-if="internalViewMode === 'map'" class="pointer-events-none absolute left-3 top-3 rounded-md border border-white/80 bg-white/90 px-3 py-2 text-xs font-semibold text-slate-700 shadow-sm">
            {{ mapStatusLabel }}
          </div>
          <div v-if="internalViewMode === 'map'" class="pointer-events-none absolute right-3 top-3 flex flex-wrap gap-2 rounded-md border border-white/80 bg-white/90 px-3 py-2 text-xs font-semibold text-slate-700 shadow-sm">
            <span class="inline-flex items-center gap-1.5">
              <span class="h-0.5 w-5 rounded-full bg-slate-500"></span>
              内部道路
            </span>
            <span class="inline-flex items-center gap-1.5">
              <span class="h-2.5 w-2.5 rounded-full bg-slate-900"></span>
              服务设施
            </span>
            <span class="inline-flex items-center gap-1.5">
              <span class="h-1 w-5 rounded-full bg-teal-700"></span>
              规划路线
            </span>
          </div>
          <div
            v-if="internalViewMode === 'map' && selectedStartMode === 'map'"
            class="pointer-events-none absolute left-3 top-14 rounded-md border border-slate-200 bg-white/90 px-3 py-2 text-xs font-semibold text-slate-700 shadow-sm"
          >
            {{ selectedStartPoint ? `起点 ${selectedStartPointLabel}` : '点击地图选择起点' }}
          </div>
          <div v-if="internalViewMode === 'map' && amapError" class="absolute inset-x-4 bottom-4 rounded-md border border-amber-200 bg-white/95 p-3 text-sm leading-6 text-amber-800 shadow-sm">
            {{ amapError }}。自动入口和下拉起点仍可规划路线，地图点选需要地图服务加载成功。
          </div>
        </div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-center justify-between gap-3">
          <h2 class="text-lg font-semibold text-slate-950">设施查询</h2>
          <div class="flex items-center gap-2">
            <span v-if="facilityLoading" class="rounded-md bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500">计算中</span>
            <span v-if="facilitySortedByWalk" class="rounded-md bg-teal-50 px-2.5 py-1 text-xs font-semibold text-teal-700" title="按内部路网实际步行距离排序">实际步行距离排序</span>
            <span class="rounded-md bg-slate-100 px-2.5 py-1 text-sm font-semibold text-slate-700">{{ routableFacilities.length }}/{{ facilities.length }} 可导航</span>
          </div>
        </div>

        <!-- 等时圈图例：从当前查询位置按内部路网步行距离分层（地图标记同色） -->
        <div v-if="facilitySortedByWalk" class="mt-3 flex flex-wrap items-center gap-x-3 gap-y-1 rounded-md bg-slate-50 px-3 py-2">
          <span class="text-xs font-semibold text-slate-600">{{ facilityDistanceOriginLabel }}等时圈</span>
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
            <label class="text-sm font-semibold text-slate-700">关键词</label>
            <input
              v-model.trim="facilitySearchKeyword"
              type="search"
              class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700"
              placeholder="输入厕所、商店、餐饮或设施名称"
            >
          </div>

          <div class="mt-4">
            <label class="text-sm font-semibold text-slate-700">步行范围</label>
            <select v-model="selectedFacilityRange" class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700">
              <option v-for="range in facilityRangeOptions" :key="range.value" :value="range.value">
                {{ range.label }}
              </option>
            </select>
          </div>

          <div class="mt-4">
            <label class="text-sm font-semibold text-slate-700">查询位置 / 路线起点</label>
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
              <div v-if="selectedMapNearestNode" class="mt-1 text-xs text-slate-500">
                距离排序已吸附到：{{ selectedMapNearestNode.name || '最近路网节点' }}
              </div>
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
              系统会使用景区入口或路网默认起点，并按内部路网实际步行距离排序附近设施。
            </div>
          </div>

          <div class="mt-4 rounded-md border border-slate-200 bg-slate-50 p-3">
            <div class="flex items-center justify-between gap-2">
              <div>
                <div class="text-sm font-semibold text-slate-900">附近设施</div>
                <div class="mt-0.5 text-xs text-slate-500">
                  当前显示 {{ visibleFacilities.length }} 个结果，可达设施按实际步行距离升序排列。
                </div>
              </div>
              <span class="rounded-md bg-white px-2.5 py-1 text-xs font-semibold text-slate-600">
                {{ facilityDistanceOriginLabel }}
              </span>
            </div>
            <div v-if="nearbyFacilities.length" class="mt-3 max-h-72 space-y-2 overflow-auto pr-1">
              <button
                v-for="facility in nearbyFacilities"
                :key="facility.id"
                type="button"
                class="w-full rounded-md border bg-white p-3 text-left transition hover:border-teal-300 hover:bg-teal-50 disabled:cursor-not-allowed disabled:opacity-60"
                :class="String(facility.id) === String(selectedFacilityId) ? 'border-teal-500 ring-1 ring-teal-500' : 'border-slate-200'"
                :disabled="!isFacilitySelectable(facility)"
                @click="selectNearbyFacility(facility)"
              >
                <div class="flex items-start justify-between gap-3">
                  <div class="min-w-0">
                    <div class="truncate text-sm font-semibold text-slate-900">{{ facility.name }}</div>
                    <div class="mt-1 text-xs text-slate-500">{{ facility.typeLabel || facility.type || '设施' }}</div>
                  </div>
                  <div class="shrink-0 text-right">
                    <div class="text-sm font-bold text-slate-950">{{ facilityDistanceText(facility) }}</div>
                    <div class="mt-1 text-xs text-slate-500">{{ facilityWalkTimeText(facility) }}</div>
                  </div>
                </div>
              </button>
            </div>
            <div v-else class="mt-3 rounded-md border border-dashed border-slate-300 bg-white p-4 text-sm text-slate-500">
              当前查询位置和筛选条件下没有可达设施，请调整类别、关键词或步行范围。
            </div>
          </div>

          <div class="mt-4">
            <label class="text-sm font-semibold text-slate-700">目的设施</label>
            <select v-model="selectedFacilityId" class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700">
              <option v-for="facility in destinationFacilities" :key="facility.id" :value="facility.id">
                {{ facility.name }} · {{ facility.typeLabel }} · {{ facilityDistanceText(facility) }} · {{ facilityWalkTimeText(facility) }}
              </option>
            </select>
            <p v-if="!destinationFacilities.length" class="mt-2 text-sm text-amber-700">
              当前筛选下没有可导航且可达的设施，请调整类别、关键词或步行范围。
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
const facilityLoading = ref(false)
const popularTimes = ref(null)  // 热门时段画像（行为数据/模型）
const currentHour = new Date().getHours()
// 图表只展示 6:00-22:00（夜间小时无信息量）
const visiblePopularHours = computed(() =>
  (popularTimes.value?.hours || []).filter(item => item.hour >= 6 && item.hour <= 22))
const internalMap = ref({ nodes: [], edges: [], nodeCount: 0, edgeCount: 0 })
const internalRoute = ref(null)
const internalError = ref('')
const internalLoading = ref(false)
const selectedFacilityType = ref('')
const facilitySearchKeyword = ref('')
const selectedFacilityRange = ref('')
const selectedFacilityId = ref('')
const selectedStartMode = ref('auto')
const selectedStartNodeId = ref('')
const selectedStartPoint = ref(null)
const showAllFacilities = ref(false)
const internalViewMode = ref('graph')
const internalGraphScope = ref('focus')
const showGraphConnectors = ref(false)
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
let facilityRequestSeq = 0

const GRAPH_WIDTH = 1000
const GRAPH_HEIGHT = 560
const GRAPH_PADDING = 48
const internalGraphViewBox = `0 0 ${GRAPH_WIDTH} ${GRAPH_HEIGHT}`
const GRAPH_FOCUS_EDGE_LIMIT = 1800
const GRAPH_FULL_EDGE_LIMIT = 3600
const GRAPH_FACILITY_LIMIT = 56

const facilityRangeOptions = [
  { value: '', label: '全部可达范围' },
  { value: '300', label: '300 米内' },
  { value: '500', label: '500 米内' },
  { value: '1000', label: '1000 米内' },
  { value: '1500', label: '1500 米内' }
]

const normalizeFacilityText = (value) => String(value || '').trim().toLowerCase()

const facilityKeywordAliases = [
  { words: ['厕所', '卫生间', '洗手间', 'wc'], terms: ['厕所', '卫生间', '洗手间', 'toilet', 'restroom'] },
  { words: ['超市', '商店', '便利店'], terms: ['超市', '商店', '便利店', 'shop', 'store'] },
  { words: ['餐饮', '餐厅', '吃饭', '咖啡'], terms: ['餐饮', '餐厅', '饭店', '咖啡', 'restaurant', 'cafe'] },
  { words: ['入口', '出口', '门'], terms: ['入口', '出口', '门', 'entrance', 'gate'] },
  { words: ['建筑', '楼', '场所'], terms: ['建筑', '楼', 'building'] }
]

const facilityTypePriority = { entrance: 0, toilet: 1, restaurant: 2, cafe: 3, shop: 4, service: 5, building: 6 }

const pointOf = (item) => {
  if (!item || item.latitude === undefined || item.longitude === undefined) return null
  const latitude = Number(item.latitude)
  const longitude = Number(item.longitude)
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null
  return { latitude, longitude }
}

const distanceMetersBetween = (left, right) => {
  const a = pointOf(left)
  const b = pointOf(right)
  if (!a || !b) return Number.POSITIVE_INFINITY
  const latRad = Math.PI / 180
  const dLat = (b.latitude - a.latitude) * latRad
  const dLng = (b.longitude - a.longitude) * latRad
  const lat1 = a.latitude * latRad
  const lat2 = b.latitude * latRad
  const sinLat = Math.sin(dLat / 2)
  const sinLng = Math.sin(dLng / 2)
  const h = sinLat * sinLat + Math.cos(lat1) * Math.cos(lat2) * sinLng * sinLng
  return 6371000 * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h))
}

const connectedInternalNodeIds = computed(() => {
  const ids = new Set()
  for (const edge of internalMap.value.edges || []) {
    if (edge.fromNodeId) ids.add(String(edge.fromNodeId))
    if (edge.toNodeId) ids.add(String(edge.toNodeId))
  }
  return ids
})

const isConnectedInternalNode = (node) => Boolean(node?.id && connectedInternalNodeIds.value.has(String(node.id)))

const nearestInternalNode = (point, connectedOnly = false) => {
  if (!point) return null
  let bestNode = null
  let bestDistance = Number.POSITIVE_INFINITY
  for (const node of internalMap.value.nodes || []) {
    if (!node.id) continue
    if (connectedOnly && !isConnectedInternalNode(node)) continue
    const distance = distanceMetersBetween(point, node)
    if (distance < bestDistance) {
      bestDistance = distance
      bestNode = node
    }
  }
  return bestNode
}

const nearestConnectedNode = (node) => {
  if (!node) return null
  if (isConnectedInternalNode(node)) return node
  return nearestInternalNode(node, true)
}

const preferredInternalNodeSourceRank = (node) => {
  if (node?.source === 'campus_curated' || node?.source === 'demo') return 0
  if (node?.source === 'osm') return 1
  return 2
}

const rawDefaultStartNode = computed(() => {
  const nodes = internalMap.value.nodes || []
  return nodes.find(node => node.type === 'entrance' && preferredInternalNodeSourceRank(node) === 0)
    || nodes.find(node => node.type === 'entrance')
    || nodes.find(node => node.id && preferredInternalNodeSourceRank(node) === 0)
    || nodes.find(node => node.id)
    || null
})

const defaultInternalStartNode = computed(() => {
  const nodes = internalMap.value.nodes || []
  return nearestConnectedNode(rawDefaultStartNode.value) || nodes.find(isConnectedInternalNode) || rawDefaultStartNode.value
})

const selectedRawStartNode = computed(() => {
  if (selectedStartMode.value !== 'node' || !selectedStartNodeId.value) return null
  return (internalMap.value.nodes || []).find(node => String(node.id) === String(selectedStartNodeId.value)) || null
})

const selectedMapNearestNode = computed(() => nearestInternalNode(selectedStartPoint.value, true))

const facilitySourceNode = computed(() => {
  if (selectedStartMode.value === 'node' && selectedStartNodeId.value) {
    return nearestConnectedNode(selectedRawStartNode.value) || defaultInternalStartNode.value
  }
  if (selectedStartMode.value === 'map' && selectedStartPoint.value) {
    return selectedMapNearestNode.value || defaultInternalStartNode.value
  }
  return defaultInternalStartNode.value
})

const facilityDistanceOriginLabel = computed(() => {
  if (selectedStartMode.value === 'map' && selectedStartPoint.value) return '点选位置'
  if (selectedStartMode.value === 'node' && selectedStartNodeId.value) {
    return selectedRawStartNode.value?.name || facilitySourceNode.value?.name || '所选场所'
  }
  return '入口'
})

const facilitySearchNeedles = computed(() => {
  const query = normalizeFacilityText(facilitySearchKeyword.value)
  if (!query) return []
  const aliases = facilityKeywordAliases
    .filter(group => group.words.some(word => query.includes(normalizeFacilityText(word))))
    .flatMap(group => group.terms)
    .map(normalizeFacilityText)
  return [...new Set([query, ...aliases].filter(Boolean))]
})

const facilityRangeLimit = computed(() => Number(selectedFacilityRange.value || 0))

const facilityWalkDistanceValue = (facility) => {
  const distance = Number(facility?.walkDistance)
  return Number.isFinite(distance) ? distance : -1
}

const facilityMatchesKeyword = (facility) => {
  const needles = facilitySearchNeedles.value
  if (!needles.length) return true
  const haystack = normalizeFacilityText([
    facility.name,
    facility.typeLabel,
    facility.type,
    facility.address
  ].filter(Boolean).join(' '))
  return needles.some(needle => haystack.includes(needle))
}

const facilityMatchesRange = (facility) => {
  const limit = facilityRangeLimit.value
  if (!limit) return true
  const distance = facilityWalkDistanceValue(facility)
  return distance >= 0 && distance <= limit
}

const compareFacilities = (left, right) => {
  if (facilitySortedByWalk.value) {
    const leftDistance = facilityWalkDistanceValue(left)
    const rightDistance = facilityWalkDistanceValue(right)
    if (leftDistance >= 0 && rightDistance >= 0 && leftDistance !== rightDistance) return leftDistance - rightDistance
    if (leftDistance >= 0) return -1
    if (rightDistance >= 0) return 1
  }
  const routableDelta = Number(Boolean(right.routable)) - Number(Boolean(left.routable))
  if (routableDelta) return routableDelta
  const leftPriority = facilityTypePriority[left.type] ?? 99
  const rightPriority = facilityTypePriority[right.type] ?? 99
  if (leftPriority !== rightPriority) return leftPriority - rightPriority
  return String(left.name || '').localeCompare(String(right.name || ''))
}

const visibleFacilityPool = computed(() => {
  return showAllFacilities.value ? facilities.value : routableFacilities.value
})

const queryFilteredFacilityPool = computed(() => {
  return visibleFacilityPool.value
    .filter(facilityMatchesKeyword)
    .filter(facilityMatchesRange)
})

const routableFacilities = computed(() => facilities.value.filter(item => item.routable))

const visibleFacilities = computed(() => {
  const items = selectedFacilityType.value
    ? queryFilteredFacilityPool.value.filter(item => item.type === selectedFacilityType.value)
    : queryFilteredFacilityPool.value
  return [...items].sort(compareFacilities)
})

const internalMapStats = computed(() => {
  const nodes = Number(internalMap.value.nodeCount ?? internalMap.value.nodes?.length ?? 0)
  const edges = Number(internalMap.value.edgeCount ?? internalMap.value.edges?.length ?? 0)
  return {
    nodes,
    edges,
    facilities: facilities.value.length,
    routableFacilities: routableFacilities.value.length
  }
})

const destinationFacilities = computed(() => {
  return visibleFacilities.value.filter(item => item.routable && (!facilitySortedByWalk.value || facilityWalkDistanceValue(item) >= 0))
})

const nearbyFacilities = computed(() => visibleFacilities.value.slice(0, 12))

const visibleFacilityTypes = computed(() => {
  const labelByType = new Map(facilityTypes.value.map(type => [type.type, type.label]))
  const counts = new Map()
  for (const facility of queryFilteredFacilityPool.value) {
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
    .sort((left, right) => preferredInternalNodeSourceRank(left) - preferredInternalNodeSourceRank(right) || (priority[left.type] ?? 9) - (priority[right.type] ?? 9) || left.name.localeCompare(right.name))
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
  const startText = selectedStartMode.value === 'map'
    ? '地图点选起点'
    : facilityDistanceOriginLabel.value
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

const setInternalViewMode = async (mode) => {
  internalViewMode.value = mode
  if (mode !== 'map') return
  await nextTick()
  await initInternalMap()
  if (map) {
    if (typeof map.resize === 'function') map.resize()
    drawInternalMap(true)
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
  loadFacilitiesForCurrentSource()
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
  if (mode !== 'map' || selectedStartPoint.value) {
    loadFacilitiesForCurrentSource()
  }
}

const clearMapStart = () => {
  selectedStartPoint.value = null
  internalRoute.value = null
  internalError.value = ''
  drawStartMarker()
  drawInternalRoute()
  loadFacilitiesForCurrentSource()
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

const loadFacilitiesForCurrentSource = async ({ resetSelection = false, redraw = true } = {}) => {
  const requestId = ++facilityRequestSeq
  facilityLoading.value = true
  const sourceNode = facilitySourceNode.value
  const facilityParams = { limit: 200 }
  if (sourceNode?.id) facilityParams.from_node_id = sourceNode.id

  try {
    const facilityData = await tourismApi.scenicFacilities(props.id, facilityParams)
    if (requestId !== facilityRequestSeq) return
    facilities.value = facilityData.items || []
    facilityTypes.value = facilityData.types || []
    facilitySortedByWalk.value = !!(facilityData.sortedByWalkDistance && sourceNode?.id)
    if (resetSelection) selectedFacilityId.value = ''
    if (selectedFacilityType.value && !visibleFacilityTypes.value.some(type => type.type === selectedFacilityType.value)) {
      selectedFacilityType.value = ''
    }
    ensureSelectedFacility()
    if (redraw) drawInternalMap()
  } catch {
    if (requestId !== facilityRequestSeq) return
    facilities.value = []
    facilityTypes.value = []
    facilitySortedByWalk.value = false
    internalError.value = '设施查询暂不可用'
    if (redraw) drawInternalMap()
  } finally {
    if (requestId === facilityRequestSeq) facilityLoading.value = false
  }
}

const loadInternalNavigation = async () => {
  internalError.value = ''
  internalRoute.value = null
  selectedFacilityId.value = ''
  selectedStartMode.value = 'auto'
  selectedStartNodeId.value = ''
  selectedStartPoint.value = null
  selectedFacilityType.value = ''
  facilitySearchKeyword.value = ''
  selectedFacilityRange.value = ''
  facilitySortedByWalk.value = false
  try {
    // 先加载内部路网，再按当前查询位置用 Dijkstra 实际步行距离排序设施。
    const mapData = await tourismApi.scenicInternalMap(props.id)
    internalMap.value = {
      nodes: mapData.nodes || [],
      edges: mapData.edges || [],
      nodeCount: mapData.nodeCount ?? (mapData.nodes || []).length,
      edgeCount: mapData.edgeCount ?? (mapData.edges || []).length
    }

    await loadFacilitiesForCurrentSource({ resetSelection: true, redraw: false })
    drawInternalMap(true)
  } catch (error) {
    facilities.value = []
    facilityTypes.value = []
    internalMap.value = { nodes: [], edges: [], nodeCount: 0, edgeCount: 0 }
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

const facilityDistanceText = (facility) => {
  const distance = facilityWalkDistanceValue(facility)
  if (distance < 0) return '不可达'
  if (distance >= 1000) return `${(distance / 1000).toFixed(1)} km`
  return `${Math.round(distance)} m`
}

const facilityWalkTimeText = (facility) => {
  const minutes = walkMinutes(facility)
  if (minutes === null) return '路网不可达'
  return `步行约${Math.max(1, Math.round(minutes))}分钟`
}

const isFacilitySelectable = (facility) => {
  return Boolean(facility?.routable && (!facilitySortedByWalk.value || facilityWalkDistanceValue(facility) >= 0))
}

const selectNearbyFacility = (facility) => {
  if (!isFacilitySelectable(facility)) return
  selectedFacilityId.value = String(facility.id)
  internalRoute.value = null
  internalError.value = ''
  drawInternalMap()
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

const graphCoordinate = (point) => {
  if (Array.isArray(point) && point.length === 2) {
    return { latitude: Number(point[0]), longitude: Number(point[1]) }
  }
  if (point && point.latitude !== undefined && point.longitude !== undefined) {
    return { latitude: Number(point.latitude), longitude: Number(point.longitude) }
  }
  return null
}

const edgeCoordinates = (edge) => {
  return (edge?.coordinates || [])
    .map(graphCoordinate)
    .filter(point => point && Number.isFinite(point.latitude) && Number.isFinite(point.longitude))
}

const edgeMidpoint = (edge) => {
  const coords = edgeCoordinates(edge)
  if (!coords.length) return null
  const middle = coords[Math.floor(coords.length / 2)]
  return middle || coords[0]
}

const quantile = (values, q) => {
  if (!values.length) return 0
  const sorted = [...values].sort((left, right) => left - right)
  const index = Math.min(sorted.length - 1, Math.max(0, Math.floor((sorted.length - 1) * q)))
  return sorted[index]
}

const paddedBounds = (bounds, ratio = 0.08) => {
  const latPad = Math.max((bounds.maxLat - bounds.minLat) * ratio, 0.00035)
  const lngPad = Math.max((bounds.maxLng - bounds.minLng) * ratio, 0.00035)
  return {
    minLat: bounds.minLat - latPad,
    maxLat: bounds.maxLat + latPad,
    minLng: bounds.minLng - lngPad,
    maxLng: bounds.maxLng + lngPad
  }
}

const pointInBounds = (point, bounds) => {
  if (!point) return false
  return point.latitude >= bounds.minLat &&
    point.latitude <= bounds.maxLat &&
    point.longitude >= bounds.minLng &&
    point.longitude <= bounds.maxLng
}

const sanitizeGraphLabel = (value) => {
  const text = String(value || '').trim()
  if (!text) return ''
  if (/^OSM\s+(服务设施|入口|建筑|路口)?\s*\d+/i.test(text)) return ''
  if (/^OSM\s+/i.test(text)) return text.replace(/^OSM\s+/i, '')
  return text.replace(/\s+/g, ' ').slice(0, 18)
}

const graphFacilityLabel = (facility) => {
  return sanitizeGraphLabel(facility?.name) || facility?.typeLabel || '设施'
}

const selectedGraphFacilityLabel = computed(() => {
  return selectedFacility.value ? graphFacilityLabel(selectedFacility.value) : ''
})

const selectedGraphLabelWidth = computed(() => {
  const textLength = selectedGraphFacilityLabel.value.length || 2
  return Math.min(210, Math.max(58, textLength * 15 + 28))
})

const graphMarkerColor = (facility) => {
  if (String(facility.id) === String(selectedFacilityId.value)) return '#0f766e'
  if (!facility.routable) return '#94a3b8'
  if (facility.type === 'entrance') return '#7c3aed'
  if (facility.type === 'toilet') return '#2563eb'
  if (facility.type === 'restaurant' || facility.type === 'cafe') return '#c2410c'
  if (facility.type === 'building') return '#64748b'
  return '#475569'
}

const graphFacilityRadius = (facility) => {
  if (String(facility.id) === String(selectedFacilityId.value)) return 7.4
  if (facility.type === 'entrance') return 5.8
  if (facility.type === 'building') return 3.8
  return facility.routable ? 4.8 : 3.4
}

const graphMarkerOpacity = (facility) => {
  if (String(facility.id) === String(selectedFacilityId.value)) return 0.98
  if (!facility.routable) return 0.48
  if (facility.type === 'building') return 0.7
  return 0.88
}

const realGraphEdges = computed(() => {
  return (internalMap.value.edges || []).filter(edge => edge.source !== 'generated' && edge.coordinates?.length)
})

const connectorGraphEdges = computed(() => {
  return (internalMap.value.edges || []).filter(edge => edge.source === 'generated' && edge.coordinates?.length)
})

const primaryRoadComponentEdges = computed(() => {
  const edges = realGraphEdges.value.filter(edge => edge.fromNodeId && edge.toNodeId)
  if (edges.length < 20) return []

  const nodeEdges = new Map()
  const addEdge = (nodeId, edge) => {
    const key = String(nodeId)
    if (!nodeEdges.has(key)) nodeEdges.set(key, [])
    nodeEdges.get(key).push(edge)
  }
  for (const edge of edges) {
    addEdge(edge.fromNodeId, edge)
    addEdge(edge.toNodeId, edge)
  }

  const visitedNodes = new Set()
  const components = []

  for (const startNode of nodeEdges.keys()) {
    if (visitedNodes.has(startNode)) continue
    const queue = [startNode]
    visitedNodes.add(startNode)
    const componentEdges = new Set()

    for (let index = 0; index < queue.length; index += 1) {
      const nodeId = queue[index]
      for (const edge of nodeEdges.get(nodeId) || []) {
        componentEdges.add(edge)
        const nextNode = String(edge.fromNodeId) === nodeId ? String(edge.toNodeId) : String(edge.fromNodeId)
        if (!visitedNodes.has(nextNode)) {
          visitedNodes.add(nextNode)
          queue.push(nextNode)
        }
      }
    }

    const componentList = [...componentEdges]
    const score = componentList.length + componentList.reduce((sum, edge) => sum + graphEdgeLength(edge), 0) / 180
    components.push({ edges: componentList, score })
  }

  const targetEdges = Math.min(240, Math.max(90, Math.ceil(edges.length * 0.45)))
  const selectedEdges = []
  for (const component of components.sort((left, right) => right.score - left.score)) {
    selectedEdges.push(...component.edges)
    if (selectedEdges.length >= targetEdges || selectedEdges.length >= GRAPH_FOCUS_EDGE_LIMIT) break
  }

  return selectedEdges.length >= 20 ? selectedEdges : []
})

const fullGraphBounds = computed(() => {
  const coords = []
  for (const edge of realGraphEdges.value) coords.push(...edgeCoordinates(edge))
  for (const facility of visibleFacilities.value) {
    const point = graphCoordinate(facility)
    if (point && Number.isFinite(point.latitude) && Number.isFinite(point.longitude)) coords.push(point)
  }
  for (const node of internalMap.value.nodes || []) {
    const point = graphCoordinate(node)
    if (point && Number.isFinite(point.latitude) && Number.isFinite(point.longitude)) coords.push(point)
  }
  if (!coords.length) {
    return { minLat: 0, maxLat: 1, minLng: 0, maxLng: 1 }
  }
  return paddedBounds({
    minLat: Math.min(...coords.map(point => point.latitude)),
    maxLat: Math.max(...coords.map(point => point.latitude)),
    minLng: Math.min(...coords.map(point => point.longitude)),
    maxLng: Math.max(...coords.map(point => point.longitude))
  }, 0.04)
})

const focusGraphBounds = computed(() => {
  if (primaryRoadComponentEdges.value.length) {
    const coords = primaryRoadComponentEdges.value.flatMap(edge => edgeCoordinates(edge))
    return paddedBounds({
      minLat: Math.min(...coords.map(point => point.latitude)),
      maxLat: Math.max(...coords.map(point => point.latitude)),
      minLng: Math.min(...coords.map(point => point.longitude)),
      maxLng: Math.max(...coords.map(point => point.longitude))
    }, 0.14)
  }

  const midpoints = realGraphEdges.value.map(edgeMidpoint).filter(Boolean)
  if (midpoints.length < 20) return fullGraphBounds.value
  const bounds = {
    minLat: quantile(midpoints.map(point => point.latitude), 0.08),
    maxLat: quantile(midpoints.map(point => point.latitude), 0.92),
    minLng: quantile(midpoints.map(point => point.longitude), 0.08),
    maxLng: quantile(midpoints.map(point => point.longitude), 0.92)
  }
  return paddedBounds(bounds, 0.1)
})

const graphBounds = computed(() => {
  return internalGraphScope.value === 'full' ? fullGraphBounds.value : focusGraphBounds.value
})

const graphEdgeLength = (edge) => Number(edge.distance || 0)

const displayedRoadEdges = computed(() => {
  const bounds = graphBounds.value
  const limit = internalGraphScope.value === 'full' ? GRAPH_FULL_EDGE_LIMIT : GRAPH_FOCUS_EDGE_LIMIT
  const sourceEdges = internalGraphScope.value === 'focus' && primaryRoadComponentEdges.value.length
    ? primaryRoadComponentEdges.value
    : realGraphEdges.value
  return sourceEdges
    .filter(edge => internalGraphScope.value === 'full' || pointInBounds(edgeMidpoint(edge), bounds))
    .sort((left, right) => graphEdgeLength(right) - graphEdgeLength(left))
    .slice(0, limit)
})

const displayedConnectorEdges = computed(() => {
  if (!showGraphConnectors.value) return []
  const bounds = graphBounds.value
  return connectorGraphEdges.value
    .filter(edge => pointInBounds(edgeMidpoint(edge), bounds))
    .slice(0, internalGraphScope.value === 'full' ? 800 : 260)
})

const internalGraphBounds = computed(() => {
  let { minLat, maxLat, minLng, maxLng } = graphBounds.value
  if (Math.abs(maxLat - minLat) < 0.00001) {
    minLat -= 0.0005
    maxLat += 0.0005
  }
  if (Math.abs(maxLng - minLng) < 0.00001) {
    minLng -= 0.0005
    maxLng += 0.0005
  }
  return { minLat, maxLat, minLng, maxLng }
})

const projectGraphPoint = (pointLike) => {
  const point = graphCoordinate(pointLike)
  if (!point || !Number.isFinite(point.latitude) || !Number.isFinite(point.longitude)) return null
  const bounds = internalGraphBounds.value
  const xRatio = (point.longitude - bounds.minLng) / (bounds.maxLng - bounds.minLng)
  const yRatio = (bounds.maxLat - point.latitude) / (bounds.maxLat - bounds.minLat)
  return {
    x: Number((GRAPH_PADDING + xRatio * (GRAPH_WIDTH - GRAPH_PADDING * 2)).toFixed(1)),
    y: Number((GRAPH_PADDING + yRatio * (GRAPH_HEIGHT - GRAPH_PADDING * 2)).toFixed(1))
  }
}

const graphPathForCoordinates = (coordinates) => {
  const points = (coordinates || []).map(projectGraphPoint).filter(Boolean)
  if (points.length < 2) return ''
  return points.map((point, index) => `${index === 0 ? 'M' : 'L'}${point.x} ${point.y}`).join(' ')
}

const internalGraphRoadPath = computed(() => {
  return displayedRoadEdges.value
    .map(edge => graphPathForCoordinates(edge.coordinates))
    .filter(Boolean)
    .join(' ')
})

const internalGraphConnectorPath = computed(() => {
  return displayedConnectorEdges.value
    .map(edge => graphPathForCoordinates(edge.coordinates))
    .filter(Boolean)
    .join(' ')
})

const internalGraphRoutePath = computed(() => graphPathForCoordinates(routeCoordinates()))

const internalGraphFacilities = computed(() => {
  const bounds = graphBounds.value
  return visibleFacilities.value
    .filter(facility => pointInBounds(graphCoordinate(facility), bounds))
    .sort((left, right) => {
      const selectedDelta = Number(String(right.id) === String(selectedFacilityId.value)) - Number(String(left.id) === String(selectedFacilityId.value))
      if (selectedDelta) return selectedDelta
      const routableDelta = Number(Boolean(right.routable)) - Number(Boolean(left.routable))
      if (routableDelta) return routableDelta
      return Number(left.walkDistance ?? Number.MAX_SAFE_INTEGER) - Number(right.walkDistance ?? Number.MAX_SAFE_INTEGER)
    })
    .slice(0, internalGraphScope.value === 'full' ? GRAPH_FACILITY_LIMIT * 2 : GRAPH_FACILITY_LIMIT)
    .map(facility => {
      const point = projectGraphPoint(facility)
      return point ? { facility, ...point } : null
    })
    .filter(Boolean)
})

const selectedGraphFacilityPoint = computed(() => {
  if (!selectedFacility.value) return null
  return projectGraphPoint(selectedFacility.value)
})

const selectInternalGraphFacility = (facility) => {
  if (!facility.routable) {
    internalError.value = '该设施暂不能规划步行路线'
    return
  }
  selectedFacilityId.value = String(facility.id)
  internalError.value = ''
  internalRoute.value = null
  drawInternalMap()
}

const internalGraphDisplayStats = computed(() => ({
  roadEdges: displayedRoadEdges.value.length,
  facilities: internalGraphFacilities.value.length
}))

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
      payload.startNodeId = Number(facilitySourceNode.value?.id || selectedStartNodeId.value || 0)
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

watch([selectedFacilityType, showAllFacilities, facilitySearchKeyword, selectedFacilityRange], () => {
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
  loadFacilitiesForCurrentSource()
})

watch(() => props.id, loadDetail)

onMounted(async () => {
  await nextTick()
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

.internal-graph {
  background-color: #f7fafc;
  background-image:
    linear-gradient(rgba(100, 116, 139, 0.08) 1px, transparent 1px),
    linear-gradient(90deg, rgba(100, 116, 139, 0.08) 1px, transparent 1px);
  background-size: 56px 56px;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.95),
    inset 0 0 0 1px rgba(203, 213, 225, 0.52);
}

.internal-graph::before {
  position: absolute;
  inset: 0;
  pointer-events: none;
  content: '';
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.58), rgba(241, 245, 249, 0.2)),
    linear-gradient(135deg, rgba(20, 184, 166, 0.06), transparent 42%);
}

.internal-graph > svg {
  position: relative;
  z-index: 1;
}

.internal-graph > .absolute {
  z-index: 2;
}
</style>
