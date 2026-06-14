<template>
  <div class="space-y-6">
    <section class="rounded-md border border-slate-200 bg-white p-4">
      <div class="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 class="text-lg font-semibold text-slate-950">成就进阶路线</h2>
          <p class="mt-1 text-sm text-slate-500">先收集基础印章，再推进主题、游记和评审成就。</p>
        </div>
      </div>

      <div class="achievement-river mt-3">
        <div class="achievement-river__content">
          <svg class="achievement-river__path" viewBox="0 0 1000 220" preserveAspectRatio="none" aria-hidden="true">
            <path
              class="achievement-river__path-shadow"
              d="M 44 148 C 116 105 196 88 282 88 C 374 88 440 42 534 82 C 608 112 647 170 740 158 C 824 146 844 88 908 68 C 944 56 958 72 982 36"
            />
            <path
              class="achievement-river__path-main"
              d="M 44 148 C 116 105 196 88 282 88 C 374 88 440 42 534 82 C 608 112 647 170 740 158 C 824 146 844 88 908 68 C 944 56 958 72 982 36"
            />
          </svg>

          <div class="achievement-river__steps">
            <article
              v-for="tier in tiers"
              :key="tier.value"
              class="achievement-river__node"
              :class="[
                `achievement-river__node--${tier.value}`,
                tier.locked ? 'achievement-river__node--locked' : tier.completed ? 'achievement-river__node--done' : 'achievement-river__node--active'
              ]"
            >
              <div class="achievement-river__badge" aria-hidden="true">
                <span>{{ tier.badge }}</span>
              </div>
              <div class="achievement-river__meta">
                <div class="text-xs font-semibold text-slate-500">第 {{ tier.value }} 层</div>
                <h3 class="mt-1 text-base font-bold text-slate-950">{{ tier.label }}</h3>
                <div class="mt-2 flex items-center justify-center gap-2 text-xs font-semibold">
                  <span>{{ tier.unlocked }}/{{ tier.items.length }} 已完成</span>
                  <span>{{ tier.percent }}%</span>
                </div>
                <div class="mt-2 h-1.5 rounded-full bg-stone-100">
                  <div class="achievement-river__progress h-1.5 rounded-full" :style="{ width: `${tier.percent}%` }"></div>
                </div>
                <p class="mt-2 text-xs leading-5 text-slate-500">{{ tier.hint }}</p>
              </div>
            </article>
          </div>
        </div>
      </div>
    </section>

    <section class="achievement-lower-grid">
      <section class="passport-cover-card" role="button" tabindex="0" @click="openPassportModal" @keydown.enter.prevent="openPassportModal">
        <div class="passport-cover-card__content">
          <div class="passport-cover-card__top">
            <div>
              <div class="passport-cover-card__kicker">TourPilot</div>
              <h2>旅行护照</h2>
            </div>
            <div class="passport-cover-card__serial">
              <strong>{{ passportProgress.unlocked }}/{{ passportProgress.total }}</strong>
              <span>护照进度</span>
            </div>
          </div>

          <div class="passport-cover-card__emblem" aria-hidden="true">
            <span>TP</span>
          </div>
          <div class="passport-cover-card__title-mark">PASSPORT</div>

          <div class="passport-cover-card__progress">
            <div class="passport-cover-card__next">
              {{ nextPassportTask ? `下一项：${nextPassportTask.name}` : '全部任务已完成' }}
            </div>
            <div class="mt-3 flex justify-between text-xs font-semibold">
              <span>完成进度</span>
              <span>{{ passportProgress.percent }}%</span>
            </div>
            <div class="passport-cover-card__track">
              <div class="passport-cover-card__bar" :style="{ width: `${passportProgress.percent}%` }"></div>
            </div>
          </div>
        </div>
      </section>

      <div class="achievement-right-stack">
        <section
          class="achievement-panel collection-wall-card rounded-md border p-5"
          role="button"
          tabindex="0"
          @click="openCollectionWallModal"
          @keydown.enter.prevent="openCollectionWallModal"
        >
          <div class="flex items-center justify-between gap-3">
            <div>
              <h2 class="text-lg font-semibold text-slate-950">数字纪念凭证墙</h2>
              <p class="mt-1 text-sm text-slate-500">收集到的凭证会点亮插槽，可进入证书页生成分享卡。</p>
            </div>
          </div>

          <div class="collection-grid mt-4">
            <button
              v-for="item in previewCollectibles"
              :key="item.id"
              type="button"
              class="collection-slot collection-slot--owned"
              @click.stop="openCollectibleDetail(item)"
            >
              <div class="collection-slot__badge" aria-hidden="true">
                <img v-if="item.imageUrl" :src="item.imageUrl" :alt="item.name" class="collection-slot__image">
                <div v-else class="collection-slot__fallback">
                  <span>{{ badgeInitial(item) }}</span>
                </div>
              </div>
              <div class="collection-slot__body">
                <div class="collection-slot__name">{{ item.name }}</div>
              </div>
            </button>

            <div
              v-for="slot in previewCollectionPlaceholders"
              :key="slot"
              class="collection-slot collection-slot--locked"
            >
              <div class="collection-slot__lock" aria-hidden="true"></div>
              <div class="mt-2 font-semibold text-slate-600">待解锁凭证</div>
              <p class="mt-1 text-xs leading-5 text-slate-400">完成护照任务后点亮</p>
            </div>
          </div>
        </section>

        <section class="badge-feature-card">
          <div class="flex items-start gap-3">
            <div class="badge-feature-card__icon" aria-hidden="true">徽</div>
            <div>
              <h2 class="text-lg font-semibold text-slate-950">实体徽章申请</h2>
              <p class="mt-1 text-sm leading-6 text-slate-500">解锁第 2 层以上成就后，才可提交实体徽章兑换申请。</p>
            </div>
          </div>
          <div class="mt-4 rounded-md px-3 py-2 text-sm font-semibold" :class="badgeEligible ? 'bg-[#eef3ef] text-[#667b70]' : 'bg-stone-100 text-stone-500'">
            {{ badgeEligibilityLabel }}
          </div>
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
          <div v-else class="mt-4 rounded-md border border-dashed border-stone-300 bg-white/70 p-4 text-sm text-stone-500">
            暂无申请记录
          </div>
        </section>
      </div>
    </section>

    <section v-if="redeemingAchievement || isReviewer" class="achievement-secondary-grid">
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
    </section>

    <div v-if="showPassportModal" class="passport-modal-backdrop" @click.self="showPassportModal = false">
      <section class="passport-modal" role="dialog" aria-modal="true" aria-label="护照任务" @wheel.stop @touchmove.stop>
        <div class="passport-modal__spine" aria-hidden="true"></div>
        <div class="passport-modal__content">
          <div class="passport-modal__header">
            <div>
              <div class="text-xs font-semibold uppercase tracking-[0.18em] text-stone-500">TourPilot Passport</div>
              <h2 class="mt-2 text-2xl font-bold text-slate-950">护照任务</h2>
              <p class="mt-2 text-sm leading-6 text-slate-500">按层级完成任务，逐步点亮数字凭证和实体徽章资格。</p>
            </div>
            <button class="rounded-md border border-stone-300 px-3 py-2 text-sm font-semibold text-stone-700 hover:bg-stone-100" @click="showPassportModal = false">
              关闭
            </button>
          </div>

          <div class="passport-task-list mt-5">
            <article v-for="achievement in achievementList" :key="achievement.id" class="passport-task">
              <div class="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <div class="text-xs font-semibold text-stone-500">{{ achievement.tierLabel }}</div>
                  <h3 class="mt-1 text-base font-bold text-slate-950">{{ achievement.name }}</h3>
                  <p class="mt-1 text-sm leading-6 text-slate-500">{{ achievement.description }}</p>
                </div>
                <span
                  :class="[
                    'rounded-md px-2.5 py-1 text-xs font-semibold',
                    achievement.status === 'unlocked' ? 'bg-[#eef3ef] text-[#667b70]' : achievement.status === 'in_progress' ? 'bg-[#f3eee9] text-[#9a765d]' : 'bg-stone-100 text-stone-500'
                  ]"
                >
                  {{ achievement.statusLabel }}
                </span>
              </div>

              <div class="mt-3">
                <div class="flex justify-between text-xs font-medium text-slate-500">
                  <span>{{ achievement.progress?.label || '等待收集印章' }}</span>
                  <span>{{ achievement.progressPercent || 0 }}%</span>
                </div>
                <div class="mt-2 h-2 rounded-full bg-stone-100">
                  <div class="h-2 rounded-full bg-[#7e9488]" :style="{ width: `${achievement.progressPercent || 0}%` }"></div>
                </div>
              </div>

              <div v-if="achievement.requiredSpots?.length" class="mt-3 flex flex-wrap gap-2">
                <span
                  v-for="spot in achievement.requiredSpots"
                  :key="`${achievement.id}-${spot}`"
                  class="rounded-md px-2.5 py-1 text-xs font-semibold"
                  :class="achievement.checkedSpots?.includes(spot) ? 'bg-[#eef3ef] text-[#667b70]' : 'bg-stone-100 text-stone-500'"
                >
                  {{ spot }}
                </span>
              </div>

              <div class="mt-3 rounded-md bg-stone-50 px-3 py-2 text-sm text-slate-700">
                {{ achievement.nextAction || '继续探索，收集下一枚旅行印章' }}
              </div>

              <div class="mt-3 flex flex-wrap gap-2">
                <button
                  class="rounded-md bg-slate-900 px-3 py-2 text-sm font-semibold text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:bg-slate-400"
                  :disabled="achievement.status !== 'unlocked' || claimingId === achievement.id || achievement.collectibleId"
                  @click="claimAchievement(achievement)"
                >
                  {{ achievement.collectibleId ? '已领取数字凭证' : claimingId === achievement.id ? '领取中...' : '领取数字凭证' }}
                </button>
                <button
                  v-if="achievement.collectibleId"
                  type="button"
                  class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100"
                  @click="openCollectibleDetail({ id: achievement.collectibleId })"
                >
                  查看证书
                </button>
                <button
                  v-if="achievement.hasPhysicalBadge"
                  class="rounded-md border border-[#b58d72] px-3 py-2 text-sm font-semibold text-[#8a6853] hover:bg-[#f3eee9] disabled:cursor-not-allowed disabled:opacity-50"
                  :disabled="achievement.status !== 'unlocked'"
                  @click="openRedemption(achievement); showPassportModal = false"
                >
                  {{ achievement.redemptionStatus ? `兑换状态：${achievement.redemptionStatusLabel}` : '申请实体徽章' }}
                </button>
              </div>
            </article>
          </div>
        </div>
      </section>
    </div>

    <div v-if="showCollectionWallModal" class="collection-modal-backdrop" @click.self="showCollectionWallModal = false">
      <section class="collection-modal" role="dialog" aria-modal="true" aria-label="&#25968;&#23383;&#32426;&#24565;&#20973;&#35777;&#22681;" @wheel.stop @touchmove.stop>
        <div class="collection-modal__header">
          <div>
            <div class="collection-modal__kicker">&#25968;&#23383;&#32426;&#24565;</div>
            <h2>&#25968;&#23383;&#32426;&#24565;&#20973;&#35777;&#22681;</h2>
          </div>
          
        </div>

        <div class="collection-modal__body">
          <button
            v-for="item in collectibles"
            :key="`modal-${item.id}`"
            type="button"
            class="collection-slot collection-slot--owned collection-slot--modal"
            @click="openCollectibleDetail(item)"
          >
            <div class="collection-slot__badge" aria-hidden="true">
              <img v-if="item.imageUrl" :src="item.imageUrl" :alt="item.name" class="collection-slot__image">
              <div v-else class="collection-slot__fallback">
                <span>{{ badgeInitial(item) }}</span>
              </div>
            </div>
            <div class="collection-slot__body">
              <div class="collection-slot__name">{{ item.name }}</div>
            </div>
          </button>

          <div
            v-for="slot in fullCollectionPlaceholders"
            :key="slot"
            class="collection-slot collection-slot--locked collection-slot--modal"
          >
            <div class="collection-slot__lock" aria-hidden="true"></div>
            <div class="mt-2 font-semibold text-slate-600">&#24453;&#35299;&#38145;&#20973;&#35777;</div>
            <p class="mt-1 text-xs leading-5 text-slate-400">&#23436;&#25104;&#25252;&#29031;&#20219;&#21153;&#21518;&#28857;&#20142;</p>
          </div>
        </div>
      </section>
    </div>

    <div v-if="showCollectibleDetailModal" class="certificate-modal-backdrop" @click.self="closeCollectibleDetail">
      <section class="certificate-modal" role="dialog" aria-modal="true" aria-label="&#25968;&#23383;&#32426;&#24565;&#20973;&#35777;&#35814;&#24773;" @wheel.stop @touchmove.stop>
        <div class="certificate-modal__art">
          <div class="certificate-modal__image-frame">
            <img v-if="selectedCollectible?.imageUrl" :src="selectedCollectible.imageUrl" :alt="selectedCollectible.name">
            <div v-else class="certificate-modal__image-fallback">{{ badgeInitial(selectedCollectible || {}) }}</div>
          </div>
          <div class="certificate-modal__seal">TourPilot Certificate</div>
        </div>
        <div class="certificate-modal__content">
          <div class="certificate-modal__kicker">TourPilot &#25968;&#23383;&#35777;&#20070;</div>
          <h2>{{ selectedCollectible?.name || '\u6570\u5b57\u7eaa\u5ff5\u51ed\u8bc1' }}</h2>
          <p>{{ selectedCollectible?.description || '\u8bb0\u5f55\u4e00\u6b21\u771f\u5b9e\u7684\u65c5\u884c\u63a2\u7d22\u4e0e\u6210\u5c31\u89e3\u9501\u3002' }}</p>

          <div class="certificate-modal__meta-grid">
            <div>
              <span>&#26469;&#28304;&#25104;&#23601;</span>
              <strong>{{ selectedCollectible?.achievementName || selectedCollectible?.tierLabel || '\u65c5\u884c\u62a4\u7167\u6210\u5c31' }}</strong>
            </div>
            <div>
              <span>&#33719;&#24471;&#26102;&#38388;</span>
              <strong>{{ formatCollectibleTime(selectedCollectible?.mintedAt || selectedCollectible?.createdAt) || '\u5df2\u89e3\u9501' }}</strong>
            </div>
            <div>
              <span>&#20973;&#35777;&#27169;&#24335;</span>
              <strong>{{ selectedCollectible?.chainMode || '\u6a21\u62df\u94fe\u4e0a\u51ed\u8bc1' }}</strong>
            </div>
            <div>
              <span>&#23618;&#32423;</span>
              <strong>{{ selectedCollectible?.tierLabel || '\u65c5\u884c\u62a4\u7167' }}</strong>
            </div>
          </div>

          <div class="certificate-modal__hash">
            <span>&#20973;&#35777;&#32534;&#21495;</span>
            <strong>{{ selectedCollectible?.tokenId || '-' }}</strong>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
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

const tierHints = {
  1: '完成首枚印章',
  2: '串联主题路线',
  3: '发布完整游记',
  4: '人工评审进阶'
}

const tierBadges = {
  1: 'L1',
  2: 'L2',
  3: 'L3',
  4: 'L4'
}

const overview = ref({ authenticated: false, total: 0, unlocked: 0, collectibleCount: 0 })
const achievementList = ref(fallbackAchievements)
const collectibles = ref([])
const redemptionHistory = ref([])
const reviewQueue = ref([])
const feedback = ref('')
const feedbackType = ref('success')
const claimingId = ref(0)
const generatingBadgeIds = ref(new Set())
const redeemingAchievement = ref(null)
const redeeming = ref(false)
const showPassportModal = ref(false)
const showCollectionWallModal = ref(false)
const showCollectibleDetailModal = ref(false)
const selectedCollectible = ref(null)
const redemptionForm = ref({
  recipientName: '',
  phone: '',
  address: '',
  note: ''
})

const isReviewer = computed(() => authStore.user?.username === 'demo_user')

const passportProgress = computed(() => {
  const total = achievementList.value.length
  const unlocked = achievementList.value.filter(item => item.status === 'unlocked').length
  return {
    total,
    unlocked,
    percent: total ? Math.round((unlocked / total) * 100) : 0
  }
})

const nextPassportTask = computed(() => achievementList.value.find(item => item.status !== 'unlocked') || null)

const previewCollectibles = computed(() => collectibles.value.slice(0, 4))

const collectionSlotCount = computed(() => Math.max(8, collectibles.value.length))

const collectionPlaceholders = computed(() => {
  const count = Math.max(0, collectionSlotCount.value - collectibles.value.length)
  return Array.from({ length: count }, (_, index) => `locked-slot-${index + 1}`)
})

const previewCollectionPlaceholders = computed(() => {
  const count = Math.max(0, 4 - previewCollectibles.value.length)
  return Array.from({ length: count }, (_, index) => `preview-locked-slot-${index + 1}`)
})

const fullCollectionPlaceholders = computed(() => collectionPlaceholders.value)

const badgeEligible = computed(() => achievementList.value.some(item => Number(item.tier) >= 2 && item.status === 'unlocked'))

const badgeEligibilityLabel = computed(() => (
  badgeEligible.value ? '已具备实体徽章申请资格' : '条件未达成：需先解锁第 2 层以上成就'
))

function setPageScrollLock(locked) {
  document.body.style.overflow = locked ? 'hidden' : ''
}

function formatCollectibleTime(value) {
  if (!value) return ''
  return String(value).slice(0, 16).replace('T', ' ')
}

const tiers = computed(() => {
  let previousHasUnlock = true
  return [1, 2, 3, 4].map(value => {
    const items = achievementList.value.filter(item => Number(item.tier) === value)
    const unlocked = items.filter(item => item.status === 'unlocked').length
    const hasProgress = items.some(item => Number(item.progressPercent || 0) > 0 || item.status === 'in_progress')
    const completed = items.length > 0 && unlocked >= items.length
    const available = value === 1 || previousHasUnlock || unlocked > 0 || hasProgress
    const tier = {
      value,
      label: items[0]?.tierLabel || `第 ${value} 层`,
      hint: tierHints[value],
      badge: tierBadges[value],
      items,
      unlocked,
      percent: items.length ? Math.round(unlocked / items.length * 100) : 0,
      completed,
      locked: !available
    }
    previousHasUnlock = unlocked > 0
    return tier
  })
})

function showFeedback(message, type = 'success') {
  feedback.value = message
  feedbackType.value = type
}

function badgeInitial(item) {
  const text = item.achievementCode || item.name || item.tierLabel || 'TP'
  const ascii = String(text).replace(/[^a-zA-Z0-9]/g, '')
  if (ascii) return ascii.slice(0, 2).toUpperCase()
  return String(text).slice(0, 1) || 'T'
}

function markBadgeGenerating(id, generating) {
  const next = new Set(generatingBadgeIds.value)
  if (generating) next.add(id)
  else next.delete(id)
  generatingBadgeIds.value = next
}

async function generateBadgeImage(item) {
  if (!item?.id || item.imageUrl || generatingBadgeIds.value.has(item.id)) return
  markBadgeGenerating(item.id, true)
  try {
    const result = await tourismApi.generateCollectibleBadge(item.id)
    const index = collectibles.value.findIndex(collectible => collectible.id === item.id)
    if (index >= 0) {
      collectibles.value[index] = {
        ...collectibles.value[index],
        imageUrl: result.imageUrl,
        badgeProvider: result.provider,
        badgePrompt: result.prompt
      }
    }
  } catch {
    // Keep the designed placeholder visible; generation can be retried after refresh.
  } finally {
    markBadgeGenerating(item.id, false)
  }
}

function scheduleBadgeImageGeneration() {
  collectibles.value
    .filter(item => item?.id && !item.imageUrl)
    .slice(0, 4)
    .forEach(item => {
      window.setTimeout(() => generateBadgeImage(item), 120)
    })
}

async function loadAchievements() {
  try {
    const data = await tourismApi.achievements()
    overview.value = data
    achievementList.value = data.items?.length ? data.items : fallbackAchievements
    collectibles.value = data.collectibles || []
    redemptionHistory.value = data.redemptionHistory || []
    scheduleBadgeImageGeneration()
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

async function openPassportModal() {
  await loadAll()
  showPassportModal.value = true
}

async function openCollectionWallModal() {
  await loadAchievements()
  showCollectionWallModal.value = true
}

async function openCollectibleDetail(item) {
  if (!item?.id) return
  selectedCollectible.value = { ...item }
  showCollectibleDetailModal.value = true
  try {
    const detail = await tourismApi.collectibleDetail(item.id)
    selectedCollectible.value = { ...selectedCollectible.value, ...detail }
  } catch (error) {
    showFeedback(error.response?.data?.message || '证书详情暂时无法打开。', 'error')
  }
}

function closeCollectibleDetail() {
  showCollectibleDetailModal.value = false
  selectedCollectible.value = null
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

watch(
  () => showPassportModal.value || showCollectionWallModal.value || showCollectibleDetailModal.value,
  setPageScrollLock
)

onMounted(loadAll)
onUnmounted(() => setPageScrollLock(false))
</script>

<style scoped>
.achievement-river {
  position: relative;
  min-height: 280px;
  overflow: hidden;
}

.achievement-river__content {
  position: relative;
  min-height: 280px;
  transform: translateY(-38px);
}

.achievement-river__path {
  position: absolute;
  inset: 38px 24px auto;
  width: calc(100% - 48px);
  height: 210px;
  pointer-events: none;
}

.achievement-river__path-shadow,
.achievement-river__path-main {
  fill: none;
  stroke-linecap: round;
}

.achievement-river__path-shadow {
  stroke: #e7e4dd;
  stroke-width: 26;
}

.achievement-river__path-main {
  stroke: #a7c4b5;
  stroke-width: 16;
}

.achievement-river__steps {
  position: relative;
  min-height: 280px;
}

.achievement-river__node {
  position: absolute;
  width: 150px;
  text-align: center;
}

.achievement-river__node--1 {
  left: 4%;
  top: 96px;
}

.achievement-river__node--2 {
  left: 32%;
  top: 50px;
}

.achievement-river__node--3 {
  right: 27%;
  top: 104px;
}

.achievement-river__node--4 {
  right: 4%;
  top: 64px;
}

.achievement-river__badge {
  display: grid;
  width: 54px;
  height: 54px;
  margin: 0 auto;
  place-items: center;
  border: 3px solid #ffffff;
  border-radius: 999px;
  background: #7e9488;
  color: #ffffff;
  font-weight: 800;
  box-shadow: 0 12px 24px rgba(82, 92, 86, 0.18);
}

.achievement-river__meta {
  margin-top: 8px;
  border: 1px solid #dedbd3;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.96);
  padding: 8px 10px;
  box-shadow: 0 8px 20px rgba(87, 82, 74, 0.06);
}

.achievement-river__progress {
  background: #7e9488;
}

.achievement-river__node--active .achievement-river__badge {
  background: #b58d72;
}

.achievement-river__node--locked {
  opacity: 0.66;
}

.achievement-river__node--locked .achievement-river__badge {
  background: #b8c0bf;
}

.achievement-river__node--locked .achievement-river__meta {
  background: rgba(247, 246, 242, 0.96);
}

.achievement-river__node--locked .achievement-river__progress {
  background: #b8c0bf;
}

.achievement-lower-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 24px;
  align-items: stretch;
}

.passport-cover-card {
  position: relative;
  min-height: 390px;
  overflow: hidden;
  border: 1px solid #cfc6ba;
  border-radius: 8px;
  background: #f0ebe5;
  color: #354640;
  cursor: pointer;
  box-shadow: 0 16px 30px rgba(87, 82, 74, 0.1);
}

.passport-cover-card::before {
  content: '';
  position: absolute;
  inset: 16px;
  border: 1px solid rgba(126, 148, 136, 0.28);
  border-radius: 8px;
  pointer-events: none;
}

.passport-cover-card::after {
  content: '';
  position: absolute;
  top: 22px;
  bottom: 22px;
  left: 64px;
  width: 2px;
  border-radius: 999px;
  background: repeating-linear-gradient(
    180deg,
    #8fa398 0 8px,
    transparent 8px 15px
  );
  box-shadow:
    -10px 0 0 rgba(255, 255, 255, 0.26),
    10px 0 0 rgba(126, 148, 136, 0.12);
  pointer-events: none;
}

.passport-cover-card:hover {
  border-color: #b8aea2;
  box-shadow: 0 20px 36px rgba(87, 82, 74, 0.14);
}

.passport-cover-card:focus-visible {
  outline: 3px solid rgba(126, 148, 136, 0.38);
  outline-offset: 3px;
}

.passport-cover-card__content {
  position: relative;
  z-index: 1;
  display: flex;
  min-height: 390px;
  flex-direction: column;
  padding: 28px 32px 26px 96px;
}

.passport-cover-card__top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 18px;
}

.passport-cover-card__kicker {
  color: #7e9488;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.18em;
  text-transform: uppercase;
}

.passport-cover-card h2 {
  margin-top: 10px;
  font-size: 32px;
  font-weight: 900;
  letter-spacing: 0;
}

.passport-cover-card__serial {
  min-width: 88px;
  border: 1px solid rgba(126, 148, 136, 0.26);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.5);
  padding: 10px 12px;
  text-align: right;
}

.passport-cover-card__serial strong {
  display: block;
  font-size: 24px;
  line-height: 1;
}

.passport-cover-card__serial span {
  display: block;
  margin-top: 4px;
  color: #7d887f;
  font-size: 12px;
}

.passport-cover-card__emblem {
  display: grid;
  width: 118px;
  height: 118px;
  margin: 38px auto 12px;
  place-items: center;
  border: 2px solid rgba(126, 148, 136, 0.34);
  border-radius: 999px;
  background:
    radial-gradient(circle, rgba(255, 255, 255, 0.58), transparent 62%),
    rgba(126, 148, 136, 0.1);
  box-shadow: inset 0 0 0 10px rgba(126, 148, 136, 0.08);
}

.passport-cover-card__emblem span {
  font-size: 36px;
  font-weight: 900;
  letter-spacing: 0;
}

.passport-cover-card__title-mark {
  margin-bottom: 34px;
  color: #5d6f66;
  font-size: 18px;
  font-weight: 900;
  letter-spacing: 0.12em;
  text-align: center;
}

.passport-cover-card__progress {
  margin-top: auto;
  color: #5d6f66;
}

.passport-cover-card__next {
  border: 1px solid rgba(126, 148, 136, 0.2);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.42);
  padding: 10px 12px;
  color: #354640;
  font-size: 14px;
  font-weight: 800;
}

.passport-cover-card__track {
  height: 8px;
  margin-top: 10px;
  overflow: hidden;
  border-radius: 999px;
  background: rgba(126, 148, 136, 0.16);
}

.passport-cover-card__bar {
  height: 100%;
  border-radius: inherit;
  background: #7e9488;
}

.achievement-panel {
  display: flex;
  flex-direction: column;
}

.achievement-right-stack {
  display: flex;
  min-height: 390px;
  flex-direction: column;
  gap: 24px;
}

.achievement-right-stack .achievement-panel {
  flex: 1 1 auto;
  min-height: 236px;
}

.achievement-right-stack .badge-feature-card {
  flex: 0 0 auto;
}

.achievement-panel .collection-grid {
  flex: 1;
}

.achievement-secondary-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 24px;
  align-items: start;
}

.collection-wall-card {
  border-color: #b4a489;
  background: #c7b8a1;
  color: #2f3630;
  box-shadow: 0 14px 28px rgba(87, 82, 74, 0.12);
  cursor: pointer;
}

.collection-wall-card h2 {
  color: #26342e;
}

.collection-wall-card p {
  color: rgba(47, 54, 48, 0.72);
}

.collection-wall-card:focus-visible {
  outline: 3px solid rgba(126, 148, 136, 0.38);
  outline-offset: 3px;
}

.collection-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.collection-slot {
  min-height: 90px;
  border-radius: 8px;
  padding: 12px;
  color: inherit;
  text-decoration: none;
  transition: border-color 160ms ease, box-shadow 160ms ease, transform 160ms ease;
}

.collection-slot--owned {
  display: grid;
  min-height: 118px;
  grid-template-columns: 74px minmax(0, 1fr);
  align-items: center;
  gap: 12px;
  border: 1px solid rgba(96, 82, 64, 0.24);
  background: rgba(255, 252, 246, 0.72);
  box-shadow: 0 8px 18px rgba(87, 82, 74, 0.08);
  text-align: left;
  cursor: pointer;
}

.collection-slot--owned:hover {
  border-color: rgba(96, 82, 64, 0.38);
  box-shadow: 0 12px 22px rgba(87, 82, 74, 0.16);
  transform: translateY(-1px);
}

.collection-slot__badge {
  display: grid;
  width: 74px;
  height: 74px;
  place-items: center;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.46);
  box-shadow: inset 0 0 0 1px rgba(96, 82, 64, 0.14);
}

.collection-slot__image {
  width: 62px;
  height: 62px;
  border-radius: 14px;
  object-fit: cover;
  box-shadow: 0 8px 16px rgba(87, 82, 74, 0.14);
}

.collection-slot__fallback {
  position: relative;
  display: grid;
  width: 62px;
  height: 62px;
  place-items: center;
  border: 2px solid #657d72;
  border-radius: 999px;
  background:
    radial-gradient(circle at 50% 42%, rgba(255, 255, 255, 0.64) 0 28%, transparent 29%),
    #eee7dc;
  color: #657d72;
  font-size: 15px;
  font-weight: 900;
}

.collection-slot__fallback::before,
.collection-slot__fallback::after {
  content: '';
  position: absolute;
  border-radius: 999px;
  background: #9a7c66;
}

.collection-slot__fallback::before {
  width: 34px;
  height: 2px;
  bottom: 18px;
  left: 14px;
}

.collection-slot__fallback::after {
  width: 22px;
  height: 2px;
  bottom: 12px;
  left: 20px;
}

.collection-slot__body {
  min-width: 0;
}

.collection-slot__name {
  display: -webkit-box;
  overflow: hidden;
  color: #111827;
  font-size: 15px;
  font-weight: 800;
  line-height: 1.45;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}

.collection-slot--locked {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  border: 1.5px dashed rgba(96, 82, 64, 0.34);
  background: rgba(248, 247, 244, 0.46);
  text-align: center;
}

.collection-slot__lock {
  position: relative;
  width: 34px;
  height: 28px;
  border-radius: 8px;
  background: rgba(126, 148, 136, 0.16);
  opacity: 0.8;
}

.collection-slot__lock::before {
  content: '';
  position: absolute;
  left: 50%;
  top: -10px;
  width: 18px;
  height: 16px;
  border: 3px solid rgba(126, 148, 136, 0.36);
  border-bottom: 0;
  border-radius: 14px 14px 0 0;
  transform: translateX(-50%);
}

.collection-slot__lock::after {
  content: '';
  position: absolute;
  left: 50%;
  top: 11px;
  width: 5px;
  height: 8px;
  border-radius: 999px;
  background: rgba(126, 148, 136, 0.42);
  transform: translateX(-50%);
}

.badge-feature-card {
  position: relative;
  overflow: hidden;
  border: 1px solid #d9d2c7;
  border-radius: 8px;
  background: linear-gradient(135deg, #fffdf9 0%, #f4f1eb 100%);
  padding: 20px;
  box-shadow: 0 12px 26px rgba(87, 82, 74, 0.08);
}

.badge-feature-card::after {
  content: '';
  position: absolute;
  right: -38px;
  bottom: -44px;
  width: 132px;
  height: 132px;
  border: 1px solid rgba(181, 141, 114, 0.22);
  border-radius: 999px;
  pointer-events: none;
}

.badge-feature-card__icon {
  display: grid;
  flex: 0 0 auto;
  width: 42px;
  height: 42px;
  place-items: center;
  border-radius: 8px;
  background: #d8c8b7;
  color: #5c5046;
  font-weight: 800;
}

.passport-modal-backdrop {
  position: fixed;
  inset: 0;
  z-index: 60;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: rgba(15, 23, 42, 0.38);
}

.passport-modal {
  position: relative;
  display: grid;
  width: min(980px, calc(100vw - 32px));
  height: min(760px, calc(100vh - 48px));
  max-height: calc(100vh - 48px);
  grid-template-columns: 20px minmax(0, 1fr);
  overflow: hidden;
  border: 1px solid #d7cabb;
  border-radius: 8px 16px 16px 8px;
  background: #f7f0e4;
  box-shadow: 0 24px 60px rgba(15, 23, 42, 0.26);
}

.passport-modal::before {
  content: '';
  position: absolute;
  top: 16px;
  bottom: 16px;
  left: 50%;
  width: 1px;
  background: linear-gradient(180deg, transparent, rgba(126, 111, 96, 0.24), transparent);
}

.passport-modal__spine {
  background:
    repeating-linear-gradient(180deg, rgba(255, 255, 255, 0.22) 0 10px, transparent 10px 20px),
    #9c8572;
}

.passport-modal__content {
  overflow: auto;
  overscroll-behavior: contain;
  padding: 0 24px 24px;
  background:
    radial-gradient(circle at 94% 12%, rgba(167, 196, 181, 0.22), transparent 28%),
    linear-gradient(90deg, #fbf7ee 0%, #f7f0e4 50%, #fbf8ef 100%);
}

.passport-modal__header {
  position: sticky;
  top: 0;
  z-index: 2;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  margin: 0 -24px;
  border-bottom: 1px solid rgba(126, 111, 96, 0.14);
  background: #eee7dc;
  padding: 24px 24px 16px;
}

.passport-task-list {
  display: grid;
  gap: 12px;
}

.passport-task {
  border: 1px solid #ded6ca;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.82);
  padding: 14px;
  box-shadow: 0 8px 18px rgba(87, 82, 74, 0.06);
}

.collection-modal-backdrop,
.certificate-modal-backdrop {
  position: fixed;
  inset: 0;
  z-index: 70;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: rgba(15, 23, 42, 0.38);
}

.collection-modal {
  width: min(1180px, calc(100vw - 32px));
  max-height: calc(100vh - 48px);
  overflow: hidden;
  border: 1px solid #b4a489;
  border-radius: 8px;
  background: #c7b8a1;
  box-shadow: 0 24px 60px rgba(15, 23, 42, 0.26);
}

.collection-modal__header {
  position: sticky;
  top: 0;
  z-index: 2;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  border-bottom: 1px solid rgba(96, 82, 64, 0.18);
  background: #c1b095;
  padding: 24px 34px 20px;
}

.collection-modal__kicker,
.certificate-modal__kicker {
  color: #5d6f66;
  font-size: 12px;
  font-weight: 900;
  letter-spacing: 0.14em;
  text-transform: uppercase;
}

.collection-modal__kicker {
  color: #5c6d63;
  letter-spacing: 0.2em;
}

.collection-modal__header h2 {
  margin-top: 6px;
  color: #26342e;
  font-size: 26px;
  font-weight: 900;
}

.modal-close-button,
.certificate-modal__close {
  border: 1px solid rgba(96, 82, 64, 0.24);
  border-radius: 8px;
  background: rgba(255, 252, 246, 0.72);
  padding: 9px 14px;
  color: #354640;
  font-size: 14px;
  font-weight: 800;
}

.collection-modal__body {
  display: grid;
  max-height: calc(100vh - 150px);
  overflow: auto;
  overscroll-behavior: contain;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  padding: 28px 34px 34px;
}

.collection-slot--modal {
  min-height: 156px;
  padding: 18px;
  grid-template-columns: 86px minmax(0, 1fr);
  gap: 18px;
}

.collection-slot--modal .collection-slot__badge {
  width: 86px;
  height: 86px;
}

.collection-slot--modal .collection-slot__image,
.collection-slot--modal .collection-slot__fallback {
  width: 72px;
  height: 72px;
}

.collection-slot--modal .collection-slot__name {
  font-size: 16px;
}

.certificate-modal {
  position: relative;
  display: grid;
  width: min(1060px, calc(100vw - 32px));
  max-height: calc(100vh - 48px);
  grid-template-columns: minmax(330px, 0.95fr) minmax(0, 1.05fr);
  overflow: auto;
  overscroll-behavior: contain;
  border: 1px solid #cfc6ba;
  border-radius: 4px;
  background:
    linear-gradient(90deg, #f1ece5 0%, #f7f2ea 48%, #fbf8f1 48%, #fffdf8 100%);
  box-shadow: 0 24px 70px rgba(15, 23, 42, 0.28);
}

.certificate-modal::before {
  content: '';
  position: absolute;
  inset: 18px;
  z-index: 1;
  border: 1px solid rgba(96, 82, 64, 0.18);
  pointer-events: none;
}

.certificate-modal::after {
  content: '';
  position: absolute;
  top: 18px;
  bottom: 18px;
  left: 48%;
  z-index: 1;
  width: 1px;
  background: linear-gradient(180deg, transparent, rgba(96, 82, 64, 0.18), transparent);
  pointer-events: none;
}

.certificate-modal__close {
  position: absolute;
  top: 18px;
  right: 18px;
  z-index: 3;
}

.certificate-modal__art {
  position: relative;
  z-index: 2;
  display: flex;
  min-height: 560px;
  flex-direction: column;
  justify-content: center;
  padding: 58px 48px 52px;
}

.certificate-modal__image-frame {
  display: grid;
  aspect-ratio: 1;
  width: min(100%, 360px);
  margin: 0 auto;
  place-items: center;
  border: 1px solid rgba(96, 82, 64, 0.24);
  border-radius: 4px;
  background: rgba(255, 252, 246, 0.72);
  box-shadow:
    inset 0 0 0 10px rgba(255, 255, 255, 0.28),
    0 18px 36px rgba(87, 82, 74, 0.14);
}

.certificate-modal__image-frame img {
  width: calc(100% - 38px);
  height: calc(100% - 38px);
  border-radius: 4px;
  object-fit: cover;
}

.certificate-modal__image-fallback {
  display: grid;
  width: 72%;
  height: 72%;
  place-items: center;
  border: 3px solid #657d72;
  border-radius: 999px;
  color: #657d72;
  font-size: 44px;
  font-weight: 900;
}

.certificate-modal__seal {
  margin-top: 30px;
  color: #5d6f66;
  font-size: 14px;
  font-weight: 900;
  letter-spacing: 0.18em;
  text-align: center;
  text-transform: uppercase;
}

.certificate-modal__content {
  position: relative;
  z-index: 2;
  padding: 64px 58px 48px;
}

.certificate-modal__content h2 {
  margin-top: 12px;
  color: #111827;
  font-size: 34px;
  font-weight: 900;
  line-height: 1.25;
}

.certificate-modal__content p {
  margin-top: 18px;
  color: #53615b;
  font-size: 15px;
  line-height: 1.8;
}

.certificate-modal__meta-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0;
  margin-top: 30px;
  border-top: 1px solid #d9d2c8;
  border-left: 1px solid #d9d2c8;
}

.certificate-modal__meta-grid div,
.certificate-modal__hash {
  border-right: 1px solid #d9d2c8;
  border-bottom: 1px solid #d9d2c8;
  border-radius: 0;
  background: rgba(255, 255, 255, 0.34);
  padding: 18px 20px;
}

.certificate-modal__hash {
  margin-top: 22px;
  border: 1px solid #d9d2c8;
}

.certificate-modal__meta-grid span,
.certificate-modal__hash span {
  display: block;
  color: #79827d;
  font-size: 12px;
  font-weight: 900;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.certificate-modal__meta-grid strong,
.certificate-modal__hash strong {
  display: block;
  margin-top: 6px;
  overflow-wrap: anywhere;
  color: #111827;
  font-size: 14px;
  font-weight: 900;
  line-height: 1.55;
}

@media (max-width: 900px) {
  .achievement-lower-grid,
  .achievement-secondary-grid {
    grid-template-columns: 1fr;
  }

  .achievement-river {
    min-height: auto;
  }

  .achievement-river__path {
    display: none;
  }

  .achievement-river__steps {
    display: grid;
    min-height: auto;
    gap: 14px;
  }

  .achievement-river__content {
    min-height: auto;
    transform: none;
  }

  .achievement-river__node {
    position: relative;
    left: auto;
    right: auto;
    top: auto;
    display: grid;
    width: 100%;
    grid-template-columns: 72px 1fr;
    gap: 12px;
    text-align: left;
  }

  .achievement-river__badge {
    margin: 0;
  }

  .achievement-river__meta {
    margin-top: 0;
  }

  .achievement-panel {
    min-height: auto;
  }

  .passport-cover-card,
  .passport-cover-card__content,
  .achievement-right-stack {
    min-height: auto;
  }

  .passport-cover-card__content {
    padding: 24px 24px 24px 86px;
  }

  .collection-grid {
    grid-template-columns: 1fr;
  }

  .passport-modal-backdrop {
    align-items: stretch;
    padding: 12px;
  }

  .passport-modal {
    width: 100%;
    height: calc(100vh - 24px);
    max-height: calc(100vh - 24px);
  }

  .passport-modal::before {
    display: none;
  }

  .passport-modal__content {
    padding: 0 18px 18px;
  }

  .passport-modal__header {
    margin: 0 -18px;
    padding: 18px;
  }

  .collection-modal-backdrop,
  .certificate-modal-backdrop {
    align-items: stretch;
    padding: 12px;
  }

  .collection-modal,
  .certificate-modal {
    width: 100%;
    max-height: calc(100vh - 24px);
  }

  .collection-modal__header {
    padding: 18px;
  }

  .collection-modal__body {
    max-height: calc(100vh - 126px);
    grid-template-columns: repeat(2, minmax(0, 1fr));
    padding: 18px;
  }

  .certificate-modal {
    grid-template-columns: 1fr;
  }

  .certificate-modal::after {
    display: none;
  }

  .certificate-modal__art {
    min-height: auto;
    padding: 64px 24px 28px;
  }

  .certificate-modal__content {
    padding: 28px 24px;
  }

  .certificate-modal__meta-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .collection-modal__body {
    grid-template-columns: 1fr;
  }

  .collection-slot--modal {
    grid-template-columns: 78px minmax(0, 1fr);
    gap: 14px;
    min-height: 132px;
    padding: 14px;
  }
}
</style>
