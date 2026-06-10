<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-slate-900">哈夫曼无损压缩</h1>
        <p class="mt-1 text-sm text-slate-500">旅行日记正文在数据库中以哈夫曼编码压缩存储，本页展示其工作原理</p>
      </div>
      <span class="rounded-md bg-teal-50 px-3 py-1 text-sm font-semibold text-teal-800">日记存储引擎</span>
    </div>

    <!-- 系统真实压缩存储统计 -->
    <div v-if="systemStats" class="mb-6 rounded-xl border border-teal-100 bg-teal-50/50 p-5">
      <div class="flex items-center justify-between mb-3">
        <h2 class="text-base font-semibold text-slate-800">系统存储概况（实时）</h2>
        <span class="text-xs text-slate-400">数据来自 travel_diaries 表</span>
      </div>
      <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <div class="rounded-lg bg-white p-3 text-center">
          <div class="text-xs text-slate-500">日记总数</div>
          <div class="mt-1 text-lg font-bold text-slate-800">{{ systemStats.totalDiaries }}</div>
        </div>
        <div class="rounded-lg bg-white p-3 text-center">
          <div class="text-xs text-slate-500">已压缩存储</div>
          <div class="mt-1 text-lg font-bold text-teal-700">{{ systemStats.compressedDiaries }}</div>
        </div>
        <div class="rounded-lg bg-white p-3 text-center">
          <div class="text-xs text-slate-500">节省空间</div>
          <div class="mt-1 text-lg font-bold text-amber-700">{{ formatBytes(systemStats.savedBytes) }}</div>
        </div>
        <div class="rounded-lg bg-white p-3 text-center">
          <div class="text-xs text-slate-500">总压缩率</div>
          <div class="mt-1 text-lg font-bold text-slate-800">{{ systemStats.savedPercent }}%</div>
        </div>
      </div>
    </div>

    <div class="grid gap-6 lg:grid-cols-2">
      <!-- Input panel -->
      <div class="rounded-xl border border-slate-200 bg-white p-5">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-base font-semibold text-slate-800">输入文本</h2>
          <span class="text-xs text-slate-400">{{ inputText.length }} 字符</span>
        </div>
        <textarea
          v-model="inputText"
          class="w-full h-48 rounded-lg border border-slate-200 bg-slate-50 px-4 py-3 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-teal-500/40 focus:border-teal-500 font-mono"
          placeholder="在此输入文本，点击下方「压缩」按钮查看哈夫曼编码效果..."
        ></textarea>
        <div class="flex gap-3 mt-3">
          <button
            @click="doCompress"
            :disabled="!inputText || compressing"
            class="flex-1 rounded-lg bg-teal-700 px-4 py-2.5 text-sm font-semibold text-white hover:bg-teal-800 disabled:bg-slate-400 disabled:cursor-not-allowed transition"
          >{{ compressing ? '压缩中...' : '压缩' }}</button>
          <button
            @click="inputText = ''; resetResults()"
            :disabled="!inputText"
            class="rounded-lg border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50 disabled:opacity-40 transition"
          >清空</button>
        </div>
      </div>

      <!-- Results panel -->
      <div class="rounded-xl border border-slate-200 bg-white p-5">
        <h2 class="text-base font-semibold text-slate-800 mb-3">压缩结果</h2>

        <!-- Stats -->
        <div class="grid grid-cols-3 gap-3 mb-4">
          <div class="rounded-lg bg-slate-50 p-3 text-center">
            <div class="text-xs text-slate-500">原始大小</div>
            <div class="mt-1 text-lg font-bold text-slate-800">{{ stats.originalBytes }}</div>
            <div class="text-xs text-slate-400">bytes</div>
          </div>
          <div class="rounded-lg bg-slate-50 p-3 text-center">
            <div class="text-xs text-slate-500">压缩后</div>
            <div class="mt-1 text-lg font-bold text-teal-700">{{ stats.compressedBytes }}</div>
            <div class="text-xs text-slate-400">bytes</div>
          </div>
          <div class="rounded-lg bg-slate-50 p-3 text-center">
            <div class="text-xs text-slate-500">压缩比</div>
            <div class="mt-1 text-lg font-bold text-amber-700">{{ stats.ratio }}%</div>
            <div class="text-xs text-slate-400">空间节省 {{ stats.saved }}%</div>
          </div>
        </div>

        <!-- Algorithm info -->
        <div v-if="stats.algorithm" class="mb-4 text-xs text-slate-500 flex items-center gap-3">
          <span class="bg-teal-50 text-teal-700 px-2 py-0.5 rounded-full">算法: {{ stats.algorithm }}</span>
          <span>不等长前缀编码</span>
        </div>

        <!-- Compressed base64 preview -->
        <div v-if="compressedB64" class="mb-3">
          <div class="text-xs text-slate-500 mb-1">压缩结果 (Base64)</div>
          <pre class="rounded-lg bg-slate-50 px-3 py-2 text-xs font-mono text-slate-600 max-h-24 overflow-auto break-all">{{ compressedB64 }}</pre>
        </div>

        <!-- Decompress button -->
        <button
          @click="doDecompress"
          :disabled="!compressedB64 || decompressing"
          class="w-full rounded-lg border border-teal-300 bg-teal-50 px-4 py-2.5 text-sm font-semibold text-teal-700 hover:bg-teal-100 disabled:opacity-40 disabled:cursor-not-allowed transition"
        >{{ decompressing ? '解压中...' : '解压验证' }}</button>

        <!-- Decompressed text -->
        <div v-if="decompressedText !== null && decompressedText === inputText" class="mt-3 rounded-lg bg-green-50 px-3 py-2 text-xs text-green-700 flex items-center gap-1">
          <svg class="w-4 h-4 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
          解压验证通过，数据完全一致
        </div>
        <div v-else-if="decompressedText !== null" class="mt-3 rounded-lg bg-rose-50 px-3 py-2 text-xs text-rose-700">
          解压结果与原文不一致，请检查数据
        </div>
      </div>
    </div>

    <!-- Character frequency bar chart -->
    <div v-if="charFreqs.length" class="mt-6 rounded-xl border border-slate-200 bg-white p-5">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-base font-semibold text-slate-800">字符频率分布（Top 20）</h2>
        <span class="text-xs text-slate-400">高频字符 → 最短编码</span>
      </div>
      <div class="space-y-1.5">
        <div v-for="item in charFreqs.slice(0, 20)" :key="item.char" class="flex items-center gap-2">
          <span class="w-10 text-center text-xs font-mono font-bold text-slate-700 bg-slate-100 rounded px-1 py-0.5 flex-shrink-0">{{ item.displayChar }}</span>
          <div class="flex-1 h-4 bg-slate-100 rounded overflow-hidden">
            <div class="h-full rounded" :style="{ width: item.pct + '%', background: item.color }"></div>
          </div>
          <span class="w-20 text-right text-xs text-slate-500 flex-shrink-0 tabular-nums">{{ item.freq }} 次</span>
        </div>
      </div>
      <p class="mt-3 text-xs text-slate-400">
        共 {{ uniqueChars }} 种字符 ·
        定长编码需 {{ fixedBits }} 位/字符 ·
        <span v-if="avgBits !== '-'">Huffman 平均 {{ avgBits }} 位/字符（节省 {{ Math.round((1 - avgBits / fixedBits / 8) * 100) }}% 空间）</span>
      </p>
    </div>

    <!-- Huffman principle card -->
    <div v-if="stats.algorithm" class="mt-6 rounded-xl border border-slate-200 bg-white p-5">
      <h2 class="text-base font-semibold text-slate-800 mb-2">哈夫曼编码原理</h2>
      <div class="prose prose-sm text-slate-600 max-w-none">
        <ol class="list-decimal list-inside space-y-1 ml-2">
          <li><strong>频率统计</strong>：扫描输入文本，统计每个字符出现的次数</li>
          <li><strong>构建最小堆</strong>：将所有字符按频率放入优先队列（最小堆），频率最低的节点在堆顶</li>
          <li><strong>合并建树</strong>：每次从堆中取出频率最低的两个节点，合并为父节点（频率=两者之和），放回堆中。重复直到只剩根节点</li>
          <li><strong>生成编码</strong>：从根节点遍历，左子树走位标记 0，右子树标记 1，叶子节点获得不等长编码。高频字符获得短编码，低频字符获得长编码</li>
          <li><strong>压缩</strong>：将原文每个字符替换为其哈夫曼编码，按位打包成字节流</li>
          <li><strong>解压</strong>：从频率表重建哈夫曼树，按位解码还原原文</li>
        </ol>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { tourismApi } from '@/services/tourismApi'

// 系统级压缩存储统计（真实数据库数据）
const systemStats = ref(null)
onMounted(async () => {
  try {
    systemStats.value = await tourismApi.diaryCompressionStats()
  } catch { /* 后端不可用时隐藏统计卡片 */ }
})

function formatBytes(bytes) {
  if (!bytes || bytes <= 0) return '0 B'
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / 1024 / 1024).toFixed(2) + ' MB'
}

const inputText = ref('')
const compressedB64 = ref('')
const decompressedText = ref(null)
const compressing = ref(false)
const decompressing = ref(false)

const stats = reactive({
  originalBytes: 0,
  compressedBytes: 0,
  ratio: '0.00',
  saved: '0.00',
  algorithm: ''
})

// Character frequency for bar chart (recomputed reactively from inputText)
const charFreqs = computed(() => {
  const text = inputText.value
  if (!text) return []
  const freq = {}
  for (const ch of text) freq[ch] = (freq[ch] || 0) + 1
  const sorted = Object.entries(freq).sort((a, b) => b[1] - a[1])
  const maxFreq = sorted[0]?.[1] || 1
  const colors = ['#0d9488', '#0891b2', '#7c3aed', '#db2777', '#ea580c', '#65a30d', '#ca8a04']
  return sorted.map(([ch, f], i) => ({
    char: ch,
    displayChar: ch === ' ' ? '空格' : ch === '\n' ? '换行' : ch === '\t' ? '制表' : ch,
    freq: f,
    pct: Math.round((f / maxFreq) * 100),
    color: colors[i % colors.length]
  }))
})
const uniqueChars = computed(() => charFreqs.value.length)
const fixedBits = computed(() => {
  const k = uniqueChars.value
  return k <= 1 ? 1 : Math.ceil(Math.log2(k))
})
const avgBits = computed(() => {
  if (!stats.originalBytes || !stats.compressedBytes) return '-'
  const chars = inputText.value.length
  return chars > 0 ? ((stats.compressedBytes * 8) / chars).toFixed(2) : '-'
})

function resetResults() {
  compressedB64.value = ''
  decompressedText.value = null
  stats.originalBytes = inputText.value.length
  stats.compressedBytes = 0
  stats.ratio = '0.00'
  stats.saved = '0.00'
  stats.algorithm = ''
}

async function doCompress() {
  if (!inputText.value) return
  compressing.value = true
  try {
    const data = await tourismApi.huffmanCompress({ content: inputText.value })
    compressedB64.value = data.compressed || ''
    stats.originalBytes = data.originalBytes || inputText.value.length
    stats.compressedBytes = data.compressedBytes || 0
    stats.ratio = (data.compressionRatio || 0).toFixed(2)
    stats.saved = (100 - (data.compressionRatio || 0)).toFixed(1)
    stats.algorithm = data.algorithm || 'huffman'
    decompressedText.value = null
  } catch {
    stats.algorithm = ''
  } finally {
    compressing.value = false
  }
}

async function doDecompress() {
  if (!compressedB64.value) return
  decompressing.value = true
  try {
    const data = await tourismApi.huffmanDecompress({ compressed: compressedB64.value })
    decompressedText.value = data.content || ''
  } catch {
    decompressedText.value = null
  } finally {
    decompressing.value = false
  }
}
</script>
