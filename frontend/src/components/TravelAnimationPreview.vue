<template>
  <div class="rounded-xl border border-slate-100 bg-white p-4 shadow-sm">
    <div class="flex flex-wrap items-start justify-between gap-3">
      <div>
        <h3 class="text-base font-semibold text-slate-900">{{ storyboard.title || '旅行动画短片' }}</h3>
        <p class="mt-1 text-sm text-slate-500">{{ storyboard.caption || '用照片、字幕和旁白生成旅行记忆短片' }}</p>
      </div>
      <button
        class="rounded-lg bg-teal-700 px-3 py-2 text-sm font-semibold text-white hover:bg-teal-800"
        @click="togglePlay"
      >
        {{ playing ? '暂停' : '播放' }}
      </button>
    </div>

    <div class="mt-4 overflow-hidden rounded-lg bg-slate-900">
      <div class="relative aspect-video">
        <img
          v-if="currentScene.image"
          :src="currentScene.image"
          :alt="currentScene.caption"
          class="h-full w-full object-cover transition-transform duration-[2800ms]"
          :class="currentScene.motion === 'pan-left' ? 'scale-110 -translate-x-3' : 'scale-110'"
        />
        <div v-else class="flex h-full w-full items-center justify-center bg-slate-800 text-sm text-slate-300">
          等待照片素材
        </div>
        <div class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/75 to-transparent px-5 pb-5 pt-16">
          <p class="text-base font-semibold leading-relaxed text-white">{{ currentScene.caption }}</p>
          <p class="mt-2 text-sm leading-relaxed text-white/75">{{ currentScene.voiceover }}</p>
        </div>
      </div>
    </div>

    <div class="mt-3 flex items-center gap-2">
      <button
        v-for="(scene, index) in scenes"
        :key="index"
        class="h-2 flex-1 rounded-full transition"
        :class="index === activeIndex ? 'bg-teal-700' : 'bg-slate-200'"
        :title="scene.caption"
        @click="setScene(index)"
      />
    </div>

    <p v-if="storyboard.voiceover" class="mt-3 text-sm leading-6 text-slate-600">
      {{ storyboard.voiceover }}
    </p>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, ref } from 'vue'

const props = defineProps({
  storyboard: { type: Object, required: true }
})

const activeIndex = ref(0)
const playing = ref(false)
let timer = null

const scenes = computed(() => {
  const list = Array.isArray(props.storyboard?.scenes) ? props.storyboard.scenes : []
  return list.length ? list : [{ caption: '暂无分镜', voiceover: '', image: '', durationMs: 3000, motion: 'slow-zoom-in' }]
})

const currentScene = computed(() => scenes.value[activeIndex.value] || scenes.value[0])

function clearTimer() {
  if (timer) {
    clearInterval(timer)
    timer = null
  }
}

function startTimer() {
  clearTimer()
  timer = setInterval(() => {
    activeIndex.value = (activeIndex.value + 1) % scenes.value.length
  }, Math.max(1800, currentScene.value.durationMs || 3200))
}

function togglePlay() {
  playing.value = !playing.value
  if (playing.value) startTimer()
  else clearTimer()
}

function setScene(index) {
  activeIndex.value = index
  if (playing.value) startTimer()
}

onBeforeUnmount(clearTimer)
</script>
