import { createRouter, createWebHistory } from 'vue-router'
import { authStore, isAuthenticated, restoreAuth } from '@/stores/auth'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue')
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('@/views/Register.vue')
  },
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/Home.vue')
  },
  {
    path: '/recommend',
    name: 'Recommendation',
    component: () => import('@/views/Recommendation.vue')
  },
  {
    path: '/search',
    name: 'Search',
    component: () => import('@/views/Search.vue')
  },
  {
    path: '/spots/:id',
    name: 'ScenicDetail',
    component: () => import('@/views/ScenicDetail.vue'),
    props: route => ({ id: Number(route.params.id) })
  },
  {
    path: '/route',
    name: 'RoutePlan',
    component: () => import('@/views/RoutePlan.vue')
  },
  {
    path: '/agent',
    name: 'TravelAgent',
    component: () => import('@/views/TravelAgent.vue')
  },
  {
    path: '/diary',
    name: 'DiaryPlaza',
    component: () => import('@/views/Diary.vue')
  },
  {
    path: '/diary/new',
    name: 'DiaryCreate',
    component: () => import('@/views/DiaryEditor.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/diary/edit/:id',
    name: 'DiaryEdit',
    component: () => import('@/views/DiaryEditor.vue'),
    props: route => ({ id: Number(route.params.id) }),
    meta: { requiresAuth: true }
  },
  {
    path: '/diary/:id',
    name: 'DiaryDetail',
    component: () => import('@/views/DiaryDetail.vue'),
    props: route => ({ id: Number(route.params.id) })
  },
  {
    path: '/achievements',
    name: 'Achievements',
    component: () => import('@/views/Achievements.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/profile',
    name: 'Profile',
    component: () => import('@/views/Profile.vue'),
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach(async (to) => {
  if (!authStore.initialized) await restoreAuth()

  if (to.meta.requiresAuth && !isAuthenticated()) {
    return { path: '/login', query: { redirect: to.fullPath } }
  }

  if ((to.path === '/login' || to.path === '/register') && isAuthenticated()) {
    const redirect = typeof to.query.redirect === 'string' ? to.query.redirect : '/profile'
    return redirect
  }

  return true
})

export default router
