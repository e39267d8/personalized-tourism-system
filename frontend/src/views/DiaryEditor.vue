<template>
  <div>
    <!-- Back navigation -->
    <div class="mb-6">
      <router-link to="/diary" class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-700 transition">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
        返回广场
      </router-link>
    </div>

    <!-- Postcard-style Editor: Left images, Right writing -->
    <div class="flex flex-col lg:flex-row gap-0 rounded-2xl overflow-hidden bg-white shadow-sm border border-slate-100">
      <!-- Left: Image upload area (visual/photo side) -->
      <div class="relative lg:w-[42%] bg-gradient-to-br from-slate-50 to-stone-50 p-5 lg:p-6 flex flex-col">
        <!-- Cover image preview -->
        <div v-if="form.images.length" class="relative rounded-xl overflow-hidden aspect-[4/3] mb-4 shadow-inner">
          <img :src="form.images[currentPreviewIdx]" class="w-full h-full object-cover" />
          <template v-if="form.images.length > 1">
            <button @click="prevPreview" class="absolute left-2 top-1/2 -translate-y-1/2 w-7 h-7 rounded-full bg-white/80 backdrop-blur flex items-center justify-center shadow-sm">
              <svg class="w-3.5 h-3.5 text-slate-700" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
            </button>
            <button @click="nextPreview" class="absolute right-2 top-1/2 -translate-y-1/2 w-7 h-7 rounded-full bg-white/80 backdrop-blur flex items-center justify-center shadow-sm">
              <svg class="w-3.5 h-3.5 text-slate-700" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </button>
          </template>
          <div class="absolute bottom-2 right-2 px-2 py-0.5 rounded-full bg-black/40 text-white text-xs">
            {{ currentPreviewIdx + 1 }}/{{ form.images.length }}
          </div>
        </div>

        <!-- Image thumbnails grid -->
        <div class="grid grid-cols-4 gap-2">
          <div
            v-for="(img, idx) in form.images"
            :key="idx"
            class="relative aspect-square rounded-lg overflow-hidden border-2 cursor-pointer transition-all"
            :class="idx === currentPreviewIdx ? 'border-teal-500 shadow-md' : 'border-transparent opacity-75 hover:opacity-100'"
            @click="currentPreviewIdx = idx"
          >
            <img :src="img" class="w-full h-full object-cover" />
            <button
              @click.stop="removeImage(idx)"
              class="absolute -top-0.5 -right-0.5 w-4 h-4 rounded-full bg-rose-500 text-white flex items-center justify-center opacity-0 hover:opacity-100 transition text-xs"
            >&times;</button>
          </div>
          <label
            v-if="form.images.length < 9"
            class="aspect-square rounded-lg border-2 border-dashed border-slate-200 flex flex-col items-center justify-center cursor-pointer hover:border-teal-400 hover:bg-teal-50/50 transition"
          >
            <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            <span class="text-[10px] text-slate-400 mt-0.5">{{ form.images.length }}/9</span>
            <input type="file" accept="image/*" multiple class="hidden" @change="handleImageUpload" />
          </label>
        </div>

        <!-- Empty state -->
        <div v-if="!form.images.length" class="flex-1 flex flex-col items-center justify-center py-12">
          <label class="flex flex-col items-center cursor-pointer group">
            <div class="w-16 h-16 rounded-full bg-slate-100 group-hover:bg-teal-50 flex items-center justify-center transition mb-3">
              <svg class="w-7 h-7 text-slate-400 group-hover:text-teal-500 transition" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            </div>
            <span class="text-sm text-slate-500 group-hover:text-teal-600 transition">添加旅行照片</span>
            <span class="text-xs text-slate-400 mt-1">支持多张上传，第一张为封面</span>
            <input type="file" accept="image/*" multiple class="hidden" @change="handleImageUpload" />
          </label>
        </div>

        <!-- Location & Mood (bottom of photo side) -->
        <div class="mt-auto pt-4 flex items-center gap-2">
          <div class="flex-1 flex items-center gap-1.5 px-3 py-2 rounded-lg bg-white/80 border border-slate-150">
            <svg class="w-4 h-4 text-teal-500 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
            <input v-model="form.location" type="text" placeholder="添加地点" class="flex-1 text-sm bg-transparent outline-none text-slate-700 placeholder:text-slate-400" />
          </div>
          <!-- Mood selector -->
          <div class="relative">
            <button
              @click="showMoodPicker = !showMoodPicker"
              class="flex items-center gap-1.5 px-3 py-2 rounded-lg bg-white/80 border border-slate-150 hover:bg-white transition"
            >
              <span class="text-base">{{ form.mood || '😊' }}</span>
              <span class="text-xs text-slate-500">{{ form.moodLabel || '心情' }}</span>
            </button>
            <div v-if="showMoodPicker" class="absolute bottom-full mb-2 right-0 w-48 bg-white rounded-xl shadow-lg border border-slate-100 p-2 z-20">
              <button
                v-for="m in moodOptions"
                :key="m.emoji"
                @click="selectMood(m)"
                class="w-full flex items-center gap-2 px-2 py-1.5 rounded-lg hover:bg-slate-50 transition text-left"
              >
                <span class="text-base">{{ m.emoji }}</span>
                <span class="text-sm text-slate-700">{{ m.label }}</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Center: Dashed divider (desktop) -->
      <div class="hidden lg:block w-px border-l-2 border-dashed border-slate-200 my-8" />

      <!-- Right: Writing area (iPhone Notes style) -->
      <div class="lg:w-[58%] p-5 lg:p-8 flex flex-col min-h-[520px]">
        <!-- Title (large, clean, like Notes app) -->
        <input
          v-model="form.title"
          type="text"
          placeholder="标题"
          class="w-full text-2xl font-bold text-slate-900 placeholder:text-slate-300 border-none outline-none mb-1 bg-transparent"
        />

        <!-- Date -->
        <div class="flex items-center gap-2 mb-4 text-xs text-slate-400">
          <input v-model="form.date" type="date" class="bg-transparent border-none outline-none text-xs text-slate-500 cursor-pointer" />
        </div>

        <!-- Tiptap Editor (iPhone Notes style) -->
        <div class="flex-1 flex flex-col">
          <!-- iPhone Notes style toolbar -->
          <div v-if="editor" class="border-t border-b border-slate-100 py-2 px-1 mb-3 flex flex-col gap-2">
            <!-- Row 1: Block format (like Notes: 标题/小标题/副标题/正文) -->
            <div class="flex items-center gap-1">
              <button
                @click="editor.chain().focus().toggleHeading({ level: 1 }).run()"
                :class="formatBtnClass(editor.isActive('heading', { level: 1 }))"
              >标题</button>
              <button
                @click="editor.chain().focus().toggleHeading({ level: 2 }).run()"
                :class="formatBtnClass(editor.isActive('heading', { level: 2 }))"
              >小标题</button>
              <button
                @click="editor.chain().focus().toggleHeading({ level: 3 }).run()"
                :class="formatBtnClass(editor.isActive('heading', { level: 3 }))"
              >副标题</button>
              <button
                @click="editor.chain().focus().setParagraph().run()"
                :class="formatBtnClass(editor.isActive('paragraph') && !editor.isActive('heading'))"
              >正文</button>
            </div>
            <!-- Row 2: Inline format (B I U S) + lists + quote + emoji -->
            <div class="flex items-center gap-1">
              <button @click="editor.chain().focus().toggleBold().run()" :class="inlineBtnClass(editor.isActive('bold'))" title="加粗">
                <span class="font-bold">B</span>
              </button>
              <button @click="editor.chain().focus().toggleItalic().run()" :class="inlineBtnClass(editor.isActive('italic'))" title="斜体">
                <span class="italic">I</span>
              </button>
              <button @click="editor.chain().focus().toggleUnderline().run()" :class="inlineBtnClass(editor.isActive('underline'))" title="下划线">
                <span class="underline">U</span>
              </button>
              <button @click="editor.chain().focus().toggleStrike().run()" :class="inlineBtnClass(editor.isActive('strike'))" title="删除线">
                <span class="line-through">S</span>
              </button>
              <span class="w-px h-5 bg-slate-200 mx-1" />
              <button @click="editor.chain().focus().toggleBulletList().run()" :class="inlineBtnClass(editor.isActive('bulletList'))" title="无序列表">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
              </button>
              <button @click="editor.chain().focus().toggleOrderedList().run()" :class="inlineBtnClass(editor.isActive('orderedList'))" title="有序列表">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h10M7 16h10M4 8h.01M4 12h.01M4 16h.01"/></svg>
              </button>
              <button @click="editor.chain().focus().toggleBlockquote().run()" :class="inlineBtnClass(editor.isActive('blockquote'))" title="引用">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"/></svg>
              </button>
              <span class="w-px h-5 bg-slate-200 mx-1" />
              <!-- Emoji button -->
              <div class="relative">
                <button @click="showEmojiPicker = !showEmojiPicker" class="w-7 h-7 rounded-lg flex items-center justify-center text-slate-500 hover:bg-slate-100 transition" title="表情">
                  <span class="text-base">😊</span>
                </button>
                <div v-if="showEmojiPicker" class="absolute top-full mt-1 left-0 w-64 bg-white rounded-xl shadow-lg border border-slate-100 p-3 z-30">
                  <div class="grid grid-cols-8 gap-1 max-h-40 overflow-y-auto">
                    <button
                      v-for="emoji in emojiList"
                      :key="emoji"
                      @click="insertEmoji(emoji)"
                      class="w-7 h-7 flex items-center justify-center rounded hover:bg-slate-100 transition text-base"
                    >{{ emoji }}</button>
                  </div>
                </div>
              </div>
              <span class="w-px h-5 bg-slate-200 mx-1" />
              <button @click="editor.chain().focus().undo().run()" class="w-7 h-7 rounded-lg flex items-center justify-center text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition" title="撤销">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a5 5 0 015 5v2M3 10l4-4M3 10l4 4"/></svg>
              </button>
              <button @click="editor.chain().focus().redo().run()" class="w-7 h-7 rounded-lg flex items-center justify-center text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition" title="重做">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 10H11a5 5 0 00-5 5v2M21 10l-4-4M21 10l-4 4"/></svg>
              </button>
            </div>
          </div>

          <!-- Writing area -->
          <div class="flex-1 rounded-lg bg-slate-50/50 focus-within:bg-white focus-within:shadow-inner transition-all">
            <editor-content :editor="editor" class="px-4 py-3 prose-editor" />
          </div>
        </div>

        <!-- Tags (inline, lightweight) -->
        <div class="mt-4 pt-3 border-t border-slate-100">
          <div class="flex items-center gap-2">
            <span class="text-xs text-slate-400">#</span>
            <input
              v-model="tagInput"
              type="text"
              placeholder="添加标签，用逗号分隔"
              class="flex-1 text-sm bg-transparent border-none outline-none text-slate-600 placeholder:text-slate-300"
            />
          </div>
          <div v-if="parsedTags.length" class="mt-2 flex flex-wrap gap-1.5">
            <span v-for="tag in parsedTags" :key="tag" class="px-2 py-0.5 text-xs rounded-full bg-teal-50 text-teal-600">#{{ tag }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Action Bar (floating bottom) -->
    <div class="sticky bottom-4 mt-6 flex items-center justify-between rounded-xl bg-white/95 backdrop-blur border border-slate-100 px-5 py-3.5 shadow-lg">
      <span class="text-xs text-slate-400">
        {{ form.images.length }} 张图片 · {{ contentLength }} 字
      </span>
      <div class="flex items-center gap-2.5">
        <button
          @click="saveDraft"
          :disabled="saving"
          class="rounded-lg border border-slate-200 px-3.5 py-2 text-sm text-slate-600 hover:bg-slate-50 transition disabled:opacity-50"
        >
          {{ saving ? '保存中...' : '存草稿' }}
        </button>
        <button
          @click="openPreview"
          class="rounded-lg border border-teal-200 px-3.5 py-2 text-sm text-teal-700 hover:bg-teal-50 transition"
        >
          预览
        </button>
        <button
          @click="publishDiary"
          :disabled="saving"
          class="rounded-lg px-5 py-2 text-sm font-medium bg-teal-700 text-white hover:bg-teal-800 shadow-sm transition disabled:opacity-50"
        >
          发布
        </button>
      </div>
    </div>

    <!-- Preview Overlay -->
    <Teleport to="body">
      <div v-if="showPreview" class="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 lg:p-8" @click.self="closePreview">
        <div class="w-full max-w-5xl max-h-[90vh] overflow-y-auto rounded-2xl bg-slate-50 p-4 lg:p-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold text-slate-900">预览效果</h2>
            <button @click="closePreview" class="w-8 h-8 rounded-full bg-slate-200 hover:bg-slate-300 flex items-center justify-center transition">
              <svg class="w-4 h-4 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
            </button>
          </div>
          <DiaryPostcard :diary="previewDiary" />
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Underline from '@tiptap/extension-underline'
import Image from '@tiptap/extension-image'
import Placeholder from '@tiptap/extension-placeholder'
import DiaryPostcard from '@/components/DiaryPostcard.vue'
import { tourismApi } from '@/services/tourismApi'
import { diaries as demoDiaries } from '@/data/demoData'
import { diaryStore, setJustPublished } from '@/stores/diaryStore'

const props = defineProps({
  id: { type: Number, default: 0 }
})

const router = useRouter()

const form = ref({
  title: '',
  date: new Date().toISOString().slice(0, 10),
  location: '',
  mood: '',
  moodLabel: '',
  images: []
})
const tagInput = ref('')
const saving = ref(false)
const showPreview = ref(false)
const showMoodPicker = ref(false)
const showEmojiPicker = ref(false)
const currentPreviewIdx = ref(0)

// Mood options
const moodOptions = [
  { emoji: '😊', label: '开心' },
  { emoji: '🥰', label: '幸福' },
  { emoji: '😌', label: '惬意' },
  { emoji: '🤩', label: '震撼' },
  { emoji: '😋', label: '满足' },
  { emoji: '🧘', label: '宁静' },
  { emoji: '💪', label: '充实' },
  { emoji: '🌊', label: '治愈' },
  { emoji: '🤔', label: '感慨' },
  { emoji: '😴', label: '疲惫' }
]

// Emoji library
const emojiList = [
  '😀', '😁', '😂', '🤣', '😊', '😍', '🥰', '😘',
  '😋', '😎', '🤩', '😏', '😌', '🥺', '😢', '😭',
  '🌟', '✨', '🔥', '💯', '❤️', '💕', '💪', '👏',
  '🎉', '🎊', '🏔️', '🌊', '🌅', '🌄', '🏖️', '🗺️',
  '✈️', '🚗', '🚶', '🧳', '📷', '🎨', '🎵', '📝',
  '🌸', '🌺', '🍀', '🌈', '☀️', '🌙', '⭐', '🦋',
  '🍜', '🍣', '🍰', '☕', '🍵', '🥂', '🎁', '🏯'
]

function selectMood(m) {
  form.value.mood = m.emoji
  form.value.moodLabel = m.label
  showMoodPicker.value = false
}

function insertEmoji(emoji) {
  editor.value?.chain().focus().insertContent(emoji).run()
  showEmojiPicker.value = false
}

const parsedTags = computed(() =>
  tagInput.value.split(/[,，]/).map(t => t.trim()).filter(Boolean)
)

const contentLength = computed(() => {
  const text = editor.value?.getText() || ''
  return text.length
})

const previewDiary = computed(() => ({
  title: form.value.title || '未命名日记',
  content: editor.value?.getHTML() || '',
  images: form.value.images,
  cover: form.value.images[0] || '',
  date: form.value.date,
  location: form.value.location,
  mood: form.value.mood,
  tags: parsedTags.value,
  author: { nickname: diaryStore.user.nickname, avatar: '' }
}))

// Tiptap Editor
const editor = useEditor({
  extensions: [
    StarterKit,
    Underline,
    Image,
    Placeholder.configure({ placeholder: '开始写你的旅行故事...' })
  ],
  content: '',
  editorProps: {
    attributes: {
      class: 'outline-none min-h-[260px] text-slate-700 text-[15px] leading-8 tracking-wide'
    }
  }
})

function formatBtnClass(active) {
  return [
    'px-2.5 py-1 rounded-lg text-xs font-medium transition',
    active ? 'bg-amber-100 text-amber-800' : 'text-slate-600 hover:bg-slate-100'
  ]
}

function inlineBtnClass(active) {
  return [
    'w-7 h-7 rounded-lg flex items-center justify-center text-sm transition',
    active ? 'bg-slate-200 text-slate-900' : 'text-slate-500 hover:bg-slate-100'
  ]
}

// Image handling
function handleImageUpload(event) {
  const files = Array.from(event.target.files)
  const remaining = 9 - form.value.images.length
  const filesToProcess = files.slice(0, remaining)

  filesToProcess.forEach(file => {
    const reader = new FileReader()
    reader.onload = (e) => {
      form.value.images.push(e.target.result)
    }
    reader.readAsDataURL(file)
  })
  event.target.value = ''
}

function removeImage(idx) {
  form.value.images.splice(idx, 1)
  if (currentPreviewIdx.value >= form.value.images.length) {
    currentPreviewIdx.value = Math.max(0, form.value.images.length - 1)
  }
}

function prevPreview() {
  currentPreviewIdx.value = (currentPreviewIdx.value - 1 + form.value.images.length) % form.value.images.length
}

function nextPreview() {
  currentPreviewIdx.value = (currentPreviewIdx.value + 1) % form.value.images.length
}

// Preview
function openPreview() {
  showPreview.value = true
}

function closePreview() {
  showPreview.value = false
}

// Save & Publish
async function saveDraft() {
  await saveDiaryWithStatus(0)
}

async function publishDiary() {
  if (!form.value.title.trim()) {
    form.value.title = '未命名日记'
  }
  saving.value = true

  const payload = {
    title: form.value.title,
    content: editor.value?.getHTML() || '',
    date: form.value.date,
    location: form.value.location,
    images: form.value.images,
    tags: parsedTags.value,
    status: 1
  }

  // Build the diary object for plaza display
  const publishedDiary = {
    id: Date.now(),
    title: form.value.title,
    date: form.value.date,
    location: form.value.location,
    mood: form.value.moodLabel || '',
    cover: form.value.images[0] || '',
    images: form.value.images,
    tags: parsedTags.value,
    excerpt: (editor.value?.getText() || '').slice(0, 80) + '...',
    content: editor.value?.getHTML() || '',
    author: { nickname: diaryStore.user.nickname, avatar: '' },
    stats: { views: 0, likes: 0, comments: 0 },
    ratingScore: 0,
    ratingCount: 0,
    bookmarkCount: 0
  }

  // Try API
  try {
    if (props.id) {
      await tourismApi.updateDiary(props.id, payload)
      publishedDiary.id = props.id
    } else {
      const res = await tourismApi.createDiary(payload)
      if (res?.id) publishedDiary.id = res.id
    }
  } catch {
    // API failed (demo mode) - still show locally
  }

  // Set as justPublished so plaza shows it first
  setJustPublished(publishedDiary)
  saving.value = false

  // Navigate to plaza
  router.push('/diary')
}

async function saveDiaryWithStatus(status) {
  if (!form.value.title.trim()) {
    form.value.title = '未命名日记'
  }
  saving.value = true
  const payload = {
    title: form.value.title,
    content: editor.value?.getHTML() || '',
    date: form.value.date,
    location: form.value.location,
    images: form.value.images,
    tags: parsedTags.value,
    status
  }

  try {
    if (props.id) {
      await tourismApi.updateDiary(props.id, payload)
    } else {
      await tourismApi.createDiary(payload)
    }
  } catch {
    // Demo mode
  } finally {
    saving.value = false
  }
}

// Load existing diary for edit mode
async function loadExistingDiary() {
  if (!props.id) return
  try {
    const data = await tourismApi.diaryDetail(props.id)
    form.value.title = data.title || ''
    form.value.date = data.date || ''
    form.value.location = data.location || ''
    form.value.mood = data.mood || ''
    form.value.images = data.images || []
    tagInput.value = (data.tags || []).join(', ')
    if (editor.value && data.content) {
      editor.value.commands.setContent(data.content)
    }
  } catch {
    const demo = demoDiaries.find(d => d.id === props.id)
    if (demo) {
      form.value.title = demo.title
      form.value.date = demo.date
      form.value.location = demo.location || ''
      form.value.mood = demo.mood || ''
      form.value.images = demo.images || []
      tagInput.value = (demo.tags || []).join(', ')
      if (editor.value && demo.content) {
        editor.value.commands.setContent(demo.content)
      }
    }
  }
}

onMounted(loadExistingDiary)

onBeforeUnmount(() => {
  editor.value?.destroy()
})
</script>

<style scoped>
.prose-editor :deep(.tiptap) {
  outline: none;
  min-height: 260px;
}
.prose-editor :deep(.tiptap p.is-editor-empty:first-child::before) {
  content: attr(data-placeholder);
  float: left;
  color: #94a3b8;
  pointer-events: none;
  height: 0;
}
.prose-editor :deep(h1) {
  font-size: 1.5rem;
  font-weight: 700;
  margin-top: 1.5rem;
  margin-bottom: 0.75rem;
  color: #0f172a;
}
.prose-editor :deep(h2) {
  font-size: 1.2rem;
  font-weight: 600;
  margin-top: 1.25rem;
  margin-bottom: 0.5rem;
  color: #1e293b;
}
.prose-editor :deep(h3) {
  font-size: 1.05rem;
  font-weight: 600;
  margin-top: 1rem;
  margin-bottom: 0.5rem;
  color: #334155;
}
.prose-editor :deep(p) {
  margin-bottom: 0.75rem;
  line-height: 2;
}
.prose-editor :deep(blockquote) {
  border-left: 2px solid #94a3b8;
  padding-left: 1rem;
  color: #64748b;
  font-style: italic;
  margin: 0.75rem 0;
}
.prose-editor :deep(ul),
.prose-editor :deep(ol) {
  padding-left: 1.25rem;
  margin-bottom: 0.75rem;
}
.prose-editor :deep(li) {
  margin-bottom: 0.25rem;
}
.prose-editor :deep(hr) {
  border-color: #e2e8f0;
  margin: 1.25rem 0;
}
.prose-editor :deep(u) {
  text-decoration: underline;
}
.prose-editor :deep(s) {
  text-decoration: line-through;
}
</style>
