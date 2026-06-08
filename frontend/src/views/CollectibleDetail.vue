<template>
  <div class="space-y-6">
    <router-link to="/achievements" class="inline-flex rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">
      返回旅行护照
    </router-link>

    <section v-if="loading" class="rounded-md border border-slate-200 bg-white p-8 text-center text-sm text-slate-500">
      正在加载数字纪念凭证...
    </section>

    <section v-else-if="errorMessage" class="rounded-md border border-rose-200 bg-rose-50 p-6">
      <h1 class="text-lg font-semibold text-rose-900">证书暂时无法打开</h1>
      <p class="mt-2 text-sm leading-6 text-rose-800">{{ errorMessage }}</p>
      <router-link to="/achievements" class="mt-4 inline-flex rounded-md bg-rose-700 px-3 py-2 text-sm font-semibold text-white hover:bg-rose-800">
        回到旅行护照
      </router-link>
    </section>

    <section v-else class="overflow-hidden rounded-md border border-slate-200 bg-white">
      <div class="grid lg:grid-cols-[0.9fr_1.1fr]">
        <div ref="shareCard" class="bg-slate-950 p-8 text-white">
          <div class="text-xs uppercase tracking-[0.22em] text-teal-200">TourPilot Passport</div>
          <h1 class="mt-10 text-3xl font-bold leading-tight">{{ collectible.name || '数字纪念凭证' }}</h1>
          <p class="mt-3 text-sm leading-7 text-slate-300">{{ collectible.description || '记录一次真实的旅行探索与成就解锁。' }}</p>
          <div class="mt-8 rounded-md border border-white/15 bg-white/10 p-4">
            <div class="text-xs text-slate-300">凭证编号</div>
            <div class="mt-1 break-all font-mono text-sm font-semibold">{{ collectible.tokenId }}</div>
          </div>
          <div class="mt-6 text-xs text-slate-400">数字纪念凭证 / 模拟链上哈希，不代表真实区块链资产</div>
        </div>

        <div class="p-6">
          <div class="grid gap-3 sm:grid-cols-2">
            <div class="rounded-md bg-slate-50 p-4">
              <div class="text-xs text-slate-500">来源成就</div>
              <div class="mt-1 font-semibold text-slate-950">{{ collectible.achievementName || '旅行护照成就' }}</div>
            </div>
            <div class="rounded-md bg-slate-50 p-4">
              <div class="text-xs text-slate-500">层级</div>
              <div class="mt-1 font-semibold text-slate-950">{{ collectible.tierLabel }}</div>
            </div>
            <div class="rounded-md bg-slate-50 p-4">
              <div class="text-xs text-slate-500">凭证模式</div>
              <div class="mt-1 font-semibold text-slate-950">{{ collectible.chainMode }}</div>
            </div>
            <div class="rounded-md bg-slate-50 p-4">
              <div class="text-xs text-slate-500">获得时间</div>
              <div class="mt-1 font-semibold text-slate-950">{{ formatTime(collectible.mintedAt || collectible.createdAt) }}</div>
            </div>
          </div>

          <div class="mt-5 rounded-md border border-slate-200 p-4">
            <div class="text-xs text-slate-500">模拟链上哈希</div>
            <div class="mt-2 break-all font-mono text-xs leading-6 text-slate-700">{{ collectible.blockchainHash }}</div>
          </div>

          <div class="mt-5 rounded-md bg-teal-50 p-4 text-sm leading-6 text-teal-900">
            {{ collectible.shareTitle || '我在 TourPilot 解锁了一张数字纪念凭证。' }}
          </div>

          <button
            class="mt-5 rounded-md bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800"
            @click="downloadShareCard"
          >
            下载分享卡
          </button>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { tourismApi } from '@/services/tourismApi'

const props = defineProps({
  id: {
    type: Number,
    required: true
  }
})

const collectible = ref({})
const loading = ref(true)
const errorMessage = ref('')

function formatTime(value) {
  if (!value) return ''
  return String(value).slice(0, 16).replace('T', ' ')
}

function drawWrappedText(ctx, text, x, y, maxWidth, lineHeight) {
  const words = String(text || '').split('')
  let line = ''
  let currentY = y
  words.forEach(char => {
    const next = line + char
    if (ctx.measureText(next).width > maxWidth && line) {
      ctx.fillText(line, x, currentY)
      line = char
      currentY += lineHeight
    } else {
      line = next
    }
  })
  if (line) ctx.fillText(line, x, currentY)
  return currentY + lineHeight
}

function downloadShareCard() {
  const canvas = document.createElement('canvas')
  canvas.width = 1080
  canvas.height = 1440
  const ctx = canvas.getContext('2d')

  ctx.fillStyle = '#0f172a'
  ctx.fillRect(0, 0, canvas.width, canvas.height)
  ctx.fillStyle = '#14b8a6'
  ctx.fillRect(0, 0, canvas.width, 18)
  ctx.fillStyle = '#ccfbf1'
  ctx.font = '30px Arial, sans-serif'
  ctx.fillText('TOURPILOT PASSPORT', 80, 120)

  ctx.fillStyle = '#ffffff'
  ctx.font = 'bold 72px Arial, sans-serif'
  const afterTitleY = drawWrappedText(ctx, collectible.value.name || '数字纪念凭证', 80, 260, 920, 86)

  ctx.fillStyle = '#cbd5e1'
  ctx.font = '34px Arial, sans-serif'
  drawWrappedText(ctx, collectible.value.description || '记录一次真实的旅行探索与成就解锁。', 80, afterTitleY + 40, 920, 48)

  ctx.fillStyle = '#1e293b'
  ctx.fillRect(80, 920, 920, 230)
  ctx.fillStyle = '#94a3b8'
  ctx.font = '28px Arial, sans-serif'
  ctx.fillText('凭证编号', 120, 990)
  ctx.fillStyle = '#ffffff'
  ctx.font = 'bold 34px Arial, sans-serif'
  drawWrappedText(ctx, collectible.value.tokenId || '-', 120, 1045, 820, 44)

  ctx.fillStyle = '#94a3b8'
  ctx.font = '28px Arial, sans-serif'
  ctx.fillText('模拟链上哈希', 120, 1230)
  ctx.fillStyle = '#e2e8f0'
  ctx.font = '24px Consolas, monospace'
  drawWrappedText(ctx, collectible.value.blockchainHash || '-', 120, 1280, 820, 34)

  const link = document.createElement('a')
  link.download = `tourpilot-collectible-${props.id}.png`
  link.href = canvas.toDataURL('image/png')
  link.click()
}

onMounted(async () => {
  loading.value = true
  errorMessage.value = ''
  try {
    collectible.value = await tourismApi.collectibleDetail(props.id)
  } catch (error) {
    errorMessage.value = error.response?.data?.message || '请确认已登录，并且该证书属于当前账号。'
  } finally {
    loading.value = false
  }
})
</script>
