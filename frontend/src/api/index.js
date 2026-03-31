import axios from 'axios'

// 创建 axios 实例
const api = axios.create({
  baseURL: '/api/v1',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器
api.interceptors.request.use(
  config => {
    // 添加认证 token
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => {
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
api.interceptors.response.use(
  response => {
    return response.data
  },
  error => {
    console.error('响应错误:', error)
    
    // 处理认证错误
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/login'
    }
    
    return Promise.reject(error)
  }
)

// API 接口定义
export default {
  // 认证模块
  auth: {
    login: (data) => api.post('/auth/login', data),
    register: (data) => api.post('/auth/register', data),
    refresh: (data) => api.post('/auth/refresh', data)
  },
  
  // 用户模块
  user: {
    getInfo: () => api.get('/users/me'),
    updatePreferences: (data) => api.put('/users/me/preferences', data)
  },
  
  // 景点模块
  scenic: {
    list: (params) => api.get('/scenic-spots', { params }),
    getDetail: (id) => api.get(`/scenic-spots/${id}`),
    search: (params) => api.get('/scenic-spots/search', { params })
  },
  
  // 推荐模块
  recommendation: {
    getPersonalized: (params) => api.get('/recommendations/scenic-spots', { params }),
    getHotSpots: (params) => api.get('/recommendations/hot-spots', { params })
  },
  
  // 路径规划模块
  route: {
    plan: (data) => api.post('/routes/plan', data),
    multiSpot: (data) => api.post('/routes/multi-spot', data),
    recalculate: (data) => api.post('/routes/recalculate', data)
  },
  
  // 周边查询模块
  nearby: {
    scenicSpots: (params) => api.get('/nearby/scenic-spots', { params }),
    facilities: (params) => api.get('/nearby/facilities', { params }),
    nearest: (type, params) => api.get(`/nearby/nearest/${type}`, { params })
  },
  
  // 游记模块
  diary: {
    list: (params) => api.get('/diaries', { params }),
    getDetail: (id) => api.get(`/diaries/${id}`),
    create: (data) => api.post('/diaries', data),
    update: (id, data) => api.put(`/diaries/${id}`, data),
    delete: (id) => api.delete(`/diaries/${id}`),
    search: (params) => api.get('/diaries/search', { params })
  },
  
  // AIGC 模块
  aigc: {
    generateSummary: (data) => api.post('/aigc/diary-summary', data),
    generateTitles: (data) => api.post('/aigc/diary-titles', data),
    polish: (data) => api.post('/aigc/polish', data)
  },
  
  // 评论模块
  review: {
    list: (params) => api.get('/reviews', { params }),
    create: (data) => api.post('/reviews', data),
    toggleHelpful: (id, data) => api.post(`/reviews/${id}/helpful`, data)
  }
}
