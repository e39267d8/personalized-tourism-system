<template>
  <div>
    <!-- Back navigation -->
    <div class="mb-6">
      <router-link to="/diary" class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-700 transition">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
        返回广场
      </router-link>
    </div>

    <!-- Postcard Layout -->
    <DiaryPostcard :diary="diary" />

    <!-- Interaction Bar -->
    <div class="mt-6 flex items-center justify-between rounded-xl bg-white border border-slate-100 px-6 py-4 shadow-sm">
      <div class="flex items-center gap-6">
        <!-- Like -->
        <button @click="toggleLike" class="flex items-center gap-1.5 group">
          <svg class="w-5 h-5 transition" :class="liked ? 'text-rose-500 fill-rose-500' : 'text-slate-400 group-hover:text-rose-400'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
          <span class="text-sm text-slate-600">{{ likeCount }}</span>
        </button>

        <!-- Bookmark -->
        <button @click="toggleBookmark" class="flex items-center gap-1.5 group">
          <svg class="w-5 h-5 transition" :class="bookmarked ? 'text-teal-600 fill-teal-600' : 'text-slate-400 group-hover:text-teal-500'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"/></svg>
          <span class="text-sm text-slate-600">{{ bookmarkCount }}</span>
        </button>

        <!-- Views -->
        <div class="flex items-center gap-1.5">
          <svg class="w-5 h-5 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
          <span class="text-sm text-slate-400">{{ diary.stats?.views || 0 }}</span>
        </div>
      </div>

      <!-- Rating -->
      <div class="flex items-center gap-2">
        <span class="text-xs text-slate-500">评分</span>
        <div class="flex gap-0.5">
          <button
            v-for="star in 5"
            :key="star"
            @click="rateDiary(star)"
            class="transition hover:scale-110"
          >
            <svg class="w-5 h-5" :class="star <= displayRating ? 'text-amber-400 fill-amber-400' : 'text-slate-200 fill-slate-200'" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>
          </button>
        </div>
        <span class="text-sm font-medium text-amber-600">{{ displayScore }}</span>
        <span class="text-xs text-slate-400">({{ ratingCount }}人)</span>
      </div>
    </div>

    <!-- Comments Section -->
    <div class="mt-6 rounded-xl bg-white border border-slate-100 p-6 shadow-sm">
      <h3 class="text-lg font-semibold text-slate-900 mb-4">评论 ({{ comments.length }})</h3>

      <!-- Comment List -->
      <div class="space-y-4 mb-6">
        <div v-for="comment in comments" :key="comment.id" class="flex gap-3">
          <div class="w-8 h-8 rounded-full bg-gradient-to-br from-slate-300 to-slate-400 flex items-center justify-center flex-shrink-0">
            <span class="text-white text-xs font-medium">{{ (comment.author?.nickname || '匿')[0] }}</span>
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="text-sm font-medium text-slate-800">{{ comment.author?.nickname || '匿名用户' }}</span>
              <span class="text-xs text-slate-400">{{ formatTime(comment.createdAt) }}</span>
            </div>
            <p class="mt-1 text-sm text-slate-600 leading-relaxed">{{ comment.content }}</p>
          </div>
        </div>
        <p v-if="comments.length === 0" class="text-sm text-slate-400 text-center py-4">暂无评论，来说点什么吧</p>
      </div>

      <!-- Comment Input -->
      <div class="flex gap-3">
        <input
          v-model="newComment"
          type="text"
          placeholder="写下你的评论..."
          class="flex-1 rounded-lg border border-slate-200 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500/40 focus:border-teal-500"
          @keydown.enter="submitComment"
        />
        <button
          @click="submitComment"
          :disabled="!newComment.trim()"
          class="rounded-lg bg-teal-700 px-4 py-2.5 text-sm font-medium text-white hover:bg-teal-800 transition disabled:opacity-50 disabled:cursor-not-allowed"
        >
          发送
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import DiaryPostcard from '@/components/DiaryPostcard.vue'
import { tourismApi } from '@/services/tourismApi'
import { diaries as demoDiaries } from '@/data/demoData'
import { diaryStore } from '@/stores/diaryStore'
import { isAuthenticated } from '@/stores/auth'

const props = defineProps({
  id: { type: Number, required: true }
})

const route = useRoute()
const router = useRouter()
const diary = ref({
  id: 0, title: '', content: '', excerpt: '', date: '', location: '',
  images: [], tags: [], author: {}, stats: { views: 0, likes: 0, comments: 0 },
  ratingScore: 0, ratingCount: 0, bookmarkCount: 0
})
const comments = ref([])
const liked = ref(false)
const bookmarked = ref(false)
const userRating = ref(0)
const newComment = ref('')

const likeCount = computed(() => diary.value.stats?.likes || 0)
const bookmarkCount = computed(() => diary.value.bookmarkCount || 0)
const displayRating = computed(() => userRating.value || Math.round(diary.value.ratingScore || 0))
const displayScore = computed(() => {
  if (userRating.value) return userRating.value.toFixed(1)
  return (diary.value.ratingScore || 0).toFixed(1)
})
const ratingCount = computed(() => diary.value.ratingCount || 0)

function ensureAuth() {
  if (isAuthenticated()) return true
  router.push({ path: '/login', query: { redirect: route.fullPath } })
  return false
}

async function loadDiary() {
  // Prefer the just-published client copy so detail uses the same uploaded image
  // that the plaza card is already showing.
  if (diaryStore.justPublished && diaryStore.justPublished.id === props.id) {
    diary.value = { ...diaryStore.justPublished }
    return
  }

  try {
    const data = await tourismApi.diaryDetail(props.id)
    diary.value = data
  } catch {
    // Check justPublished first (user's own diary with Date.now() ID)
    if (diaryStore.justPublished && diaryStore.justPublished.id === props.id) {
      diary.value = { ...diaryStore.justPublished }
    } else {
      const demo = demoDiaries.find(d => d.id === props.id)
      diary.value = demo ? { ...demo } : (diaryStore.justPublished ? { ...diaryStore.justPublished } : { ...demoDiaries[0] })
    }
  }
}

async function loadComments() {
  // User's just-published diary should have no preset comments
  if (diaryStore.justPublished && diaryStore.justPublished.id === props.id) {
    comments.value = []
    return
  }
  try {
    const data = await tourismApi.diaryComments(props.id)
    comments.value = data.items || []
  } catch {
    const commentPool = [
      [
        { id: 1, content: '故宫真的怎么逛都逛不完，下次想去珍宝馆！', author: { nickname: '旅行达人' }, createdAt: '2026-04-13T09:30:00' },
        { id: 2, content: '景山的视角太绝了，推荐日落时分去', author: { nickname: '摄影小白' }, createdAt: '2026-04-14T16:20:00' }
      ],
      [
        { id: 1, content: '国博的古代中国展可以看一整天', author: { nickname: '文博迷' }, createdAt: '2026-04-19T10:00:00' },
        { id: 2, content: '王府井那家涮肉能给个具体店名吗？', author: { nickname: '吃货一号' }, createdAt: '2026-04-20T20:15:00' }
      ],
      [
        { id: 1, content: '什刹海的柳树拍出来太美了，求调色参数！', author: { nickname: '修图爱好者' }, createdAt: '2026-04-27T08:45:00' },
        { id: 2, content: '北海公园的船多少钱一小时？', author: { nickname: '新手驴友' }, createdAt: '2026-04-28T14:30:00' }
      ],
      [
        { id: 1, content: '颐和园长廊的画太精致了，一天都看不完', author: { nickname: '古建筑控' }, createdAt: '2026-05-03T11:20:00' },
        { id: 2, content: '佛香阁的风景真的值得爬上去！', author: { nickname: '登高望远' }, createdAt: '2026-05-03T15:40:00' }
      ],
      [
        { id: 1, content: 'UCCA的展很赞，每次去都有新发现', author: { nickname: '艺术观察者' }, createdAt: '2026-05-06T14:10:00' },
        { id: 2, content: '那家独立书店叫什么名字？想去打卡', author: { nickname: '书虫' }, createdAt: '2026-05-06T17:30:00' }
      ],
      [
        { id: 1, content: '凌晨四点出发太需要毅力了，佩服！', author: { nickname: '佛系旅行者' }, createdAt: '2026-05-01T07:00:00' },
        { id: 2, content: '慕田峪比八达岭人少太多了，强烈推荐', author: { nickname: '长城达人' }, createdAt: '2026-05-01T19:45:00' },
        { id: 3, content: '请问住的哪里？方便凌晨出发吗', author: { nickname: '计划控' }, createdAt: '2026-05-02T08:30:00' }
      ],
      [
        { id: 1, content: '帽儿胡同那家咖啡是猫咖吗？', author: { nickname: '猫奴' }, createdAt: '2026-05-07T10:00:00' },
        { id: 2, content: '南锣现在人还多吗？想工作日去', author: { nickname: '错峰出行' }, createdAt: '2026-05-07T14:20:00' }
      ],
      [
        { id: 1, content: '天坛的回音壁现在还能体验回音效果吗？', author: { nickname: '好奇宝宝' }, createdAt: '2026-04-21T09:15:00' },
        { id: 2, content: '祈年殿的光影确实绝美，金色琉璃瓦太上镜了', author: { nickname: '光影猎人' }, createdAt: '2026-04-22T18:30:00' }
      ],
      [
        { id: 1, content: '三里屯那家精酿叫什么名字？求推荐', author: { nickname: '精酿爱好者' }, createdAt: '2026-05-04T22:00:00' },
        { id: 2, content: '深夜食堂的牛肉面太诱人了！', author: { nickname: '夜猫子' }, createdAt: '2026-05-04T23:45:00' }
      ],
      [
        { id: 1, content: '奥森南园跑道确实舒服，树荫多不晒', author: { nickname: '跑步达人' }, createdAt: '2026-05-08T07:30:00' },
        { id: 2, content: '哈哈白鹭也太治愈了', author: { nickname: '自然爱好者' }, createdAt: '2026-05-08T08:00:00' }
      ],
      [
        { id: 1, content: '雍和宫工作日去确实安静，能感受到禅意', author: { nickname: '佛系青年' }, createdAt: '2026-04-16T10:30:00' },
        { id: 2, content: '五道营胡同的小店也很有意思', author: { nickname: '胡同探索者' }, createdAt: '2026-04-17T15:00:00' }
      ],
      [
        { id: 1, content: '圆明园春天真的很美，野花开满了废墟间', author: { nickname: '春日记录者' }, createdAt: '2026-04-23T11:00:00' },
        { id: 2, content: '福海划船能看到黑天鹅吗？', author: { nickname: '动物观察家' }, createdAt: '2026-04-24T09:30:00' }
      ]
    ]
    const idx = ((props.id - 1) % commentPool.length + commentPool.length) % commentPool.length
    comments.value = commentPool[idx]
  }
}

function toggleLike() {
  if (!ensureAuth()) return
  liked.value = !liked.value
  const delta = liked.value ? 1 : -1
  diary.value.stats = { ...diary.value.stats, likes: (diary.value.stats?.likes || 0) + delta }
  // Attempt API call in background, don't revert on failure in demo mode
  if (liked.value) {
    tourismApi.likeDiary(props.id).catch(() => {})
  } else {
    tourismApi.unlikeDiary(props.id).catch(() => {})
  }
}

function toggleBookmark() {
  if (!ensureAuth()) return
  bookmarked.value = !bookmarked.value
  const delta = bookmarked.value ? 1 : -1
  diary.value.bookmarkCount = (diary.value.bookmarkCount || 0) + delta
  if (bookmarked.value) {
    tourismApi.bookmarkDiary(props.id).catch(() => {})
  } else {
    tourismApi.unbookmarkDiary(props.id).catch(() => {})
  }
}

const hasRatedBefore = ref(false)

function rateDiary(score) {
  if (!ensureAuth()) return
  const oldScore = userRating.value
  userRating.value = score

  // Only increment count on first rating; subsequent ratings just update score
  const count = diary.value.ratingCount || 0
  const currentAvg = diary.value.ratingScore || 0

  if (!hasRatedBefore.value) {
    // First time rating: add new score to average
    const newCount = count + 1
    const newAvg = (currentAvg * count + score) / newCount
    diary.value.ratingScore = newAvg
    diary.value.ratingCount = newCount
    hasRatedBefore.value = true
  } else {
    // Re-rating: replace old score in average calculation
    if (count > 0) {
      const totalWithoutOld = currentAvg * count - oldScore
      const newAvg = (totalWithoutOld + score) / count
      diary.value.ratingScore = newAvg
    } else {
      diary.value.ratingScore = score
    }
  }

  tourismApi.rateDiary(props.id, score).catch(() => {})
}

function submitComment() {
  if (!newComment.value.trim()) return
  if (!ensureAuth()) return
  const content = newComment.value.trim()
  // Optimistic push
  comments.value.push({
    id: Date.now(),
    content,
    author: { nickname: diaryStore.user.nickname },
    createdAt: new Date().toISOString()
  })
  diary.value.stats = { ...diary.value.stats, comments: (diary.value.stats?.comments || 0) + 1 }
  newComment.value = ''
  tourismApi.createComment(props.id, { content }).catch(() => {})
}

function formatTime(time) {
  if (!time) return ''
  return time.slice(0, 16).replace('T', ' ')
}

onMounted(() => {
  loadDiary()
  loadComments()
})
</script>
