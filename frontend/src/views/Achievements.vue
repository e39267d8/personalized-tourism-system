<template>
  <div class="space-y-6">
    <section class="rounded-md border border-slate-200 bg-white p-5">
      <div class="grid gap-6 lg:grid-cols-[1fr_0.8fr]">
        <div>
          <div class="inline-flex rounded-md bg-amber-50 px-3 py-1 text-sm font-semibold text-amber-800">成长体系</div>
          <h1 class="mt-4 text-3xl font-bold tracking-tight text-slate-950">成就系统与数字纪念章</h1>
          <p class="mt-3 max-w-2xl text-sm leading-7 text-slate-600">
            把路线完成、游记发布、预算控制和景点评价转化为可展示的徽章，增强用户留存，也适合课程展示“旅游后”场景。
          </p>
        </div>
        <div class="grid grid-cols-3 gap-3">
          <div class="rounded-md bg-slate-50 p-4 text-center">
            <div class="text-2xl font-bold text-slate-950">4</div>
            <div class="mt-1 text-xs text-slate-500">徽章规则</div>
          </div>
          <div class="rounded-md bg-slate-50 p-4 text-center">
            <div class="text-2xl font-bold text-slate-950">2</div>
            <div class="mt-1 text-xs text-slate-500">已解锁</div>
          </div>
          <div class="rounded-md bg-slate-50 p-4 text-center">
            <div class="text-2xl font-bold text-slate-950">120</div>
            <div class="mt-1 text-xs text-slate-500">积分</div>
          </div>
        </div>
      </div>
    </section>

    <section class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
      <article v-for="achievement in achievementList" :key="achievement.id" class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-start justify-between gap-3">
          <div class="grid h-12 w-12 place-items-center rounded-md bg-slate-900 text-sm font-bold text-white">{{ achievement.level }}</div>
          <span
            :class="[
              'rounded-md px-2 py-1 text-xs font-semibold',
              achievement.progress === 100 ? 'bg-teal-50 text-teal-800' : achievement.progress > 0 ? 'bg-amber-50 text-amber-800' : 'bg-slate-100 text-slate-500'
            ]"
          >
            {{ achievement.status }}
          </span>
        </div>
        <h2 class="mt-4 text-lg font-bold text-slate-950">{{ achievement.name }}</h2>
        <p class="mt-2 min-h-12 text-sm leading-6 text-slate-500">{{ achievement.description }}</p>
        <div class="mt-4">
          <div class="flex justify-between text-xs font-medium text-slate-500">
            <span>进度</span>
            <span>{{ achievement.progress }}%</span>
          </div>
          <div class="mt-2 h-2 rounded-full bg-slate-100">
            <div class="h-2 rounded-full bg-teal-700" :style="{ width: `${achievement.progress}%` }"></div>
          </div>
        </div>
      </article>
    </section>

    <section class="grid gap-6 xl:grid-cols-[0.9fr_1.1fr]">
      <div class="rounded-md border border-slate-200 bg-white p-5">
        <h2 class="text-lg font-semibold text-slate-950">解锁规则设计</h2>
        <div class="mt-4 space-y-3">
          <div v-for="rule in rules" :key="rule.title" class="rounded-md bg-slate-50 p-4">
            <div class="font-semibold text-slate-950">{{ rule.title }}</div>
            <p class="mt-1 text-sm leading-6 text-slate-500">{{ rule.copy }}</p>
          </div>
        </div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-center justify-between">
          <div>
            <h2 class="text-lg font-semibold text-slate-950">数字纪念章</h2>
            <p class="mt-1 text-sm text-slate-500">先做展示，后续可接真实链上或本地证书。</p>
          </div>
          <button class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">生成证书</button>
        </div>

        <div class="mt-5 grid gap-4 md:grid-cols-2">
          <article v-for="collectible in collectibles" :key="collectible.token" class="rounded-md border border-slate-200 p-4">
            <div class="aspect-square rounded-md bg-gradient-to-br from-slate-900 via-teal-800 to-amber-600 p-5 text-white">
              <div class="text-xs uppercase tracking-[0.18em] opacity-80">Travel Badge</div>
              <div class="mt-8 text-2xl font-bold">{{ collectible.name }}</div>
              <div class="mt-2 text-sm opacity-80">{{ collectible.token }}</div>
            </div>
            <p class="mt-3 text-sm leading-6 text-slate-500">{{ collectible.copy }}</p>
          </article>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { achievements } from '@/data/demoData'
import { tourismApi } from '@/services/tourismApi'

const achievementList = ref(achievements)

const rules = [
  { title: '路线完成', copy: '用户完成指定景点序列后解锁，例如前门、天安门、故宫、景山。' },
  { title: '预算控制', copy: '实际支出低于系统预算时增加预算规划师进度。' },
  { title: '内容贡献', copy: '发布游记、评价、上传图片都可以转化为成长值。' },
  { title: '主题探索', copy: '历史、博物馆、citywalk、摄影等主题可以分别设计徽章。' }
]

const collectibles = [
  {
    name: '中轴线纪念章',
    token: 'DEMO-AXIS-001',
    copy: '完成北京中轴线演示路线后获得，用于展示旅游后的沉淀体验。'
  },
  {
    name: '老城漫步纪念章',
    token: 'DEMO-WALK-001',
    copy: '完成鼓楼到北海 citywalk 并发布游记后获得。'
  }
]

onMounted(async () => {
  try {
    const response = await tourismApi.achievements()
    achievementList.value = response.items?.length ? response.items : achievements
  } catch (error) {
    achievementList.value = achievements
  }
})
</script>
