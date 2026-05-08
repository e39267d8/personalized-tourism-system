<template>
  <div class="grid gap-6 xl:grid-cols-[0.85fr_1.15fr]">
    <section class="space-y-6">
      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-center justify-between gap-4">
          <div>
            <h1 class="text-2xl font-bold text-slate-950">旅游日记</h1>
            <p class="mt-2 text-sm leading-6 text-slate-500">记录路线、预算、体验和图片，后续可接 AIGC 润色与多媒体生成。</p>
          </div>
          <button @click="startNewDiary" class="rounded-md bg-slate-900 px-3 py-2 text-sm font-semibold text-white hover:bg-slate-800">新建</button>
        </div>

        <div class="mt-5">
          <input v-model="query" type="search" placeholder="搜索标题、标签或心情" class="w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-teal-700 focus:outline-none">
        </div>
      </div>

      <div class="space-y-3">
        <article
          v-for="diary in filteredDiaries"
          :key="diary.id"
          @click="selectDiary(diary)"
          :class="[
            'cursor-pointer overflow-hidden rounded-md border bg-white transition hover:border-slate-400',
            selectedDiary?.id === diary.id ? 'border-slate-900 ring-2 ring-slate-900/10' : 'border-slate-200'
          ]"
        >
          <img :src="diary.cover" :alt="diary.title" class="h-36 w-full object-cover">
          <div class="p-4">
            <div class="flex items-start justify-between gap-3">
              <h2 class="font-semibold text-slate-950">{{ diary.title }}</h2>
              <span class="rounded-md bg-teal-50 px-2 py-1 text-xs font-semibold text-teal-800">{{ diary.mood }}</span>
            </div>
            <p class="mt-2 line-clamp-2 text-sm leading-6 text-slate-500">{{ diary.excerpt }}</p>
            <div class="mt-3 flex flex-wrap gap-2">
              <span v-for="tag in diary.tags" :key="tag" class="rounded-md bg-slate-100 px-2 py-1 text-xs text-slate-600">{{ tag }}</span>
            </div>
          </div>
        </article>
      </div>
    </section>

    <section class="space-y-6">
      <div class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 class="text-lg font-semibold text-slate-950">日记编辑器</h2>
            <p class="mt-1 text-sm text-slate-500">当前为本地演示编辑，保存后可展示在列表中。</p>
          </div>
          <div class="flex gap-2">
            <button @click="generateSummary" class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">生成摘要</button>
          <button @click="saveDiary" class="rounded-md bg-teal-700 px-3 py-2 text-sm font-semibold text-white hover:bg-teal-800">{{ saving ? '保存中' : '保存' }}</button>
          </div>
        </div>

        <div class="mt-5 grid gap-4">
          <input v-model="draft.title" class="rounded-md border border-slate-300 px-3 py-2 text-lg font-semibold focus:border-teal-700 focus:outline-none" placeholder="日记标题">
          <div class="grid gap-4 md:grid-cols-3">
            <input v-model="draft.date" type="date" class="rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-teal-700 focus:outline-none">
            <input v-model="draft.distance" class="rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-teal-700 focus:outline-none" placeholder="路线距离">
            <input v-model="draft.mood" class="rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-teal-700 focus:outline-none" placeholder="心情">
          </div>
          <input v-model="tagInput" class="rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-teal-700 focus:outline-none" placeholder="标签，用逗号分隔">
          <textarea v-model="draft.excerpt" rows="7" class="resize-none rounded-md border border-slate-300 px-3 py-2 text-sm leading-6 focus:border-teal-700 focus:outline-none" placeholder="写下今天的路线、花费、体验和建议"></textarea>
        </div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <h2 class="text-lg font-semibold text-slate-950">预览</h2>
        <div class="mt-4 overflow-hidden rounded-md border border-slate-200">
          <img :src="draft.cover || diaries[0].cover" alt="日记封面" class="h-52 w-full object-cover">
          <div class="p-5">
            <div class="flex flex-wrap items-start justify-between gap-3">
              <div>
                <h3 class="text-2xl font-bold text-slate-950">{{ draft.title || '未命名日记' }}</h3>
                <div class="mt-2 text-sm text-slate-500">{{ draft.date }} · {{ draft.distance }} · {{ draft.mood }}</div>
              </div>
              <span class="rounded-md bg-amber-50 px-3 py-1 text-sm font-semibold text-amber-800">草稿</span>
            </div>
            <p class="mt-4 whitespace-pre-line text-sm leading-7 text-slate-600">{{ draft.excerpt }}</p>
            <div class="mt-4 flex flex-wrap gap-2">
              <span v-for="tag in draftTags" :key="tag" class="rounded-md bg-teal-50 px-2 py-1 text-xs font-medium text-teal-800">{{ tag }}</span>
            </div>
          </div>
        </div>
      </div>

      <div class="rounded-md border border-slate-200 bg-white p-5">
        <h2 class="text-lg font-semibold text-slate-950">后续修改空间</h2>
        <div class="mt-4 grid gap-3 md:grid-cols-3">
          <div class="rounded-md bg-slate-50 p-4 text-sm text-slate-600">接入 `POST /api/v1/diaries` 保存真实游记。</div>
          <div class="rounded-md bg-slate-50 p-4 text-sm text-slate-600">接入 AIGC 标题、摘要、图片说明生成。</div>
          <div class="rounded-md bg-slate-50 p-4 text-sm text-slate-600">关联路线规划和实际预算支出。</div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { diaries as initialDiaries } from '@/data/demoData'
import { tourismApi } from '@/services/tourismApi'

const diaries = ref(initialDiaries.map(item => ({ ...item })))
const selectedDiary = ref(diaries.value[0])
const query = ref('')
const tagInput = ref(selectedDiary.value.tags.join('，'))
const draft = ref({ ...selectedDiary.value })
const saving = ref(false)

const filteredDiaries = computed(() => {
  const keyword = query.value.trim().toLowerCase()
  if (!keyword) return diaries.value
  return diaries.value.filter(diary => {
    return [diary.title, diary.mood, diary.excerpt, ...diary.tags].join(' ').toLowerCase().includes(keyword)
  })
})

const draftTags = computed(() => tagInput.value.split(/[，,]/).map(tag => tag.trim()).filter(Boolean))

const selectDiary = (diary) => {
  selectedDiary.value = diary
  draft.value = { ...diary }
  tagInput.value = diary.tags.join('，')
}

const startNewDiary = () => {
  selectedDiary.value = null
  draft.value = {
    id: Date.now(),
    title: '',
    date: new Date().toISOString().slice(0, 10),
    distance: '',
    mood: '',
    cover: initialDiaries[1].cover,
    tags: [],
    excerpt: '',
    stats: { views: 0, likes: 0, comments: 0 }
  }
  tagInput.value = ''
}

const generateSummary = () => {
  const run = async () => {
    try {
      const response = await tourismApi.summarizeDiary({ content: draft.value.excerpt || draft.value.title })
      draft.value.excerpt = response.summary || draft.value.excerpt
    } catch (error) {
      const tags = draftTags.value.length ? `关键词：${draftTags.value.join('、')}。` : ''
      draft.value.excerpt = draft.value.excerpt || `这是一条围绕 ${draft.value.title || '本次旅行'} 的路线记录，包含行程亮点、预算感受和后续推荐依据。${tags}`
    }
  }
  run()
}

const saveDiary = async () => {
  saving.value = true
  const nextDiary = { ...draft.value, tags: draftTags.value }
  try {
    const response = selectedDiary.value
      ? await tourismApi.updateDiary(nextDiary.id, nextDiary)
      : await tourismApi.createDiary(nextDiary)
    const saved = response.id ? response : nextDiary
    const index = diaries.value.findIndex(item => item.id === saved.id)
    if (index >= 0) diaries.value[index] = saved
    else diaries.value.unshift(saved)
    selectedDiary.value = saved
    draft.value = { ...saved }
  } catch (error) {
    const index = diaries.value.findIndex(item => item.id === nextDiary.id)
    if (index >= 0) diaries.value[index] = nextDiary
    else diaries.value.unshift(nextDiary)
    selectedDiary.value = nextDiary
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  try {
    const response = await tourismApi.diaries()
    if (response.items?.length) {
      diaries.value = response.items
      selectDiary(diaries.value[0])
    }
  } catch (error) {
    // Keep local demo data when the API is not running.
  }
})
</script>
