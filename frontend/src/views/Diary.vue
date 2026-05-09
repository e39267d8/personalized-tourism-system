<template>
  <div>
    <!-- Header: Title + Search & Sort -->
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold text-slate-900">日记广场</h1>
      <div class="flex items-center gap-3">
        <input
          v-model="query"
          type="text"
          placeholder="搜索日记..."
          class="w-40 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500/40 focus:border-teal-500"
          @input="onSearch"
        />
        <select
          v-model="sort"
          class="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500/40"
          @change="onSortChange"
        >
          <option value="popular">最受欢迎</option>
          <option value="latest">最新发布</option>
          <option value="rating">评分最高</option>
        </select>
      </div>
    </div>

    <!-- Main Layout: Grid + Sidebar same height, pagination separate below -->
    <div class="flex gap-6 items-stretch">
      <!-- Left: 3-column diary cards grid, fixed 2-row height -->
      <div class="flex-1 min-w-0 diary-grid">
          <article
            v-for="diary in pagedDiaries"
            :key="diary.id"
            class="cursor-pointer group"
            @click="$router.push('/diary/' + diary.id)"
          >
            <div class="rounded-xl overflow-hidden bg-white border border-slate-100 shadow-sm hover:shadow-md transition-shadow duration-300 h-full flex flex-col scale-card">
              <div class="relative overflow-hidden aspect-[4/3]">
                <img
                  :src="diary.cover || (diary.images && diary.images[0])"
                  :alt="diary.title"
                  class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                  @error="handleImageError($event, diary)"
                />
                <!-- Pin badge for justPublished -->
                <div v-if="isJustPublished(diary)" class="absolute top-2 left-2 bg-teal-600/90 text-white text-[10px] px-1.5 py-0.5 rounded">
                  刚发布
                </div>
              </div>
              <div class="px-3 py-3 flex flex-col gap-2">
                <h3 class="text-[15px] font-semibold text-slate-800 leading-snug line-clamp-2">{{ diary.title }}</h3>
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <div class="w-5 h-5 rounded-full bg-gradient-to-br from-teal-400 to-teal-600 flex items-center justify-center">
                      <span class="text-white text-[10px] font-medium">{{ (diary.author?.nickname || '旅')[0] }}</span>
                    </div>
                    <span class="text-xs text-slate-500 truncate max-w-[80px]">{{ diary.author?.nickname || '旅行者' }}</span>
                  </div>
                  <div class="flex items-center gap-2.5">
                    <span v-if="diary.ratingScore" class="flex items-center gap-0.5">
                      <svg class="w-3.5 h-3.5 text-amber-500" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>
                      <span class="text-xs text-amber-700">{{ diary.ratingScore.toFixed(1) }}</span>
                    </span>
                    <span class="flex items-center gap-0.5 text-xs text-slate-400">
                      <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
                      {{ diary.stats?.likes || 0 }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </article>
      </div>

      <!-- Right Sidebar: stretches to same height as grid, button at bottom -->
      <div class="hidden lg:flex flex-col w-36 flex-shrink-0">
        <!-- Artistic Panel: no border, seamless background -->
        <div class="relative w-full h-full flex flex-col items-center overflow-hidden rounded-xl bg-gradient-to-b from-transparent via-slate-50/30 to-slate-50/50 p-4">
          
          <!-- Blurred scattered Chinese characters (Wang Fei style) -->
          <div class="absolute inset-0 overflow-hidden pointer-events-none select-none">
            <span class="char-float" style="top:6%;left:12%;font-size:2.5rem;opacity:0.07;transform:rotate(-12deg)">行</span>
            <span class="char-float" style="top:14%;right:8%;font-size:1.8rem;opacity:0.10;transform:rotate(8deg)">远</span>
            <span class="char-float" style="top:25%;left:55%;font-size:3rem;opacity:0.05;transform:rotate(-5deg)">思</span>
            <span class="char-float" style="top:36%;left:5%;font-size:2rem;opacity:0.09;transform:rotate(15deg)">梦</span>
            <span class="char-float" style="top:47%;right:12%;font-size:2.2rem;opacity:0.06;transform:rotate(-8deg)">归</span>
            <span class="char-float" style="top:58%;left:20%;font-size:1.6rem;opacity:0.10;transform:rotate(12deg)">途</span>
            <span class="char-float" style="top:69%;right:25%;font-size:2.8rem;opacity:0.04;transform:rotate(-3deg)">诗</span>
            <span class="char-float" style="top:80%;left:8%;font-size:1.4rem;opacity:0.08;transform:rotate(6deg)">记</span>
            <!-- Partial strokes - positioned to NOT overlap with full characters above -->
            <span class="stroke-float" style="top:3%;right:30%;opacity:0.06;transform:rotate(-20deg)">丿</span>
            <span class="stroke-float" style="top:19%;left:8%;opacity:0.05;transform:rotate(10deg)">㇏</span>
            <span class="stroke-float" style="top:31%;right:5%;opacity:0.06;transform:rotate(-15deg)">丶</span>
            <span class="stroke-float" style="top:42%;left:55%;opacity:0.04;transform:rotate(25deg)">㇀</span>
            <span class="stroke-float" style="top:53%;left:5%;opacity:0.05;transform:rotate(-8deg)">丨</span>
            <span class="stroke-float" style="top:64%;right:5%;opacity:0.05;transform:rotate(18deg)">㇇</span>
            <span class="stroke-float" style="top:74%;left:50%;opacity:0.06;transform:rotate(-12deg)">乀</span>
            <span class="stroke-float" style="top:87%;right:35%;opacity:0.05;transform:rotate(5deg)">㇂</span>
          </div>

          <!-- Floating pixel squares - denser at bottom, sparser at top -->
          <div class="absolute inset-0 pointer-events-none">
            <span v-for="sq in floatingSquares" :key="sq.id" class="pixel-sq" :style="sq.style" />
          </div>

          <!-- Literary quote (vertical text) - top aligned, shifted down 3 chars -->
          <div class="relative z-10 pt-16">
            <div class="flex flex-row-reverse gap-2">
              <p class="writing-vertical text-lg text-slate-700 tracking-[0.25em] leading-relaxed" style="font-family: 'Noto Serif SC', 'SimSun', serif;">{{ quoteLines[0] }}</p>
              <p class="writing-vertical text-lg text-slate-700 tracking-[0.25em] leading-relaxed" style="font-family: 'Noto Serif SC', 'SimSun', serif;">{{ quoteLines[1] }}</p>
            </div>
          </div>

          <!-- Spacer pushes button to bottom -->
          <div class="flex-1"></div>

          <!-- Pixel-mosaic Write Diary button - bottom aligned with grid bottom -->
          <router-link to="/diary/new" class="relative z-10 group mb-0">
            <div class="w-20 h-20 rounded-lg bg-gradient-to-br from-teal-700 to-teal-900 flex items-center justify-center shadow-lg group-hover:shadow-xl group-hover:scale-105 transition-all duration-300 pixel-btn">
              <!-- Pixel decoration squares around button -->
              <span class="absolute -top-1.5 -left-1.5 w-3 h-3 bg-teal-400/60 rounded-sm" />
              <span class="absolute -top-2 right-2 w-2 h-2 bg-teal-300/50 rounded-sm" />
              <span class="absolute top-1 -right-1 w-2.5 h-2.5 bg-teal-500/40 rounded-sm" />
              <span class="absolute -bottom-1 left-3 w-2 h-2 bg-teal-400/50 rounded-sm" />
              <span class="absolute -bottom-2 -right-1.5 w-3 h-3 bg-teal-300/40 rounded-sm" />
              <span class="absolute -top-3 left-4 w-2 h-2 bg-teal-500/30 rounded-sm" />
              <span class="absolute top-3 -left-2 w-2.5 h-2.5 bg-teal-400/35 rounded-sm" />
              <span class="absolute -bottom-3 right-1 w-2 h-2 bg-teal-500/45 rounded-sm" />
              <span class="absolute bottom-2 -left-2 w-1.5 h-1.5 bg-teal-300/55 rounded-sm" />
              <svg class="w-7 h-7 text-white relative z-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/></svg>
            </div>
            <p class="text-xs text-slate-600 text-center mt-2 font-medium group-hover:text-teal-700 transition">写日记</p>
          </router-link>
        </div>
      </div>
    </div>

    <!-- Pagination - below the flex container, independent of sidebar -->
    <div class="flex items-center justify-center gap-2 mt-6">
      <button
        @click="prevPage"
        :disabled="currentPage <= 1"
        class="px-3 py-1.5 rounded-lg text-sm border border-slate-200 text-slate-600 hover:bg-slate-50 transition disabled:opacity-40 disabled:cursor-not-allowed"
      >上一页</button>
      <button
        v-for="page in totalPages"
        :key="page"
        @click="currentPage = page"
        :class="['w-8 h-8 rounded-lg text-sm font-medium transition', page === currentPage ? 'bg-teal-700 text-white' : 'text-slate-600 hover:bg-slate-100']"
      >{{ page }}</button>
      <button
        @click="nextPage"
        :disabled="currentPage >= totalPages"
        class="px-3 py-1.5 rounded-lg text-sm border border-slate-200 text-slate-600 hover:bg-slate-50 transition disabled:opacity-40 disabled:cursor-not-allowed"
      >下一页</button>
    </div>

    <!-- Mobile FAB -->
    <router-link
      to="/diary/new"
      class="lg:hidden fixed bottom-6 right-6 w-14 h-14 rounded-lg bg-teal-700 text-white shadow-lg hover:bg-teal-800 flex items-center justify-center z-30 transition"
    >
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/></svg>
    </router-link>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { tourismApi } from '@/services/tourismApi'
import { diaries as demoDiaries } from '@/data/demoData'
import { diaryStore } from '@/stores/diaryStore'
import { fallbackImageForSpot } from '@/utils/images'

const PAGE_SIZE = 6

const diaries = ref([])
const query = ref('')
const sort = ref(localStorage.getItem('diary_sort') || 'popular')
const currentPage = ref(1)
const pinJustPublished = ref(!!diaryStore.justPublished)

// Travel literary quotes pool - refreshes each visit
const quotes = [
  ['人间烟火气', '最抚凡人心'],
  ['此心安处', '便是吾乡'],
  ['山河远阔', '人间星河'],
  ['一期一会', '世当珍惜'],
  ['行到水穷处', '坐看云起时'],
  ['目之所及', '皆是回忆'],
  ['生活明朗', '万物可爱'],
  ['浮生若梦', '为欢几何'],
  ['岁月不居', '时节如流'],
  ['且将新火', '试新茶'],
  ['清风徐来', '水波不兴'],
  ['落霞与孤鹜', '秋水共长天'],
  ['世界是一本书', '不旅行只读了一页'],
  ['身未动', '心已远'],
  ['一花一世界', '一叶一菩提'],
  ['人生如逆旅', '我亦是行人'],
  ['读万卷书', '行万里路'],
  ['天地者万物之逆旅', '光阴者百代之过客'],
  ['白日放歌须纵酒', '青春作伴好还乡'],
  ['不到长城非好汉', '屈指行程二万'],
  ['莫愁前路无知己', '天下谁人不识君'],
  ['仗剑走天涯', '看一看世界繁华'],
  ['心之所向', '素履以往'],
  ['既见君子', '云胡不喜'],
  ['旅行是从自己活腻', '的地方到别人活腻的地方'],
  ['最好的时光', '在路上'],
  ['要么读书', '要么旅行'],
  ['生活不止眼前的苟且', '还有诗和远方'],
  ['走过的路', '都算数'],
  ['每一步都是远方', '每一眼都是风景']
]
const quoteLines = ref(quotes[Math.floor(Math.random() * quotes.length)])

// Generate floating pixel squares - denser at bottom, sparser toward top
const floatingSquares = computed(() => {
  const squares = []
  const total = 24
  for (let i = 0; i < total; i++) {
    const size = 3 + Math.random() * 7
    // Exponential distribution: more squares toward the bottom
    const rawTop = Math.pow(Math.random(), 0.5) * 100
    const top = Math.min(92, Math.max(5, rawTop))
    squares.push({
      id: i,
      style: {
        position: 'absolute',
        top: top + '%',
        left: (5 + Math.random() * 80) + '%',
        width: size + 'px',
        height: size + 'px',
        background: `rgba(13, 148, 136, ${0.08 + Math.random() * 0.18})`,
        borderRadius: '2px',
        transform: `rotate(${Math.random() * 45 - 22}deg)`
      }
    })
  }
  return squares
})

function isJustPublished(diary) {
  return diaryStore.justPublished && diary.id === diaryStore.justPublished.id
}

const sortedDiaries = computed(() => {
  let list = [...diaries.value]

  // Separate justPublished from the list for pinning
  let pinned = null
  if (pinJustPublished.value && diaryStore.justPublished) {
    const idx = list.findIndex(d => d.id === diaryStore.justPublished.id)
    if (idx >= 0) {
      pinned = list.splice(idx, 1)[0]
    } else {
      pinned = diaryStore.justPublished
    }
  } else if (diaryStore.justPublished) {
    const exists = list.some(d => d.id === diaryStore.justPublished.id)
    if (!exists) list.push(diaryStore.justPublished)
  }

  // Filter by search
  if (query.value.trim()) {
    const q = query.value.toLowerCase()
    list = list.filter(d =>
      d.title.toLowerCase().includes(q) ||
      (d.tags || []).some(tag => tag.toLowerCase().includes(q)) ||
      (d.excerpt || '').toLowerCase().includes(q)
    )
  }

  // Sort
  if (sort.value === 'rating') {
    list.sort((a, b) => (b.ratingScore || 0) - (a.ratingScore || 0))
  } else if (sort.value === 'popular') {
    list.sort((a, b) => ((b.stats?.likes || 0) + (b.stats?.comments || 0) * 2) - ((a.stats?.likes || 0) + (a.stats?.comments || 0) * 2))
  } else {
    list.sort((a, b) => (b.date || '').localeCompare(a.date || ''))
  }

  // Prepend pinned justPublished to absolute top
  if (pinned) {
    list.unshift(pinned)
  }

  return list
})

const totalPages = computed(() => Math.max(1, Math.ceil(sortedDiaries.value.length / PAGE_SIZE)))

const pagedDiaries = computed(() => {
  const start = (currentPage.value - 1) * PAGE_SIZE
  return sortedDiaries.value.slice(start, start + PAGE_SIZE)
})

function prevPage() {
  if (currentPage.value > 1) currentPage.value--
}

function nextPage() {
  if (currentPage.value < totalPages.value) currentPage.value++
}

function onSearch() {
  currentPage.value = 1
  if (query.value.trim()) {
    pinJustPublished.value = false
  }
}

function onSortChange() {
  localStorage.setItem('diary_sort', sort.value)
  currentPage.value = 1
  pinJustPublished.value = false
}

function handleImageError(event, diary) {
  if (event?.target) {
    event.target.onerror = null
    event.target.src = fallbackImageForSpot({ name: diary.title, category: diary.location, tags: diary.tags })
  }
}

async function loadDiaries() {
  try {
    const data = await tourismApi.diaries({ sort: sort.value })
    diaries.value = data.items || data || []
    if (diaries.value.length === 0) diaries.value = demoDiaries
  } catch {
    diaries.value = demoDiaries
  }
}

onMounted(loadDiaries)
</script>

<style scoped>
.writing-vertical {
  writing-mode: vertical-rl;
  text-orientation: mixed;
}

/* Fixed 2-row grid: always maintains 2 rows regardless of content count */
.diary-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-template-rows: repeat(2, auto);
  gap: 1rem;
  min-height: 580px;
  align-content: start;
}

@media (max-width: 1023px) {
  .diary-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 639px) {
  .diary-grid {
    grid-template-columns: 1fr;
  }
}

.scale-card {
  transform: scale(0.92);
  transform-origin: top left;
}

.char-float {
  position: absolute;
  font-family: 'Noto Serif SC', 'SimSun', 'KaiTi', serif;
  color: #334155;
  filter: blur(0.5px);
  user-select: none;
}

.stroke-float {
  position: absolute;
  font-family: 'Noto Serif SC', 'KaiTi', serif;
  font-size: 3.5rem;
  color: #64748b;
  user-select: none;
}

.pixel-sq {
  display: block;
}

.pixel-btn {
  position: relative;
  image-rendering: pixelated;
}
</style>
