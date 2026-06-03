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
        <span class="rounded-md bg-teal-50 px-3 py-2 text-sm font-semibold text-teal-800">
          个人旅行档案
        </span>
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

    <section class="rounded-md border border-slate-200 bg-white p-6">
      <div class="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 class="text-xl font-bold text-slate-950">账号安全</h2>
          <p class="mt-2 text-sm leading-6 text-slate-500">登录后可修改密码。忘记密码需要后续接入邮件或验证码服务。</p>
        </div>
        <div v-if="passwordMessage" class="rounded-md px-3 py-2 text-sm font-semibold" :class="passwordMessageType === 'error' ? 'bg-rose-50 text-rose-700' : 'bg-teal-50 text-teal-800'">
          {{ passwordMessage }}
        </div>
      </div>

      <form class="mt-5 grid gap-4 lg:grid-cols-[1fr_1fr_auto]" @submit.prevent="submitPasswordChange">
        <input
          v-model="passwordForm.oldPassword"
          autocomplete="current-password"
          class="h-11 rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
          placeholder="原密码"
          type="password"
        >
        <input
          v-model="passwordForm.newPassword"
          autocomplete="new-password"
          class="h-11 rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
          placeholder="新密码，至少 8 位"
          type="password"
        >
        <button class="h-11 rounded-md bg-slate-900 px-5 text-sm font-semibold text-white hover:bg-slate-800">
          修改密码
        </button>
      </form>
    </section>

    <section class="rounded-md border border-slate-200 bg-white p-6">
      <div class="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 class="text-xl font-bold text-slate-950">我的旅游偏好问卷</h2>
          <p class="mt-2 text-sm leading-6 text-slate-500">
            保存后首页会根据你的偏好标签、预算和人流选择生成个性化推荐。
          </p>
        </div>
        <div v-if="saveMessage" class="rounded-md bg-teal-50 px-3 py-2 text-sm font-semibold text-teal-800">
          {{ saveMessage }}
        </div>
      </div>

      <form class="mt-6 space-y-6" @submit.prevent="savePreferences">
        <div>
          <label class="text-sm font-semibold text-slate-700">喜欢的景点类型</label>
          <div class="mt-3 flex flex-wrap gap-2">
            <button
              v-for="option in categoryOptions"
              :key="option"
              type="button"
              class="rounded-md border px-3 py-2 text-sm font-medium transition"
              :class="toggleClass(form.preferredCategories.includes(option))"
              @click="toggleArray(form.preferredCategories, option)"
            >
              {{ option }}
            </button>
          </div>
        </div>

        <div>
          <label class="text-sm font-semibold text-slate-700">偏好标签</label>
          <div class="mt-3 flex flex-wrap gap-2">
            <button
              v-for="option in tagOptions"
              :key="option"
              type="button"
              class="rounded-md border px-3 py-2 text-sm font-medium transition"
              :class="toggleClass(form.preferredTags.includes(option))"
              @click="toggleArray(form.preferredTags, option)"
            >
              {{ option }}
            </button>
          </div>
        </div>

        <div class="grid gap-5 lg:grid-cols-3">
          <div>
            <label class="text-sm font-semibold text-slate-700">预算偏好</label>
            <select v-model="form.budgetLevel" class="mt-2 h-11 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700">
              <option value="low">低预算</option>
              <option value="medium">中等预算</option>
              <option value="high">高预算</option>
            </select>
          </div>

          <div>
            <label class="text-sm font-semibold text-slate-700">人流偏好</label>
            <select v-model="form.crowdPreference" class="mt-2 h-11 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700">
              <option value="avoid_crowded">尽量避开拥挤</option>
              <option value="popular">偏好热门景点</option>
              <option value="any">都可以</option>
            </select>
          </div>

          <div>
            <label class="text-sm font-semibold text-slate-700">游玩强度</label>
            <select v-model="form.intensity" class="mt-2 h-11 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700">
              <option value="light">轻松</option>
              <option value="medium">适中</option>
              <option value="high">充实</option>
            </select>
          </div>
        </div>

        <div class="flex flex-wrap gap-3 border-t border-slate-100 pt-5">
          <button class="rounded-md bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white hover:bg-slate-800">
            保存偏好
          </button>
          <button
            type="button"
            class="rounded-md border border-slate-300 px-5 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-100"
            @click="clearPreferences"
          >
            清除偏好
          </button>
          <router-link to="/" class="rounded-md border border-teal-700 px-5 py-2.5 text-sm font-semibold text-teal-800 hover:bg-teal-50">
            查看首页推荐
          </router-link>
        </div>
      </form>
    </section>

    <section class="grid gap-6 lg:grid-cols-2">
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
import { computed, onMounted, reactive, ref } from 'vue'
import { achievements as fallbackAchievements, diaries as fallbackDiaries } from '@/data/demoData'
import { tourismApi } from '@/services/tourismApi'
import { changePassword } from '@/stores/auth'
import {
  clearStoredProfile,
  readStoredProfile,
  writeStoredProfile
} from '@/utils/recommendation'

const categoryOptions = ['历史古迹', '博物馆', '自然公园', '城市地标', '商业街区', '美食街区', '摄影打卡', '亲子休闲', '城市漫步']
const tagOptions = ['历史', '展览', '自然', '摄影', '美食', '低预算', '夜游', '轻徒步', '胡同', '购物']

const defaultForm = () => ({
  preferredCategories: [],
  preferredTags: [],
  budgetLevel: 'medium',
  crowdPreference: 'any',
  intensity: 'medium'
})

const profile = ref({
  nickname: '旅行用户',
  email: 'traveler@example.com',
  stats: { diaries: 0, achievements: 0, favorites: 0 }
})
const form = reactive(defaultForm())
const diaries = ref(fallbackDiaries)
const achievements = ref(fallbackAchievements)
const saveMessage = ref('')
const passwordForm = reactive({
  oldPassword: '',
  newPassword: ''
})
const passwordMessage = ref('')
const passwordMessageType = ref('success')

const initials = computed(() => (profile.value.nickname || profile.value.username || 'TP').slice(0, 2).toUpperCase())

const toggleClass = (active) => active
  ? 'border-slate-900 bg-slate-900 text-white'
  : 'border-slate-300 bg-white text-slate-600 hover:bg-slate-100'

const toggleArray = (target, value) => {
  const index = target.indexOf(value)
  if (index >= 0) target.splice(index, 1)
  else target.push(value)
}

const applyPreferences = (saved) => {
  Object.assign(form, defaultForm(), saved || {})
}

const applySavedPreferences = () => {
  const saved = readStoredProfile()
  if (saved) applyPreferences(saved)
}

const preferencePayload = () => ({
  preferredCategories: [...form.preferredCategories],
  preferredTags: [...form.preferredTags],
  budgetLevel: form.budgetLevel,
  crowdPreference: form.crowdPreference,
  intensity: form.intensity
})

const savePreferences = async () => {
  const payload = preferencePayload()
  writeStoredProfile(payload)
  try {
    await tourismApi.saveProfilePreferences(payload)
    saveMessage.value = '偏好已保存，首页推荐将根据你的选择更新'
  } catch (error) {
    saveMessage.value = '偏好已保存，首页推荐将根据你的选择更新'
  }
  window.setTimeout(() => {
    saveMessage.value = ''
  }, 2800)
}

const clearPreferences = async () => {
  clearStoredProfile()
  applyPreferences(defaultForm())
  try {
    await tourismApi.deleteProfilePreferences()
    saveMessage.value = '偏好已清除，首页将显示默认推荐'
  } catch (error) {
    saveMessage.value = '偏好已清除，首页将显示默认推荐'
  }
}

const submitPasswordChange = async () => {
  passwordMessage.value = ''
  if (!passwordForm.oldPassword || !passwordForm.newPassword) {
    passwordMessageType.value = 'error'
    passwordMessage.value = '请输入原密码和新密码'
    return
  }
  try {
    await changePassword({
      oldPassword: passwordForm.oldPassword,
      newPassword: passwordForm.newPassword
    })
    passwordForm.oldPassword = ''
    passwordForm.newPassword = ''
    passwordMessageType.value = 'success'
    passwordMessage.value = '密码已修改'
  } catch (error) {
    passwordMessageType.value = 'error'
    passwordMessage.value = error.response?.data?.message || '修改失败，请稍后重试'
  }
}

onMounted(async () => {
  applySavedPreferences()
  try {
    const [profileData, preferenceData, diaryData, achievementData] = await Promise.all([
      tourismApi.profile(),
      tourismApi.getProfilePreferences(),
      tourismApi.diaries(),
      tourismApi.achievements()
    ])
    profile.value = {
      ...profileData,
      stats: profileData.stats || { diaries: 0, achievements: 0, favorites: 0 }
    }
    if (preferenceData.exists && preferenceData.profile) {
      applyPreferences(preferenceData.profile)
      writeStoredProfile(preferenceData.profile)
    }
    diaries.value = diaryData.items?.length ? diaryData.items : fallbackDiaries
    achievements.value = achievementData.items?.length ? achievementData.items : fallbackAchievements
  } catch (error) {
    diaries.value = fallbackDiaries
    achievements.value = fallbackAchievements
  }
})
</script>
