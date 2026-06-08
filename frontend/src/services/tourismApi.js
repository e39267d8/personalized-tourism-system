import axios from 'axios'
import { isAuthApiPath, safeRedirectPath } from '@/utils/auth'

const client = axios.create({
  baseURL: '/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

client.interceptors.request.use(
  config => {
    const token = typeof localStorage === 'undefined' ? '' : localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => Promise.reject(error)
)

client.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 401) {
      if (typeof localStorage !== 'undefined') localStorage.removeItem('token')
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new CustomEvent('tourism-auth:unauthorized'))
        const url = error.config?.url || ''
        const isLoginPage = window.location.pathname === '/login' || window.location.pathname === '/register'
        if (!isAuthApiPath(url) && !isLoginPage) {
          const redirect = encodeURIComponent(safeRedirectPath(window.location.pathname + window.location.search, '/'))
          window.location.href = `/login?redirect=${redirect}`
        }
      }
    }
    console.error('API request failed:', error.config?.url || error.message)
    return Promise.reject(error)
  }
)

const unwrap = (response) => response.data?.data ?? response.data

export const tourismApi = {
  register: (payload) => client.post('/auth/register', payload).then(unwrap),
  login: (payload) => client.post('/auth/login', payload).then(unwrap),
  logout: () => client.post('/auth/logout').then(unwrap),
  authMe: () => client.get('/auth/me').then(unwrap),
  changePassword: (payload) => client.post('/auth/change-password', payload).then(unwrap),
  dashboard: () => client.get('/dashboard').then(unwrap),
  scenicCategories: () => client.get('/scenic-categories').then(unwrap),
  scenicSpots: (params) => client.get('/scenic-spots', { params }).then(unwrap),
  searchSuggestions: (params) => client.get('/search/suggestions', { params }).then(unwrap),
  scenicSpot: (id) => client.get(`/scenic-spots/${id}`).then(unwrap),
  scenicSpotReviews: (id) => client.get(`/scenic-spots/${id}/reviews`).then(unwrap),
  scenicFacilities: (id, params) => client.get(`/scenic-spots/${id}/facilities`, { params }).then(unwrap),
  indoorBuildings: (id) => client.get(`/scenic-spots/${id}/indoor-buildings`).then(unwrap),
  indoorFeatures: (id, params) => client.get(`/indoor-buildings/${id}/features`, { params }).then(unwrap),
  planIndoorRoute: (id, payload) => client.post(`/indoor-buildings/${id}/routes/plan`, payload).then(unwrap),
  scenicInternalMap: (id) => client.get(`/scenic-spots/${id}/internal-map`).then(unwrap),
  planScenicInternalRoute: (id, payload) => client.post(`/scenic-spots/${id}/internal-routes/plan`, payload).then(unwrap),
  budgetPlans: (params) => client.get('/budget-plans', { params }).then(unwrap),
  routeNodes: () => client.get('/route-nodes').then(unwrap),
  routes: () => client.get('/routes').then(unwrap),
  planRoute: (payload) => client.post('/routes/plan', payload).then(unwrap),
  personalizedRecommendations: (payload) => client.post('/recommendations/personalized', payload).then(unwrap),
  diaries: (params) => client.get('/diaries', { params }).then(unwrap),
  diaryDetail: (id) => client.get(`/diaries/${id}`).then(unwrap),
  createDiary: (payload) => client.post('/diaries', payload).then(unwrap),
  updateDiary: (id, payload) => client.put(`/diaries/${id}`, payload).then(unwrap),
  deleteDiary: (id) => client.delete(`/diaries/${id}`).then(unwrap),
  likeDiary: (id) => client.post(`/diaries/${id}/like`).then(unwrap),
  unlikeDiary: (id) => client.delete(`/diaries/${id}/like`).then(unwrap),
  bookmarkDiary: (id) => client.post(`/diaries/${id}/bookmark`).then(unwrap),
  unbookmarkDiary: (id) => client.delete(`/diaries/${id}/bookmark`).then(unwrap),
  rateDiary: (id, score) => client.post(`/diaries/${id}/rating`, { score }).then(unwrap),
  diaryComments: (id, params) => client.get(`/diaries/${id}/comments`, { params }).then(unwrap),
  createComment: (diaryId, payload) => client.post(`/diaries/${diaryId}/comments`, payload).then(unwrap),
  deleteComment: (commentId) => client.delete(`/comments/${commentId}`).then(unwrap),
  achievements: () => client.get('/achievements').then(unwrap),
  checkinScenicSpot: (id, payload) => client.post(`/scenic-spots/${id}/checkins`, payload).then(unwrap),
  claimAchievement: (id) => client.post(`/achievements/${id}/claim`).then(unwrap),
  collectibles: () => client.get('/collectibles').then(unwrap),
  collectibleDetail: (id) => client.get(`/collectibles/${id}`).then(unwrap),
  redeemBadge: (payload) => client.post('/badge-redemptions', payload).then(unwrap),
  badgeRedemptions: () => client.get('/badge-redemptions').then(unwrap),
  submitAchievementReview: (diaryId) => client.post(`/diaries/${diaryId}/achievement-review`).then(unwrap),
  achievementReviewSubmissions: (params) => client.get('/achievement-review-submissions', { params }).then(unwrap),
  decideAchievementReview: (id, payload) => client.post(`/achievement-review-submissions/${id}/decision`, payload).then(unwrap),
  profile: () => client.get('/profile').then(unwrap),
  getProfilePreferences: () => client.get('/profile/preferences').then(unwrap),
  saveProfilePreferences: (payload) => client.put('/profile/preferences', payload).then(unwrap),
  deleteProfilePreferences: () => client.delete('/profile/preferences').then(unwrap),
  summarizeDiary: (payload) => client.post('/aigc/diary-summary', payload).then(unwrap),
  polishDiary: (payload) => client.post('/aigc/polish', payload).then(unwrap),
  imagePrompt: (payload) => client.post('/aigc/image-prompt', payload).then(unwrap),
  travelAgentChat: (payload) => client.post('/aigc/travel-chat', payload).then(unwrap),

  // 美食推荐
  foodRecommend: (params) => client.get('/foods', { params }).then(unwrap),
  foodCuisines: (params) => client.get('/foods/cuisines', { params }).then(unwrap),

  // 日记检索（倒排索引）
  searchDiaries: (params) => client.get('/diaries/search/fulltext', { params }).then(unwrap),
  searchDiaryByTitle: (params) => client.get('/diaries/search/title', { params }).then(unwrap),
  searchDiaryBySpot: (params) => client.get('/diaries/search/spot', { params }).then(unwrap),
  rebuildDiaryIndex: () => client.post('/diaries/index/rebuild').then(unwrap),

  // 哈夫曼压缩
  huffmanCompress: (payload) => client.post('/huffman/compress', payload).then(unwrap),
  huffmanDecompress: (payload) => client.post('/huffman/decompress', payload).then(unwrap),

  // TSP 多点环游
  tourRoute: (payload) => client.post('/routes/tour', payload).then(unwrap),

  // 拥挤度感知路由
  congestionRoute: (payload) => client.post('/routes/plan/congestion', payload).then(unwrap),
  congestionInfo: (params) => client.get('/routes/congestion', { params }).then(unwrap)
}
