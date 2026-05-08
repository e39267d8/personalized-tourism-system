<template>
  <div class="space-y-6">
    <section class="rounded-md border border-slate-200 bg-white p-6">
      <div class="flex flex-wrap items-center justify-between gap-5">
        <div class="flex items-center gap-4">
          <div class="grid h-16 w-16 place-items-center rounded-md bg-slate-900 text-xl font-bold text-white">
            {{ initials }}
          </div>
          <div>
            <h1 class="text-2xl font-bold">{{ profile.nickname }}</h1>
            <p class="mt-1 text-sm text-slate-500">{{ profile.email }}</p>
          </div>
        </div>
        <button class="rounded-md bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800">
          编辑资料
        </button>
      </div>

      <div class="mt-6 grid gap-4 sm:grid-cols-3">
        <div class="rounded-md bg-slate-50 p-4">
          <div class="text-sm text-slate-500">旅行日记</div>
          <div class="mt-2 text-3xl font-bold">{{ profile.stats.diaries }}</div>
        </div>
        <div class="rounded-md bg-slate-50 p-4">
          <div class="text-sm text-slate-500">已解锁成就</div>
          <div class="mt-2 text-3xl font-bold">{{ profile.stats.achievements }}</div>
        </div>
        <div class="rounded-md bg-slate-50 p-4">
          <div class="text-sm text-slate-500">收藏景点</div>
          <div class="mt-2 text-3xl font-bold">{{ profile.stats.favorites }}</div>
        </div>
      </div>
    </section>

    <section class="grid gap-6 lg:grid-cols-[1fr_1fr]">
      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-semibold">最近日记</h2>
          <router-link to="/diary" class="text-sm font-semibold text-teal-700 hover:text-teal-900">管理日记</router-link>
        </div>
        <div class="mt-4 space-y-3">
          <article v-for="diary in diaries.slice(0, 3)" :key="diary.id" class="rounded-md border border-slate-200 p-4">
            <div class="font-semibold">{{ diary.title }}</div>
            <p class="mt-2 line-clamp-2 text-sm leading-6 text-slate-500">{{ diary.excerpt }}</p>
            <div class="mt-3 text-xs text-slate-400">{{ diary.date }} · {{ diary.distance }}</div>
          </article>
        </div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-semibold">我的成就</h2>
          <router-link to="/achievements" class="text-sm font-semibold text-teal-700 hover:text-teal-900">查看全部</router-link>
        </div>
        <div class="mt-4 space-y-3">
          <article v-for="item in achievements.slice(0, 3)" :key="item.id" class="rounded-md border border-slate-200 p-4">
            <div class="flex items-center justify-between gap-3">
              <div>
                <div class="font-semibold">{{ item.name }}</div>
                <div class="mt-1 text-sm text-slate-500">{{ item.status }}</div>
              </div>
              <div class="text-sm font-bold text-teal-700">{{ item.progress }}%</div>
            </div>
            <div class="mt-3 h-2 overflow-hidden rounded-full bg-slate-100">
              <div class="h-full rounded-full bg-teal-700" :style="{ width: `${item.progress}%` }"></div>
            </div>
          </article>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { achievements as fallbackAchievements, diaries as fallbackDiaries } from '@/data/demoData'
import { tourismApi } from '@/services/tourismApi'

const profile = ref({
  nickname: '旅行用户',
  email: 'traveler@example.com',
  stats: { diaries: 0, achievements: 0, favorites: 0 }
})
const diaries = ref(fallbackDiaries)
const achievements = ref(fallbackAchievements)

const initials = computed(() => (profile.value.nickname || profile.value.username || 'TP').slice(0, 2).toUpperCase())

onMounted(async () => {
  try {
    const [profileData, diaryData, achievementData] = await Promise.all([
      tourismApi.profile(),
      tourismApi.diaries(),
      tourismApi.achievements()
    ])
    profile.value = {
      ...profileData,
      stats: profileData.stats || { diaries: 0, achievements: 0, favorites: 0 }
    }
    diaries.value = diaryData.items?.length ? diaryData.items : fallbackDiaries
    achievements.value = achievementData.items?.length ? achievementData.items : fallbackAchievements
  } catch (error) {
    diaries.value = fallbackDiaries
    achievements.value = fallbackAchievements
  }
})
</script>
