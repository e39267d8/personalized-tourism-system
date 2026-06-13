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
        <div v-if="form.images.length" class="relative rounded-xl overflow-hidden mb-3 bg-white shadow-inner">
          <img :src="form.images[currentPreviewIdx]" class="mx-auto block max-h-[28rem] max-w-full object-contain bg-white" />
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
          <div v-if="currentPreviewIdx === coverIndex" class="absolute left-2 top-2 rounded-full bg-teal-600 px-2.5 py-1 text-xs font-medium text-white">
            封面
          </div>
          <button
            v-else
            class="absolute left-2 top-2 rounded-full bg-white/85 px-2.5 py-1 text-xs font-medium text-slate-700 shadow-sm hover:bg-white"
            @click="setCover(currentPreviewIdx)"
          >
            设为封面
          </button>
        </div>

        <!-- Apple Photos style filmstrip -->
        <div v-if="form.images.length" class="-mx-1 flex items-center gap-2 overflow-x-auto px-1 pb-2">
          <div
            v-for="(img, idx) in form.images"
            :key="idx"
            role="button"
            tabindex="0"
            :data-image-idx="idx"
            class="group relative h-16 w-16 flex-shrink-0 cursor-grab select-none overflow-hidden rounded-md border-2 bg-white transition-all active:cursor-grabbing"
            :class="[
              idx === currentPreviewIdx ? 'border-teal-500 shadow-sm' : 'border-transparent hover:border-slate-300',
              idx === draggedImageIdx && imageDragActive ? 'scale-105 opacity-75 ring-2 ring-teal-300' : '',
              idx === dragOverImageIdx && imageDragActive ? 'border-teal-500 ring-2 ring-teal-200' : ''
            ]"
            @pointerdown="startImageDrag(idx, $event)"
            @pointermove="moveImageDrag"
            @pointerup="finishImageDrag($event)"
            @pointercancel="cancelImageDrag"
            @keydown.enter.prevent="currentPreviewIdx = idx"
            @keydown.space.prevent="currentPreviewIdx = idx"
            title="长按拖动调整顺序"
          >
            <img :src="img" class="w-full h-full object-cover" />
            <span v-if="idx === coverIndex" class="absolute left-1 top-1 rounded bg-teal-600 px-1.5 py-0.5 text-[10px] font-medium text-white">封面</span>
            <button
              @pointerdown.stop
              @click.stop="removeImage(idx)"
              class="absolute right-1 top-1 w-4 h-4 rounded-full bg-black/55 text-white flex items-center justify-center opacity-0 transition text-xs hover:opacity-100 group-hover:opacity-100 focus:opacity-100"
            >&times;</button>
          </div>
          <label
            v-if="form.images.length < 9"
            class="flex h-16 w-16 flex-shrink-0 cursor-pointer flex-col items-center justify-center rounded-md border-2 border-dashed border-slate-200 bg-white/70 transition hover:border-teal-400 hover:bg-teal-50/50"
          >
            <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            <span class="text-[10px] text-slate-400 mt-0.5">{{ form.images.length }}/9</span>
            <input type="file" accept="image/*" multiple class="hidden" @change="handleImageUpload" />
          </label>
        </div>

        <div v-if="isProcessingImages || imageUploadError" class="mt-3 rounded-lg border px-3 py-2 text-xs" :class="imageUploadError ? 'border-rose-100 bg-rose-50 text-rose-600' : 'border-teal-100 bg-teal-50 text-teal-700'">
          {{ imageUploadError || '正在压缩图片...' }}
        </div>

        <!-- Empty state -->
        <div v-if="!form.images.length" class="flex-1 flex flex-col items-center justify-center py-12">
          <label class="flex flex-col items-center cursor-pointer group">
            <div class="w-16 h-16 rounded-full bg-slate-100 group-hover:bg-teal-50 flex items-center justify-center transition mb-3">
              <svg class="w-7 h-7 text-slate-400 group-hover:text-teal-500 transition" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            </div>
            <span class="text-sm text-slate-500 group-hover:text-teal-600 transition">添加旅行照片</span>
            <span class="text-xs text-slate-400 mt-1">支持多张上传，可单独设置封面</span>
            <input type="file" accept="image/*" multiple class="hidden" @change="handleImageUpload" />
          </label>
        </div>

        <!-- Scenic spots & Mood (bottom of photo side) -->
        <div class="mt-auto pt-4 flex items-center gap-2">
          <div class="flex flex-1 items-center gap-1.5 rounded-lg border border-slate-150 bg-white/80 px-3 py-2">
            <svg class="h-4 w-4 flex-shrink-0 text-teal-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"/></svg>
            <span class="flex-shrink-0 text-xs text-slate-400">景点ID</span>
            <input
              v-model="scenicSpotInput"
              type="text"
              placeholder="多个 ID 用逗号分隔"
              class="min-w-0 flex-1 bg-transparent text-sm text-slate-700 outline-none placeholder:text-slate-400"
            />
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

        <div class="mt-3 rounded-lg border border-slate-150 bg-white/80 p-3">
          <div class="flex items-center gap-2">
            <input
              v-model="videoInput"
              type="url"
              placeholder="添加视频 URL"
              class="min-w-0 flex-1 bg-transparent text-sm text-slate-700 outline-none placeholder:text-slate-400"
              @keydown.enter.prevent="addVideoUrl"
            />
            <button
              class="rounded-md bg-slate-800 px-2.5 py-1.5 text-xs font-medium text-white hover:bg-slate-900"
              @click="addVideoUrl"
            >
              添加
            </button>
          </div>
          <div v-if="form.videos.length" class="mt-2 space-y-2">
            <div v-for="(video, idx) in form.videos" :key="video" class="flex items-center gap-2 text-xs text-slate-500">
              <span class="min-w-0 flex-1 truncate">{{ video }}</span>
              <button class="text-rose-500 hover:text-rose-700" @click="removeVideo(idx)">移除</button>
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
                <span v-if="editor.isActive('bold')" class="absolute bottom-1 right-1 h-1.5 w-1.5 rounded-[2px] bg-teal-600" />
              </button>
              <button @click="editor.chain().focus().toggleItalic().run()" :class="inlineBtnClass(editor.isActive('italic'))" title="斜体">
                <span class="italic">I</span>
                <span v-if="editor.isActive('italic')" class="absolute bottom-1 right-1 h-1.5 w-1.5 rounded-[2px] bg-teal-600" />
              </button>
              <button @click="editor.chain().focus().toggleUnderline().run()" :class="inlineBtnClass(editor.isActive('underline'))" title="下划线">
                <span class="underline">U</span>
                <span v-if="editor.isActive('underline')" class="absolute bottom-1 right-1 h-1.5 w-1.5 rounded-[2px] bg-teal-600" />
              </button>
              <button @click="editor.chain().focus().toggleStrike().run()" :class="inlineBtnClass(editor.isActive('strike'))" title="删除线">
                <span class="line-through">S</span>
                <span v-if="editor.isActive('strike')" class="absolute bottom-1 right-1 h-1.5 w-1.5 rounded-[2px] bg-teal-600" />
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
              <span class="w-px h-5 bg-slate-200 mx-1" />
              <button @click="aiPolish" :disabled="aiBusy" class="w-7 h-7 rounded-lg flex items-center justify-center text-amber-500 hover:text-amber-600 hover:bg-amber-50 transition" title="AI 润色">
                <span class="text-xs font-bold">{{ aiBusy ? '...' : 'AI' }}</span>
              </button>
              <button @click="aiGenerateTitle" :disabled="aiBusy" class="w-7 h-7 rounded-lg flex items-center justify-center text-purple-500 hover:text-purple-600 hover:bg-purple-50 transition" title="AI 标题文案">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
              </button>
              <button @click="aiImagePrompt" :disabled="aiBusy" class="w-7 h-7 rounded-lg flex items-center justify-center text-teal-500 hover:text-teal-600 hover:bg-teal-50 transition" title="AI 配图建议">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
              </button>
            </div>
          </div>

          <!-- AI feedback indicator -->
          <div v-if="aiMessage" class="mb-2 px-3 py-1.5 rounded-md text-xs flex items-center gap-1.5" :class="aiMessage.type === 'success' ? 'bg-green-50 text-green-700' : 'bg-blue-50 text-blue-700'">
            <svg v-if="aiMessage.type === 'success'" class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
            <svg v-else class="w-3.5 h-3.5 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>
            {{ aiMessage.text }}
          </div>

          <!-- Writing area -->
          <div class="flex-1 rounded-lg bg-slate-50/50 focus-within:bg-white focus-within:shadow-inner transition-all">
            <div
              ref="editorEl"
              class="px-4 py-3 prose-editor"
              contenteditable="true"
              data-placeholder="开始写你的旅行故事..."
              @input="syncEditorContent"
              @keyup="updateActiveFormats"
              @mouseup="updateActiveFormats"
              @blur="syncEditorContent"
            />
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
      <div class="flex items-center gap-3">
        <span class="text-xs text-slate-400">
          {{ form.images.length }} 张图片 · {{ form.videos.length }} 个视频 · {{ contentLength }} 字
        </span>
        <span
          v-if="huffmanStats.saved > 0"
          class="text-xs text-teal-600"
          title="发布后会自动优化正文存储"
        >
          内容优化存储 · 节省 {{ huffmanStats.saved }}%
        </span>
      </div>
      <div class="flex items-center gap-2.5">
        <button
          @click="saveDraft"
          :disabled="saving || isProcessingImages"
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
          :disabled="saving || isProcessingImages"
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
import { ref, computed, onMounted, onBeforeUnmount, reactive } from 'vue'
import { useRouter } from 'vue-router'
import DiaryPostcard from '@/components/DiaryPostcard.vue'
import { tourismApi } from '@/services/tourismApi'
import { diaries as demoDiaries } from '@/data/demoData'
import { diaryStore, setJustPublished } from '@/stores/diaryStore'
import { authStore } from '@/stores/auth'
import { normalizeDiaryImages } from '@/utils/images'

const props = defineProps({
  id: { type: Number, default: 0 }
})

const router = useRouter()

const MAX_DIARY_IMAGES = 9
const MAX_DIARY_IMAGE_DIMENSION = 1600
const MAX_DIARY_IMAGE_BYTES = 900 * 1024
const INITIAL_IMAGE_QUALITY = 0.82
const MIN_IMAGE_QUALITY = 0.58

const form = ref({
  title: '',
  date: new Date().toISOString().slice(0, 10),
  location: '',
  locationDetail: null,
  mood: '',
  moodLabel: '',
  images: [],
  videos: []
})
const tagInput = ref('')
const videoInput = ref('')
const scenicSpotInput = ref('')
const saving = ref(false)
const isProcessingImages = ref(false)
const imageUploadError = ref('')
const showPreview = ref(false)
const showMoodPicker = ref(false)
const showEmojiPicker = ref(false)
const currentPreviewIdx = ref(0)
const coverIndex = ref(0)
const editorEl = ref(null)
const editorHtml = ref('')
const editorPlainText = ref('')
const aiBusy = ref(false)
const aiMessage = ref(null) // { type: 'loading'|'success', text: string }
const draftDiaryId = ref(props.id || 0)
const draggedImageIdx = ref(-1)
const dragOverImageIdx = ref(-1)
const imageDragActive = ref(false)
let imageDragTimer = null
const activeFormats = reactive({
  block: 'paragraph',
  bold: false,
  italic: false,
  underline: false,
  strike: false,
  bulletList: false,
  orderedList: false,
  blockquote: false
})

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

const parsedScenicSpotIds = computed(() =>
  scenicSpotInput.value
    .split(/[,，\s]+/)
    .map(item => Number.parseInt(item, 10))
    .filter(id => Number.isInteger(id) && id > 0)
)

const selectedCover = computed(() => form.value.images[coverIndex.value] || form.value.images[0] || '')

const contentLength = computed(() => {
  return editorPlainText.value.replace(/\s/g, '').length
})

const normalizedFormImages = computed(() => normalizeDiaryImages({
  images: form.value.images,
  tags: parsedTags.value
}))

const previewDiary = computed(() => {
  const images = normalizedFormImages.value
  return {
    title: form.value.title || '未命名日记',
    content: editor.value?.getHTML() || '',
    images,
    cover: selectedCover.value || images[0] || '',
    videos: form.value.videos,
    scenicSpotIds: parsedScenicSpotIds.value,
    date: form.value.date,
    location: '',
    locationDetail: {},
    mood: form.value.mood,
    tags: parsedTags.value,
    author: { nickname: diaryStore.user.nickname, avatar: '' },
    disableLocalImageFallback: true
  }
})

// Huffman compression stats — debounced, shown as "节省 X%" in action bar
const huffmanStats = reactive({ saved: 0 })
let _huffmanTimer = null
function _refreshHuffmanStats() {
  clearTimeout(_huffmanTimer)
  _huffmanTimer = setTimeout(async () => {
    const text = editorEl.value?.innerText || ''
    if (text.length < 30) { huffmanStats.saved = 0; return }
    try {
      const data = await tourismApi.huffmanCompress({ content: text })
      huffmanStats.saved = Math.round(100 - (data.compressionRatio || 0))
    } catch { /* silent */ }
  }, 2000)
}

function syncEditorContent() {
  editorHtml.value = editorEl.value?.innerHTML || ''
  editorPlainText.value = editorEl.value?.innerText || ''
  _refreshHuffmanStats()
}

function setEditorContent(html = '') {
  editorHtml.value = html
  if (editorEl.value) {
    editorEl.value.innerHTML = html
  }
  editorPlainText.value = editorEl.value?.innerText || html.replace(/<[^>]*>/g, '')
  window.setTimeout(updateActiveFormats, 0)
}

function focusEditor() {
  editorEl.value?.focus()
}

function escapeHtml(value = '') {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

function textToParagraphHtml(value = '') {
  const blocks = String(value)
    .split(/\n{2,}/)
    .map(block => block.trim())
    .filter(Boolean)
  if (!blocks.length) return ''
  return blocks
    .map(block => `<p>${escapeHtml(block).replace(/\n/g, '<br>')}</p>`)
    .join('')
}

function cleanAiDiaryText(value = '') {
  let text = String(value || '').replace(/\r/g, '').trim()
  text = text.replace(/^```[a-z]*\s*/i, '').replace(/```$/i, '').trim()
  text = text.replace(/^(润色后的?(正文|文本|版本)?|正式日记正文|以下是.*?日记.*?|成品日记)[：:]\s*/i, '').trim()
  const blockedLine = /^(提示词|摘要|标题|系统建议|修改说明|润色说明|以下是|当然[，,]|好的[，,])/
  return text
    .split('\n')
    .map(line => line.trim())
    .filter(line => line && !blockedLine.test(line))
    .join('\n')
    .trim()
}

function cleanAiTitle(value = '') {
  return String(value || '')
    .replace(/\r?\n/g, ' ')
    .replace(/^(标题|题目|标题文案)[：:]\s*/i, '')
    .replace(/[《》"'“”]/g, '')
    .trim()
    .slice(0, 40)
}

// AI tools
async function aiPolish() {
  const text = editorEl.value?.textContent || ''
  if (!text.trim()) { aiMessage.value = { type: 'success', text: '请先输入内容' }; return }
  aiBusy.value = true
  aiMessage.value = { type: 'loading', text: 'AI 正在润色...' }
  try {
    const data = await tourismApi.polishDiary({ content: text })
    const polished = cleanAiDiaryText(data.polished || text) || text
    setEditorContent(textToParagraphHtml(polished))
    aiMessage.value = { type: 'success', text: 'AI 润色完成' }
    setTimeout(() => { aiMessage.value = null }, 3000)
  } catch {
    aiMessage.value = { type: 'success', text: 'AI 暂不可用，已保留原文' }
    setTimeout(() => { aiMessage.value = null }, 3000)
  } finally { aiBusy.value = false }
}

async function aiGenerateTitle() {
  const text = editorEl.value?.textContent || ''
  if (!text.trim()) { aiMessage.value = { type: 'success', text: '请先输入内容' }; return }
  aiBusy.value = true
  aiMessage.value = { type: 'loading', text: 'AI 正在生成标题...' }
  try {
    const data = await tourismApi.generateDiaryTitle({ content: text })
    const title = cleanAiTitle(data.title)
    if (title) form.value.title = title
    aiMessage.value = { type: 'success', text: title ? '标题已写入' : '没有生成可用标题' }
    setTimeout(() => { aiMessage.value = null }, 3000)
  } catch {
    aiMessage.value = { type: 'success', text: 'AI 暂不可用' }
    setTimeout(() => { aiMessage.value = null }, 3000)
  } finally { aiBusy.value = false }
}

async function aiImagePrompt() {
  if (!form.value.title.trim()) { aiMessage.value = { type: 'success', text: '请先输入标题' }; return }
  const text = editorEl.value?.textContent || ''
  aiBusy.value = true
  aiMessage.value = { type: 'loading', text: 'AI 正在生成配图建议...' }
  try {
    const data = await tourismApi.imagePrompt({ title: form.value.title, content: text })
    const promptCn = data.promptCn || '旅行风景'
    const style = data.style || '写实摄影'
    const palette = data.colorPalette || '自然色调'
    aiMessage.value = { type: 'success', text: '配图建议: ' + promptCn + ' | ' + style + ' | ' + palette }
    setTimeout(() => { aiMessage.value = null }, 8000)
  } catch {
    aiMessage.value = { type: 'success', text: 'AI 暂不可用' }
    setTimeout(() => { aiMessage.value = null }, 3000)
  } finally { aiBusy.value = false }
}

function execEditorCommand(command, value = null) {
  focusEditor()
  document.execCommand(command, false, value)
  syncEditorContent()
  window.setTimeout(updateActiveFormats, 0)
}

function updateActiveFormats() {
  activeFormats.bold = document.queryCommandState('bold')
  activeFormats.italic = document.queryCommandState('italic')
  activeFormats.underline = document.queryCommandState('underline')
  activeFormats.strike = document.queryCommandState('strikeThrough')
  activeFormats.bulletList = document.queryCommandState('insertUnorderedList')
  activeFormats.orderedList = document.queryCommandState('insertOrderedList')

  const selection = window.getSelection()
  let node = selection?.anchorNode || null
  if (node && node.nodeType === Node.TEXT_NODE) node = node.parentElement
  const element = node instanceof Element ? node : null
  const block = element?.closest?.('h1,h2,h3,blockquote,p,li,div')
  const tag = block?.tagName?.toLowerCase() || ''
  activeFormats.blockquote = tag === 'blockquote' || Boolean(element?.closest?.('blockquote'))
  if (tag === 'h1') activeFormats.block = 'heading1'
  else if (tag === 'h2') activeFormats.block = 'heading2'
  else if (tag === 'h3') activeFormats.block = 'heading3'
  else activeFormats.block = activeFormats.blockquote ? 'blockquote' : 'paragraph'
}

function editorIsActive(type, attrs = {}) {
  if (type === 'heading') return activeFormats.block === `heading${attrs.level || 1}`
  if (type === 'paragraph') return activeFormats.block === 'paragraph'
  if (type === 'blockquote') return activeFormats.blockquote
  if (type === 'bold') return activeFormats.bold
  if (type === 'italic') return activeFormats.italic
  if (type === 'underline') return activeFormats.underline
  if (type === 'strike') return activeFormats.strike
  if (type === 'bulletList') return activeFormats.bulletList
  if (type === 'orderedList') return activeFormats.orderedList
  return false
}

function createEditorChain() {
  const chain = {
    focus() {
      focusEditor()
      return chain
    },
    toggleHeading({ level }) {
      execEditorCommand('formatBlock', `H${level}`)
      return chain
    },
    setParagraph() {
      execEditorCommand('formatBlock', 'P')
      return chain
    },
    toggleBold() {
      execEditorCommand('bold')
      return chain
    },
    toggleItalic() {
      execEditorCommand('italic')
      return chain
    },
    toggleUnderline() {
      execEditorCommand('underline')
      return chain
    },
    toggleStrike() {
      execEditorCommand('strikeThrough')
      return chain
    },
    toggleBulletList() {
      execEditorCommand('insertUnorderedList')
      return chain
    },
    toggleOrderedList() {
      execEditorCommand('insertOrderedList')
      return chain
    },
    toggleBlockquote() {
      execEditorCommand('formatBlock', 'BLOCKQUOTE')
      return chain
    },
    insertContent(value) {
      execEditorCommand('insertText', value)
      return chain
    },
    undo() {
      execEditorCommand('undo')
      return chain
    },
    redo() {
      execEditorCommand('redo')
      return chain
    },
    run() {
      syncEditorContent()
      return true
    }
  }
  return chain
}

const editor = ref({
  chain: createEditorChain,
  commands: {
    setContent: setEditorContent
  },
  getHTML() {
    syncEditorContent()
    return editorHtml.value
  },
  getText() {
    return editorEl.value?.innerText || editorHtml.value.replace(/<[^>]*>/g, '')
  },
  isActive: editorIsActive
})

function formatBtnClass(active) {
  return [
    'px-2.5 py-1 rounded-lg text-xs font-medium transition',
    active ? 'bg-amber-100 text-amber-800' : 'text-slate-600 hover:bg-slate-100'
  ]
}

function inlineBtnClass(active) {
  return [
    'relative w-7 h-7 rounded-lg flex items-center justify-center text-sm transition',
    active ? 'bg-slate-200 text-slate-900' : 'text-slate-500 hover:bg-slate-100'
  ]
}

// Image handling
function estimateDataUrlBytes(dataUrl) {
  const base64 = String(dataUrl).split(',')[1] || ''
  return Math.ceil(base64.length * 0.75)
}

function loadImageFromFile(file) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file)
    const image = new Image()
    image.onload = () => {
      URL.revokeObjectURL(url)
      resolve(image)
    }
    image.onerror = () => {
      URL.revokeObjectURL(url)
      reject(new Error('Image load failed'))
    }
    image.src = url
  })
}

async function compressDiaryImage(file) {
  const image = await loadImageFromFile(file)
  const scale = Math.min(
    1,
    MAX_DIARY_IMAGE_DIMENSION / image.naturalWidth,
    MAX_DIARY_IMAGE_DIMENSION / image.naturalHeight
  )
  const width = Math.max(1, Math.round(image.naturalWidth * scale))
  const height = Math.max(1, Math.round(image.naturalHeight * scale))
  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  const ctx = canvas.getContext('2d')
  ctx.fillStyle = '#ffffff'
  ctx.fillRect(0, 0, width, height)
  ctx.drawImage(image, 0, 0, width, height)

  let quality = INITIAL_IMAGE_QUALITY
  let dataUrl = canvas.toDataURL('image/jpeg', quality)
  while (estimateDataUrlBytes(dataUrl) > MAX_DIARY_IMAGE_BYTES && quality > MIN_IMAGE_QUALITY) {
    quality = Math.max(MIN_IMAGE_QUALITY, quality - 0.08)
    dataUrl = canvas.toDataURL('image/jpeg', quality)
  }
  return dataUrl
}

function diaryImagePayload() {
  return normalizeDiaryImages({
    images: form.value.images,
    tags: parsedTags.value
  }).slice(0, MAX_DIARY_IMAGES)
}

function setCover(idx) {
  if (idx < 0 || idx >= form.value.images.length) return
  coverIndex.value = idx
  currentPreviewIdx.value = idx
}

async function handleImageUpload(event) {
  const files = Array.from(event.target.files)
  const remaining = MAX_DIARY_IMAGES - form.value.images.length
  const filesToProcess = files.slice(0, remaining)
  imageUploadError.value = ''

  if (!filesToProcess.length) {
    event.target.value = ''
    return
  }

  isProcessingImages.value = true
  try {
    for (const file of filesToProcess) {
      if (!file.type.startsWith('image/')) continue
      const compressed = await compressDiaryImage(file)
      form.value.images.push(compressed)
    }
    if (form.value.images.length && coverIndex.value >= form.value.images.length) coverIndex.value = 0
    if (files.length > remaining) {
      imageUploadError.value = `最多只能上传 ${MAX_DIARY_IMAGES} 张图片，已自动忽略多余图片。`
    }
  } catch {
    imageUploadError.value = '有图片处理失败，请换一张图片再试。'
  } finally {
    isProcessingImages.value = false
    event.target.value = ''
  }
}

function removeImage(idx) {
  form.value.images.splice(idx, 1)
  imageUploadError.value = ''
  if (idx === coverIndex.value) {
    coverIndex.value = 0
  } else if (idx < coverIndex.value) {
    coverIndex.value -= 1
  }
  if (currentPreviewIdx.value >= form.value.images.length) {
    currentPreviewIdx.value = Math.max(0, form.value.images.length - 1)
  }
  if (coverIndex.value >= form.value.images.length) {
    coverIndex.value = Math.max(0, form.value.images.length - 1)
  }
}

function remapIndexAfterMove(index, from, to) {
  if (index === from) return to
  if (from < to && index > from && index <= to) return index - 1
  if (from > to && index >= to && index < from) return index + 1
  return index
}

function moveImage(from, to) {
  if (from === to || from < 0 || to < 0 || from >= form.value.images.length || to >= form.value.images.length) return
  const next = [...form.value.images]
  const [item] = next.splice(from, 1)
  next.splice(to, 0, item)
  form.value.images = next
  coverIndex.value = remapIndexAfterMove(coverIndex.value, from, to)
  currentPreviewIdx.value = remapIndexAfterMove(currentPreviewIdx.value, from, to)
}

function startImageDrag(idx, event) {
  if (event.button !== undefined && event.button !== 0) return
  clearTimeout(imageDragTimer)
  draggedImageIdx.value = idx
  dragOverImageIdx.value = idx
  imageDragActive.value = false
  event.currentTarget?.setPointerCapture?.(event.pointerId)
  imageDragTimer = window.setTimeout(() => {
    imageDragActive.value = true
  }, 260)
}

function moveImageDrag(event) {
  if (draggedImageIdx.value < 0) return
  if (!imageDragActive.value) return
  event.preventDefault()
  const target = document.elementFromPoint(event.clientX, event.clientY)?.closest?.('[data-image-idx]')
  const idx = Number(target?.dataset?.imageIdx)
  if (Number.isInteger(idx) && idx >= 0 && idx < form.value.images.length) {
    dragOverImageIdx.value = idx
  }
}

function finishImageDrag(event) {
  clearTimeout(imageDragTimer)
  if (draggedImageIdx.value < 0) return
  if (imageDragActive.value) {
    event.preventDefault()
    moveImage(draggedImageIdx.value, dragOverImageIdx.value)
  } else {
    currentPreviewIdx.value = draggedImageIdx.value
  }
  cancelImageDrag()
}

function cancelImageDrag() {
  clearTimeout(imageDragTimer)
  draggedImageIdx.value = -1
  dragOverImageIdx.value = -1
  imageDragActive.value = false
}

function addVideoUrl() {
  const value = videoInput.value.trim()
  if (!value) return
  if (!form.value.videos.includes(value)) form.value.videos.push(value)
  videoInput.value = ''
}

function removeVideo(idx) {
  form.value.videos.splice(idx, 1)
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

function buildDiaryPayload(status) {
  const images = diaryImagePayload()
  return {
    title: form.value.title,
    content: editor.value?.getHTML() || '',
    date: form.value.date,
    location: '',
    locationName: '',
    locationAddress: '',
    locationLatitude: 0,
    locationLongitude: 0,
    locationPoiId: '',
    coverImage: selectedCover.value || images[0] || '',
    cover: selectedCover.value || images[0] || '',
    images,
    videos: form.value.videos,
    scenicSpotIds: parsedScenicSpotIds.value,
    tags: parsedTags.value,
    status
  }
}

function localDiaryFromPayload(saved, payload) {
  const currentUser = authStore.user || {}
  const savedAuthor = saved?.author || {}
  const author = {
    id: savedAuthor.id || currentUser.id || 0,
    nickname: savedAuthor.nickname || currentUser.nickname || currentUser.username || diaryStore.user.nickname || '旅行者',
    avatar: savedAuthor.avatar || currentUser.avatarUrl || ''
  }
  const diary = {
    id: saved?.id || draftDiaryId.value || Date.now(),
    title: payload.title,
    date: payload.date,
    location: '',
    locationDetail: {},
    mood: form.value.moodLabel || '',
    cover: payload.coverImage,
    coverImage: payload.coverImage,
    images: payload.images,
    videos: payload.videos,
    scenicSpotIds: payload.scenicSpotIds,
    tags: payload.tags,
    excerpt: (editor.value?.getText() || '').slice(0, 80) + '...',
    content: payload.content,
    status: payload.status,
    author,
    stats: { views: 0, likes: 0, comments: 0 },
    ratingScore: 0,
    ratingCount: 0,
    bookmarkCount: 0,
    disableLocalImageFallback: true,
    ...(saved || {})
  }
  diary.author = author
  return diary
}

// Save & Publish
async function saveDraft() {
  await saveDiaryWithStatus(0)
}

async function publishDiary() {
  if (!form.value.title.trim()) {
    form.value.title = '未命名日记'
  }
  const publishedDiary = await saveDiaryWithStatus(1)
  setJustPublished(publishedDiary)
  router.push('/diary')
}

async function saveDiaryWithStatus(status) {
  if (!form.value.title.trim()) {
    form.value.title = '未命名日记'
  }
  saving.value = true
  const payload = buildDiaryPayload(status)
  let saved = null
  try {
    const targetId = draftDiaryId.value || props.id
    if (targetId) {
      saved = await tourismApi.updateDiary(targetId, payload)
      draftDiaryId.value = saved?.id || targetId
    } else {
      saved = await tourismApi.createDiary(payload)
      if (saved?.id) draftDiaryId.value = saved.id
    }
  } catch {
    // Demo mode
  } finally {
    saving.value = false
  }
  return localDiaryFromPayload(saved, payload)
}

// Load existing diary for edit mode
async function loadExistingDiary() {
  if (!props.id) return
  try {
    const data = await tourismApi.diaryDetail(props.id)
    form.value.title = data.title || ''
    form.value.date = data.date || ''
    form.value.location = ''
    form.value.locationDetail = null
    form.value.mood = data.mood || ''
    form.value.images = normalizeDiaryImages(data).slice(0, MAX_DIARY_IMAGES)
    coverIndex.value = Math.max(0, form.value.images.findIndex(img => img === (data.coverImage || data.cover)))
    if (coverIndex.value < 0) coverIndex.value = 0
    currentPreviewIdx.value = coverIndex.value
    form.value.videos = data.videos || []
    scenicSpotInput.value = (data.scenicSpotIds || []).join(', ')
    tagInput.value = (data.tags || []).join(', ')
    if (editor.value && data.content) {
      editor.value.commands.setContent(data.content)
    }
  } catch {
    const demo = demoDiaries.find(d => d.id === props.id)
    if (demo) {
      form.value.title = demo.title
      form.value.date = demo.date
      form.value.location = ''
      form.value.locationDetail = null
      form.value.mood = demo.mood || ''
      form.value.images = normalizeDiaryImages(demo).slice(0, MAX_DIARY_IMAGES)
      coverIndex.value = Math.max(0, form.value.images.findIndex(img => img === (demo.coverImage || demo.cover)))
      if (coverIndex.value < 0) coverIndex.value = 0
      currentPreviewIdx.value = coverIndex.value
      form.value.videos = demo.videos || []
      scenicSpotInput.value = (demo.scenicSpotIds || []).join(', ')
      tagInput.value = (demo.tags || []).join(', ')
      if (editor.value && demo.content) {
        editor.value.commands.setContent(demo.content)
      }
    }
  }
}

onMounted(async () => {
  document.addEventListener('selectionchange', updateActiveFormats)
  await loadExistingDiary()
  updateActiveFormats()
})

onBeforeUnmount(() => {
  document.removeEventListener('selectionchange', updateActiveFormats)
})
</script>

<style scoped>
.prose-editor :deep(.tiptap) {
  outline: none;
  min-height: 260px;
}
.prose-editor[contenteditable="true"] {
  outline: none;
  min-height: 260px;
  color: #334155;
  font-size: 15px;
  line-height: 2;
  letter-spacing: 0;
}
.prose-editor[contenteditable="true"]:empty::before {
  content: attr(data-placeholder);
  color: #94a3b8;
  pointer-events: none;
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
