import { createRouter, createWebHistory } from 'vue-router'

const routes = [
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
    path: '/route',
    name: 'RoutePlan',
    component: () => import('@/views/RoutePlan.vue')
  },
  {
    path: '/diary',
    name: 'Diary',
    component: () => import('@/views/Diary.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
