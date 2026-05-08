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
    path: '/diary',
    name: 'Diary',
    component: () => import('@/views/Diary.vue')
  },
  {
    path: '/achievements',
    name: 'Achievements',
    component: () => import('@/views/Achievements.vue')
  },
  {
    path: '/profile',
    name: 'Profile',
    component: () => import('@/views/Profile.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
