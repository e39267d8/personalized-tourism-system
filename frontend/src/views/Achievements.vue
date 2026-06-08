<template>
  <div class="space-y-6">
    <section class="rounded-md border border-slate-200 bg-white p-5">
      <div class="grid gap-6 lg:grid-cols-[1fr_0.72fr]">
        <div>
          <div class="inline-flex rounded-md bg-teal-50 px-3 py-1 text-sm font-semibold text-teal-800">旅行护照</div>
          <h1 class="mt-4 text-3xl font-bold tracking-tight text-slate-950">成就系统与数字纪念凭证</h1>
          <p class="mt-3 max-w-3xl text-sm leading-7 text-slate-600">
            在景点详情页收集旅行印章，完成城市主题、旅行日记和大师评审，解锁可收藏、可分享的数字纪念凭证。
          </p>
          <div v-if="!overview.authenticated" class="mt-4 rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
            当前展示的是示例护照。登录后可以保存打卡进度、领取数字纪念凭证并申请实体徽章。
          </div>
          <div v-if="feedback" class="mt-4 rounded-md border px-3 py-2 text-sm" :class="feedbackType === 'error' ? 'border-rose-200 bg-rose-50 text-rose-800' : 'border-teal-200 bg-teal-50 text-teal-800'">
            {{ feedback }}
          </div>
        </div>

        <div class="grid grid-cols-3 gap-3">
          <div class="rounded-md bg-slate-50 p-4 text-center">
            <div class="text-2xl font-bold text-slate-950">{{ overview.total || achievementList.length }}</div>
            <div class="mt-1 text-xs text-slate-500">护照任务</div>
          </div>
          <div class="rounded-md bg-slate-50 p-4 text-center">
            <div class="text-2xl font-bold text-teal-700">{{ overview.unlocked || 0 }}</div>
            <div class="mt-1 text-xs text-slate-500">已解锁</div>
          </div>
          <div class="rounded-md bg-slate-50 p-4 text-center">
            <div class="text-2xl font-bold text-amber-700">{{ overview.collectibleCount || collectibles.length }}</div>
            <div class="mt-1 text-xs text-slate-500">数字凭证</div>
          </div>
        </div>
      </div>
    </section>

    <section class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
      <article v-for="tier in tiers" :key="tier.value" class="rounded-md border border-slate-200 bg-white p-4">
        <div class="flex items-center justify-between">
          <div class="text-sm font-semibold text-slate-500">第 {{ tier.value }} 层</div>
          <span class="rounded-md bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-600">{{ tier.items.length }} 项</span>
        </div>
        <h2 class="mt-3 text-lg font-bold text-slate-950">{{ tier.label }}</h2>
        <p class="mt-2 min-h-12 text-sm leading-6 text-slate-500">{{ tier.copy }}</p>
        <div class="mt-3 h-2 rounded-full bg-slate-100">
          <div class="h-2 rounded-full bg-teal-700" :style="{ width: `${tier.percent}%` }"></div>
        </div>
        <div class="mt-2 text-xs text-slate-500">{{ tier.unlocked }}/{{ tier.items.length }} 已完成</div>
      </article>
    </section>

    <section class="grid gap-6 xl:grid-cols-[1fr_0.82fr]">
      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-semibold text-slate-950">护照任务</h2>
          <button class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100" @click="loadAll">
            刷新进度
          </button>
        </div>

        <article v-for="achievement in achievementList" :key="achievement.id" class="rounded-md border border-slate-200 bg-white p-5">
          <div class="flex flex-wrap items-start justify-between gap-3">
            <div>
              <div class="text-xs font-semibold text-slate-500">{{ achievement.tierLabel }}</div>
              <h3 class="mt-1 text-lg font-bold text-slate-950">{{ achievement.name }}</h3>
              <p class="mt-2 text-sm leading-6 text-slate-500">{{ achievement.description }}</p>
            </div>
            <span
              :class="[
                'rounded-md px-2.5 py-1 text-xs font-semibold',
                achievement.status === 'unlocked' ? 'bg-teal-50 text-teal-800' : achievement.status === 'in_progress' ? 'bg-amber-50 text-amber-800' : 'bg-slate-100 text-slate-500'
              ]"
            >
              {{ achievement.statusLabel }}
            </span>
          </div>

          <div class="mt-4">
            <div class="flex justify-between text-xs font-medium text-slate-500">
              <span>{{ achievement.progress?.label || '等待收集印章' }}</span>
              <span>{{ achievement.progressPercent || 0 }}%</span>
            </div>
            <div class="mt-2 h-2 rounded-full bg-slate-100">
              <div class="h-2 rounded-full bg-teal-700" :style="{ width: `${achievement.progressPercent || 0}%` }"></div>
            </div>
          </div>

          <div v-if="achievement.requiredSpots?.length" class="mt-4 flex flex-wrap gap-2">
            <span
              v-for="spot in achievement.requiredSpots"
              :key="`${achievement.id}-${spot}`"
              class="rounded-md px-2.5 py-1 text-xs font-semibold"
              :class="achievement.checkedSpots?.includes(spot) ? 'bg-teal-50 text-teal-800' : 'bg-slate-100 text-slate-500'"
            >
              {{ spot }}
            </span>
          </div>

          <div class="mt-4 rounded-md bg-slate-50 px-3 py-2 text-sm text-slate-700">
            {{ achievement.nextAction || '继续探索，收集下一枚旅行印章' }}
          </div>

          <div class="mt-4 flex flex-wrap gap-2">
            <button
              class="rounded-md bg-slate-900 px-3 py-2 text-sm font-semibold text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:bg-slate-400"
              :disabled="achievement.status !== 'unlocked' || claimingId === achievement.id || achievement.collectibleId"
              @click="claimAchievement(achievement)"
            >
              {{ achievement.collectibleId ? '已领取数字凭证' : claimingId === achievement.id ? '领取中...' : '领取数字凭证' }}
            </button>
            <router-link
              v-if="achievement.collectibleId"
              :to="`/collectibles/${achievement.collectibleId}`"
              class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100"
            >
              查看证书
            </router-link>
            <button
              v-if="achievement.hasPhysicalBadge"
              class="rounded-md border border-amber-300 px-3 py-2 text-sm font-semibold text-amber-800 hover:bg-amber-50 disabled:cursor-not-allowed disabled:opacity-50"
              :disabled="achievement.status !== 'unlocked'"
              @click="openRedemption(achievement)"
            >
              {{ achievement.redemptionStatus ? `兑换状态：${achievement.redemptionStatusLabel}` : '申请实体徽章' }}
            </button>
          </div>
        </article>
      </div>

      <aside class="space-y-6">
        <section class="rounded-md border border-slate-200 bg-white p-5">
          <h2 class="text-lg font-semibold text-slate-950">数字纪念凭证墙</h2>
          <p class="mt-1 text-sm text-slate-500">模拟链上编号，可进入证书页生成分享卡。</p>

          <div v-if="collectibles.length" class="mt-4 space-y-3">
            <router-link
              v-for="item in collectibles"
              :key="item.id"
              :to="`/collectibles/${item.id}`"
              class="block rounded-md border border-slate-200 p-4 text-left hover:border-teal-500 hover:bg-teal-50/40"
            >
              <div class="text-xs font-semibold text-slate-500">{{ item.tierLabel }}</div>
              <div class="mt-1 font-bold text-slate-950">{{ item.name }}</div>
              <div class="mt-2 break-all text-xs text-slate-500">{{ item.tokenId }}</div>
            </router-link>
          </div>
          <div v-else class="mt-4 rounded-md border border-dashed border-slate-300 p-5 text-sm leading-6 text-slate-500">
            还没有数字纪念凭证。完成打卡或主题集章后，在左侧领取第一张证书。
          </div>
        </section>

        <section class="rounded-md border border-slate-200 bg-white p-5">
          <h2 class="text-lg font-semibold text-slate-950">我的实体徽章申请</h2>
          <div v-if="redemptionHistory.length" class="mt-4 space-y-3">
            <div v-for="item in redemptionHistory" :key="item.id" class="rounded-md border border-slate-200 p-3">
              <div class="flex items-center justify-between gap-3">
                <div class="font-semibold text-slate-950">{{ item.achievementName }}</div>
                <span class="rounded-md bg-amber-50 px-2 py-1 text-xs font-semibold text-amber-800">{{ item.statusLabel }}</span>
              </div>
              <div class="mt-2 text-xs leading-5 text-slate-500">
                {{ item.recipientName }} / {{ item.phone }}<br>
                {{ item.address }}
              </div>
            </div>
          </div>
          <div v-else class="mt-4 rounded-md border border-dashed border-slate-300 p-4 text-sm text-slate-500">
            解锁第 2 层以上成就后，可以提交实体徽章兑换申请。
          </div>
        </section>

        <section v-if="redeemingAchievement" class="rounded-md border border-amber-200 bg-white p-5">
          <h2 class="text-lg font-semibold text-slate-950">实体徽章兑换</h2>
          <p class="mt-1 text-sm text-slate-500">当前申请：{{ redeemingAchievement.name }}</p>
          <div class="mt-4 space-y-3">
            <input v-model="redemptionForm.recipientName" class="h-10 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700" placeholder="收件人">
            <input v-model="redemptionForm.phone" class="h-10 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700" placeholder="联系电话">
            <textarea v-model="redemptionForm.address" class="min-h-20 w-full rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-teal-700" placeholder="收件地址"></textarea>
            <textarea v-model="redemptionForm.note" class="min-h-16 w-full rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-teal-700" placeholder="备注，可不填"></textarea>
            <div class="flex gap-2">
              <button class="flex-1 rounded-md bg-amber-600 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-700 disabled:bg-slate-400" :disabled="redeeming" @click="submitRedemption">
                {{ redeeming ? '提交中...' : '提交兑换申请' }}
              </button>
              <button class="rounded-md border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100" @click="redeemingAchievement = null">
                取消
              </button>
            </div>
          </div>
        </section>

        <section v-if="isReviewer" class="rounded-md border border-slate-200 bg-white p-5">
          <div class="flex items-center justify-between gap-3">
            <h2 class="text-lg font-semibold text-slate-950">大师评审队列</h2>
            <button class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100" @click="loadReviewQueue">
              刷新
            </button>
          </div>
          <div v-if="reviewQueue.length" class="mt-4 space-y-3">
            <div v-for="item in reviewQueue" :key="item.id" class="rounded-md border border-slate-200 p-3">
              <div class="font-semibold text-slate-950">{{ item.diaryTitle }}</div>
              <div class="mt-1 text-xs text-slate-500">
                {{ item.nickname || item.username }} / {{ item.contentLength }} 字 / {{ item.imageCount }} 图 / {{ item.spotCount }} 景点
              </div>
              <div class="mt-2 text-xs font-semibold text-amber-700">{{ item.statusLabel }}</div>
              <div v-if="item.status === 'pending'" class="mt-3 flex gap-2">
                <button class="rounded-md bg-teal-700 px-3 py-1.5 text-xs font-semibold text-white hover:bg-teal-800" @click="decideReview(item, 'approved')">
                  通过
                </button>
                <button class="rounded-md border border-rose-300 px-3 py-1.5 text-xs font-semibold text-rose-700 hover:bg-rose-50" @click="decideReview(item, 'rejected')">
                  驳回
                </button>
              </div>
            </div>
          </div>
          <div v-else class="mt-4 rounded-md border border-dashed border-slate-300 p-4 text-sm text-slate-500">
            暂无待处理评审。
          </div>
        </section>
      </aside>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { tourismApi } from '@/services/tourismApi'
import { authStore } from '@/stores/auth'

const fallbackAchievements = [
  {
    id: 1,
    name: '北京旅行第一章',
    description: '完成任意一个景点打卡，开启你的 TourPilot 旅行护照。',
    tier: 1,
    tierLabel: '基础打卡',
    status: 'locked',
    statusLabel: '未解锁',
    progressPercent: 0,
    progress: { label: '登录后开始收集旅行印章' },
    nextAction: '去任意景点详情页收集第一枚旅行印章',
    hasPhysicalBadge: false
  },
  {
    id: 3,
    name: '中轴线集章者',
    description: '集齐前门、天安门、故宫、景山，完成北京中轴线主题探索。',
    tier: 2,
    tierLabel: '主题集章',
    status: 'locked',
    statusLabel: '未解锁',
    progressPercent: 0,
    progress: { label: '已收集 0/4 枚主题印章' },
    requiredSpots: ['前门', '天安门', '故宫', '景山'],
    checkedSpots: [],
    missingSpots: ['前门', '天安门', '故宫', '景山'],
    nextAction: '下一枚建议去：前门',
    hasPhysicalBadge: true
  },
  {
    id: 9,
    name: '旅行记忆创作者',
    description: '发布包含景点、图片和完整体验记录的旅行日记。',
    tier: 3,
    tierLabel: '旅行日记',
    status: 'locked',
    statusLabel: '未解锁',
    progressPercent: 0,
    progress: { label: '合格旅行日记 0 篇' },
    nextAction: '发布一篇含景点、图片且超过 120 字的旅行日记',
    hasPhysicalBadge: false
  },
  {
    id: 10,
    name: '大师级旅行记录者',
    description: '优质旅行日记通过人工评审，获得最高级纪念奖励。',
    tier: 4,
    tierLabel: '大师评审',
    status: 'locked',
    statusLabel: '未解锁',
    progressPercent: 0,
    progress: { label: '大师评审通过 0 篇' },
    nextAction: '将优质公开游记提交人工评审',
    hasPhysicalBadge: true
  }
]

const tierCopies = {
  1: '到达或演示打卡即可解锁，给游客即时反馈。',
  2: '围绕城市主题集齐多枚印章，形成探索路线。',
  3: '用图片和文字沉淀旅行记忆，获得创作者身份。',
  4: '优质游记进入人工评审，解锁最高级奖励。'
}

const overview = ref({ authenticated: false, total: 0, unlocked: 0, collectibleCount: 0 })
const achievementList = ref(fallbackAchievements)
const collectibles = ref([])
const redemptionHistory = ref([])
const reviewQueue = ref([])
const feedback = ref('')
const feedbackType = ref('success')
const claimingId = ref(0)
const redeemingAchievement = ref(null)
const redeeming = ref(false)
const redemptionForm = ref({
  recipientName: '',
  phone: '',
  address: '',
  note: ''
})

const isReviewer = computed(() => authStore.user?.username === 'demo_user')

const tiers = computed(() => {
  return [1, 2, 3, 4].map(value => {
    const items = achievementList.value.filter(item => Number(item.tier) === value)
    const unlocked = items.filter(item => item.status === 'unlocked').length
    return {
      value,
      label: items[0]?.tierLabel || `第 ${value} 层`,
      copy: tierCopies[value],
      items,
      unlocked,
      percent: items.length ? Math.round(unlocked / items.length * 100) : 0
    }
  })
})

function showFeedback(message, type = 'success') {
  feedback.value = message
  feedbackType.value = type
}

async function loadAchievements() {
  try {
    const data = await tourismApi.achievements()
    overview.value = data
    achievementList.value = data.items?.length ? data.items : fallbackAchievements
    collectibles.value = data.collectibles || []
    redemptionHistory.value = data.redemptionHistory || []
  } catch (error) {
    achievementList.value = fallbackAchievements
    collectibles.value = []
    redemptionHistory.value = []
    showFeedback(error.response?.data?.message || '成就数据暂时不可用，已展示示例护照。', 'error')
  }
}

async function loadReviewQueue() {
  if (!isReviewer.value) return
  try {
    const data = await tourismApi.achievementReviewSubmissions({ status: 'pending' })
    reviewQueue.value = data.items || []
  } catch {
    reviewQueue.value = []
  }
}

async function loadAll() {
  await loadAchievements()
  await loadReviewQueue()
}

async function claimAchievement(achievement) {
  claimingId.value = achievement.id
  try {
    await tourismApi.claimAchievement(achievement.id)
    showFeedback(`已领取「${achievement.name}」数字纪念凭证。`)
    await loadAchievements()
  } catch (error) {
    showFeedback(error.response?.data?.message || '领取失败，请稍后再试。', 'error')
  } finally {
    claimingId.value = 0
  }
}

function openRedemption(achievement) {
  redeemingAchievement.value = achievement
  redemptionForm.value = {
    recipientName: '',
    phone: '',
    address: '',
    note: ''
  }
}

async function submitRedemption() {
  if (!redeemingAchievement.value) return
  if (!redemptionForm.value.recipientName.trim() || !redemptionForm.value.phone.trim() || !redemptionForm.value.address.trim()) {
    showFeedback('请填写收件人、电话和地址。', 'error')
    return
  }

  redeeming.value = true
  try {
    const result = await tourismApi.redeemBadge({
      achievementId: redeemingAchievement.value.id,
      ...redemptionForm.value
    })
    showFeedback(`实体徽章申请已提交，当前状态：${result.statusLabel || '待处理'}。`)
    redeemingAchievement.value = null
    redemptionForm.value = { recipientName: '', phone: '', address: '', note: '' }
    await loadAchievements()
  } catch (error) {
    showFeedback(error.response?.data?.message || '提交兑换申请失败。', 'error')
  } finally {
    redeeming.value = false
  }
}

async function decideReview(item, status) {
  try {
    await tourismApi.decideAchievementReview(item.id, {
      status,
      reviewNote: status === 'approved' ? '内容完整，符合大师级旅行记录标准。' : '暂未达到大师级旅行记录标准，可补充细节后再提交。'
    })
    showFeedback(status === 'approved' ? '评审已通过，用户大师级成就已重新计算。' : '评审已驳回。')
    await loadAll()
  } catch (error) {
    showFeedback(error.response?.data?.message || '评审操作失败。', 'error')
  }
}

onMounted(loadAll)
</script>
