<template>
  <div class="grid gap-6 xl:grid-cols-[0.72fr_1.28fr]">
    <aside class="space-y-6">
      <section class="rounded-md border border-slate-200 bg-white p-5">
        <div class="flex items-start justify-between gap-3">
          <div>
            <h1 class="text-2xl font-bold text-slate-950">旅行智能助手</h1>
            <p class="mt-2 text-sm leading-6 text-slate-500">
              输入目的地、预算和旅行偏好，助手会通过后端 API 调用真实大模型生成聊天回复和行程建议。
            </p>
          </div>
          <span class="rounded-md bg-teal-50 px-2.5 py-1 text-sm font-semibold text-teal-800">API</span>
        </div>

        <div class="mt-5 space-y-4">
          <div>
            <label class="text-sm font-semibold text-slate-700">目的地</label>
            <input
              v-model.trim="trip.destination"
              class="mt-2 h-10 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
              placeholder="例如：北京、杭州、成都"
            >
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="text-sm font-semibold text-slate-700">天数</label>
              <input
                v-model.number="trip.days"
                min="1"
                max="14"
                type="number"
                class="mt-2 h-10 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
              >
            </div>
            <div>
              <label class="text-sm font-semibold text-slate-700">预算</label>
              <input
                v-model.number="trip.budget"
                min="0"
                step="50"
                type="number"
                class="mt-2 h-10 w-full rounded-md border border-slate-300 px-3 text-sm outline-none focus:border-teal-700"
              >
            </div>
          </div>

          <div>
            <label class="text-sm font-semibold text-slate-700">旅行风格</label>
            <select v-model="trip.style" class="mt-2 h-10 w-full rounded-md border border-slate-300 bg-white px-3 text-sm outline-none focus:border-teal-700">
              <option value="balanced">均衡安排</option>
              <option value="culture">历史文化</option>
              <option value="food">美食优先</option>
              <option value="photo">拍照打卡</option>
              <option value="relaxed">轻松慢游</option>
            </select>
          </div>
        </div>
      </section>

      <section class="rounded-md border border-slate-200 bg-white p-5">
        <h2 class="text-lg font-semibold text-slate-950">快捷问题</h2>
        <div class="mt-4 grid gap-2">
          <button
            v-for="prompt in quickPrompts"
            :key="prompt"
            type="button"
            class="rounded-md bg-slate-50 px-3 py-2 text-left text-sm text-slate-600 hover:bg-teal-50 hover:text-teal-800"
            @click="usePrompt(prompt)"
          >
            {{ prompt }}
          </button>
        </div>
      </section>
    </aside>

    <section class="flex min-h-[660px] flex-col overflow-hidden rounded-md border border-slate-200 bg-white">
      <div class="flex items-center justify-between border-b border-slate-200 px-5 py-4">
        <div>
          <h2 class="text-lg font-semibold text-slate-950">对话规划</h2>
          <p class="mt-1 text-sm text-slate-500">{{ statusText }}</p>
        </div>
        <button
          type="button"
          class="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100"
          @click="resetChat"
        >
          清空
        </button>
      </div>

      <div ref="messagePane" class="flex-1 space-y-4 overflow-y-auto bg-slate-50 p-5">
        <article
          v-for="message in messages"
          :key="message.id"
          class="flex"
          :class="message.role === 'user' ? 'justify-end' : 'justify-start'"
        >
          <div
            class="max-w-[82%] rounded-md px-4 py-3 text-sm leading-7 shadow-sm"
            :class="message.role === 'user' ? 'bg-slate-900 text-white' : 'border border-slate-200 bg-white text-slate-700'"
          >
            <div class="mb-1 text-xs font-semibold" :class="message.role === 'user' ? 'text-slate-300' : 'text-teal-700'">
              {{ message.role === 'user' ? '你' : 'TourPilot 智能助手' }}
            </div>
            <div class="whitespace-pre-line">{{ message.content }}</div>
          </div>
        </article>
      </div>

      <div v-if="latestSuggestions.length" class="border-t border-slate-100 px-5 py-3">
        <div class="flex flex-wrap gap-2">
          <button
            v-for="suggestion in latestSuggestions"
            :key="suggestion"
            type="button"
            class="rounded-md bg-teal-50 px-2.5 py-1 text-xs font-medium text-teal-800 hover:bg-teal-100"
            @click="usePrompt(suggestion)"
          >
            {{ suggestion }}
          </button>
        </div>
      </div>

      <form class="border-t border-slate-200 p-4" @submit.prevent="sendMessage">
        <div class="flex flex-col gap-3 sm:flex-row">
          <textarea
            v-model.trim="draft"
            rows="2"
            class="min-h-14 flex-1 resize-none rounded-md border border-slate-300 px-3 py-2 text-sm leading-6 outline-none focus:border-teal-700"
            placeholder="例如：帮我规划一个北京三日游，想看博物馆、少排队、预算 1000 元"
            @keydown.enter.exact.prevent="sendMessage"
          />
          <button
            class="rounded-md bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:bg-slate-400"
            :disabled="loading || !draft"
          >
            {{ loading ? '思考中...' : '发送' }}
          </button>
        </div>
      </form>
    </section>
  </div>
</template>

<script setup>
import { computed, nextTick, reactive, ref } from 'vue'
import { tourismApi } from '@/services/tourismApi'

const trip = reactive({
  destination: '北京',
  days: 3,
  budget: 1000,
  style: 'balanced'
})

const messages = ref([
  {
    id: 1,
    role: 'assistant',
    content: '你好，我是 TourPilot 旅行智能助手。你可以告诉我目的地、天数、预算和兴趣点，我会帮你拆成可执行的旅行计划。'
  }
])
const draft = ref('帮我规划一个三日游，想兼顾经典景点、博物馆和轻松美食。')
const loading = ref(false)
const apiAvailable = ref(true)
const latestSuggestions = ref(['帮我把路线安排得更轻松', '推荐适合雨天的备选方案', '把预算压到 800 元以内'])
const messagePane = ref(null)

const quickPrompts = [
  '帮我规划一个第一次来北京的三日游',
  '我想低预算 citywalk，怎么安排？',
  '下雨天适合去哪几个室内景点？',
  '帮我生成一条适合拍照的路线'
]

const statusText = computed(() =>
  apiAvailable.value ? '已连接旅行规划 API' : 'API 暂不可用，请检查后端服务或大模型密钥配置'
)

const scrollToBottom = async () => {
  await nextTick()
  if (messagePane.value) {
    messagePane.value.scrollTop = messagePane.value.scrollHeight
  }
}

const appendMessage = (role, content) => {
  messages.value.push({
    id: Date.now() + Math.random(),
    role,
    content
  })
}

const sendMessage = async () => {
  if (!draft.value || loading.value) return
  const content = draft.value
  draft.value = ''
  appendMessage('user', content)
  loading.value = true
  await scrollToBottom()

  try {
    const response = await tourismApi.travelAgentChat({
      message: content,
      destination: trip.destination,
      days: trip.days,
      budget: trip.budget,
      style: trip.style,
      messages: messages.value.slice(-8).map(({ role, content }) => ({ role, content }))
    })
    apiAvailable.value = true
    appendMessage('assistant', response.reply || '大模型接口没有返回可显示的回复，请稍后重试。')
    latestSuggestions.value = response.suggestions?.length ? response.suggestions : latestSuggestions.value
  } catch (error) {
    apiAvailable.value = false
    const serverMessage = error.response?.data?.message
    appendMessage('assistant', `真实 API 请求失败：${serverMessage || error.message || '请检查后端服务和大模型密钥配置。'}`)
  } finally {
    loading.value = false
    await scrollToBottom()
  }
}

const usePrompt = (prompt) => {
  draft.value = prompt
}

const resetChat = () => {
  messages.value = [
    {
      id: Date.now(),
      role: 'assistant',
      content: '对话已清空。告诉我你的目的地、天数、预算和偏好，我会重新帮你规划。'
    }
  ]
  latestSuggestions.value = ['帮我做一版紧凑路线', '帮我做一版轻松路线', '推荐附近美食和交通方式']
  scrollToBottom()
}
</script>
