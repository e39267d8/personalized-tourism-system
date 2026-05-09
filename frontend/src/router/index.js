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
    name: 'DiaryPlaza',
    component: () => import('@/views/Diary.vue')
  },
  {
    path: '/diary/new',
    name: 'DiaryCreate',
    component: () => import('@/views/DiaryEditor.vue')
  },
  {
    path: '/diary/edit/:id',
    name: 'DiaryEdit',
    component: () => import('@/views/DiaryEditor.vue'),
    props: route => ({ id: Number(route.params.id) })
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
