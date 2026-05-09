import axios from 'axios'

const client = axios.create({
  baseURL: '/api/v1',
  timeout: 5000,
  headers: {
    'Content-Type': 'application/json'
  }
})

const unwrap = (response) => response.data?.data ?? response.data

export const tourismApi = {
  dashboard: () => client.get('/dashboard').then(unwrap),
  scenicSpots: (params) => client.get('/scenic-spots', { params }).then(unwrap),
  searchSuggestions: (params) => client.get('/search/suggestions', { params }).then(unwrap),
  scenicSpot: (id) => client.get(`/scenic-spots/${id}`).then(unwrap),
  scenicSpotReviews: (id) => client.get(`/scenic-spots/${id}/reviews`).then(unwrap),
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
  profile: () => client.get('/profile').then(unwrap),
  getProfilePreferences: () => client.get('/profile/preferences').then(unwrap),
  saveProfilePreferences: (payload) => client.put('/profile/preferences', payload).then(unwrap),
  deleteProfilePreferences: () => client.delete('/profile/preferences').then(unwrap),
  summarizeDiary: (payload) => client.post('/aigc/diary-summary', payload).then(unwrap)
}
