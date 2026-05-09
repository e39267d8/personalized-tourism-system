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
  diaries: (params) => client.get('/diaries', { params }).then(unwrap),
  createDiary: (payload) => client.post('/diaries', payload).then(unwrap),
  updateDiary: (id, payload) => client.put(`/diaries/${id}`, payload).then(unwrap),
  deleteDiary: (id) => client.delete(`/diaries/${id}`).then(unwrap),
  achievements: () => client.get('/achievements').then(unwrap),
  profile: () => client.get('/profile').then(unwrap),
  summarizeDiary: (payload) => client.post('/aigc/diary-summary', payload).then(unwrap)
}
