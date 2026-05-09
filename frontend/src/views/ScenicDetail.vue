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
          </div>
        </div>
      </div>
    </section>

    <section class="grid gap-6 lg:grid-cols-[0.75fr_1.25fr]">
      <div class="rounded-md border border-slate-200 bg-white p-5">
        <h2 class="text-lg font-semibold">位置信息</h2>
        <div class="mt-3 text-sm leading-7 text-slate-600">
          <div>城市：{{ spot.district || '北京' }}</div>
          <div>地址：{{ spot.address || '暂无详细地址' }}</div>
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
          暂无评价，之后可以在这里接入用户评价发布功能。
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { onMounted, ref, watch } from 'vue'
import { scenicSpots as fallbackSpots } from '@/data/demoData'
import { tourismApi } from '@/services/tourismApi'
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
}

watch(() => props.id, loadDetail)
onMounted(loadDetail)
</script>
