import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/api'

export const useUserStore = defineStore('user', () => {
  // 状态
  const token = ref(localStorage.getItem('token') || '')
  const userInfo = ref(null)
  
  // 计算属性
  const isLoggedIn = computed(() => !!token.value)
  const username = computed(() => userInfo.value?.username || '')
  
  // 动作
  async function login(username, password) {
    try {
      const response = await api.auth.login({ account: username, password })
      if (response.code === 200) {
        token.value = response.data.token
        userInfo.value = response.data.user_info
        localStorage.setItem('token', token.value)
        return { success: true }
      }
      return { success: false, message: response.message }
    } catch (error) {
      return { success: false, message: '登录失败：' + error.message }
    }
  }
  
  async function fetchUserInfo() {
    try {
      const response = await api.user.getInfo()
      if (response.code === 200) {
        userInfo.value = response.data
        return { success: true }
      }
      return { success: false, message: response.message }
    } catch (error) {
      return { success: false, message: '获取用户信息失败' }
    }
  }
  
  function logout() {
    token.value = ''
    userInfo.value = null
    localStorage.removeItem('token')
  }
  
  return {
    token,
    userInfo,
    isLoggedIn,
    username,
    login,
    fetchUserInfo,
    logout
  }
})
