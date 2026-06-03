import { reactive } from 'vue'

// Simple reactive store for diary module state
export const diaryStore = reactive({
  // The diary just published by current user (shown first in plaza until sort/search resets)
  justPublished: null,
  // Current user info
  user: {
    nickname: '旅行者小林',
    avatar: ''
  }
})

export function setJustPublished(diary) {
  diaryStore.justPublished = diary
}

export function clearJustPublished() {
  diaryStore.justPublished = null
}
