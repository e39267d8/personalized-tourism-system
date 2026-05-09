<template>
  <div class="flex flex-col lg:flex-row gap-0 bg-white rounded-xl overflow-hidden shadow-sm border border-slate-100 relative">
    <!-- Left: Image Carousel -->
    <div class="relative lg:w-[45%] min-h-[320px] lg:min-h-[480px] bg-slate-100 flex items-center justify-center">
      <img
        v-if="currentImage"
        :src="currentImage"
        :alt="diary.title"
        class="w-full h-full object-cover"
      />
      <div v-else class="text-slate-400 text-sm">No Image</div>

      <!-- Navigation arrows -->
      <template v-if="imageList.length > 1">
        <button
          @click="prevImage"
          class="absolute left-3 top-1/2 -translate-y-1/2 w-9 h-9 rounded-full bg-white/80 backdrop-blur flex items-center justify-center shadow hover:bg-white transition"
        >
          <svg class="w-4 h-4 text-slate-700" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
        </button>
        <button
          @click="nextImage"
          class="absolute right-3 top-1/2 -translate-y-1/2 w-9 h-9 rounded-full bg-white/80 backdrop-blur flex items-center justify-center shadow hover:bg-white transition"
        >
          <svg class="w-4 h-4 text-slate-700" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
        </button>
      </template>

      <!-- Dots indicator -->
      <div v-if="imageList.length > 1" class="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-1.5">
        <span
          v-for="(_, idx) in imageList"
          :key="idx"
          class="w-2 h-2 rounded-full transition-all"
          :class="idx === currentIdx ? 'bg-white scale-110' : 'bg-white/50'"
        />
      </div>
    </div>

    <!-- Center: Dashed divider (desktop only) -->
    <div class="hidden lg:block w-px border-l-2 border-dashed border-slate-200 my-8" />

    <!-- Right: Text Content -->
    <div class="lg:w-[55%] p-6 lg:p-8 overflow-y-auto max-h-[75vh] diary-content-scroll flex flex-col">
      <!-- Title -->
      <h1 class="text-2xl font-bold text-slate-900 leading-tight mb-4">{{ diary.title }}</h1>

      <!-- Content -->
      <div
        class="prose-diary text-slate-700 text-base leading-8 tracking-wide flex-1"
        v-html="diary.content || diary.excerpt"
      />

      <!-- Tags & Location (bottom-left of text area) -->
      <div v-if="(diary.tags && diary.tags.length) || diary.location" class="mt-6 flex flex-wrap gap-2">
        <span
          v-if="diary.location"
          class="inline-flex items-center gap-1 px-2.5 py-1 text-xs font-medium rounded-full bg-teal-50 text-teal-700 border border-teal-100"
        >
          <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
          {{ diary.location }}
        </span>
        <span
          v-for="tag in diary.tags"
          :key="tag"
          class="px-2.5 py-1 text-xs font-medium rounded-full bg-slate-100 text-slate-600"
        >
          #{{ tag }}
        </span>
      </div>
    </div>

    <!-- Signature: absolute bottom-right of the whole card -->
    <div v-if="diary.author" class="absolute bottom-4 right-6 text-right">
      <p class="text-sm text-slate-700 font-medium italic">-- {{ diary.author.nickname || '匿名旅行者' }}</p>
      <p class="text-xs text-slate-400 mt-0.5">{{ diary.date }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  diary: { type: Object, required: true }
})

const currentIdx = ref(0)

const imageList = computed(() => {
  if (props.diary.images && props.diary.images.length) return props.diary.images
  if (props.diary.cover) return [props.diary.cover]
  return []
})

const currentImage = computed(() => imageList.value[currentIdx.value] || '')

function prevImage() {
  currentIdx.value = (currentIdx.value - 1 + imageList.value.length) % imageList.value.length
}

function nextImage() {
  currentIdx.value = (currentIdx.value + 1) % imageList.value.length
}
</script>

<style scoped>
.diary-content-scroll::-webkit-scrollbar {
  width: 4px;
}
.diary-content-scroll::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 2px;
}
.prose-diary :deep(h2) {
  font-size: 1.25rem;
  font-weight: 700;
  margin-top: 1.5rem;
  margin-bottom: 0.75rem;
  color: #1e293b;
}
.prose-diary :deep(h3) {
  font-size: 1.1rem;
  font-weight: 600;
  margin-top: 1.25rem;
  margin-bottom: 0.5rem;
  color: #334155;
}
.prose-diary :deep(p) {
  margin-bottom: 1rem;
  line-height: 2;
}
.prose-diary :deep(blockquote) {
  border-left: 3px solid #94a3b8;
  padding-left: 1rem;
  color: #64748b;
  font-style: italic;
  margin: 1rem 0;
}
.prose-diary :deep(ul),
.prose-diary :deep(ol) {
  padding-left: 1.5rem;
  margin-bottom: 1rem;
}
.prose-diary :deep(li) {
  margin-bottom: 0.25rem;
}
</style>
