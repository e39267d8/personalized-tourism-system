<template>
  <div class="diary-page">
    <h1 class="text-3xl font-bold mb-6">游记管理</h1>
    
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- 左侧：游记列表 -->
      <div class="lg:col-span-1 bg-white rounded-lg shadow-md p-6">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-xl font-semibold">我的游记</h2>
          <button 
            @click="showCreateDialog = true"
            class="bg-primary-600 hover:bg-primary-700 text-white px-4 py-2 rounded-md text-sm"
          >
            新建游记
          </button>
        </div>
        
        <!-- 搜索框 -->
        <div class="mb-4">
          <input 
            v-model="searchQuery"
            @keyup.enter="searchDiaries"
            type="text"
            placeholder="搜索游记..."
            class="w-full border rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
        </div>
        
        <!-- 游记列表 -->
        <div class="space-y-4 max-h-[600px] overflow-y-auto">
          <div 
            v-for="diary in diaries" 
            :key="diary.id"
            @click="viewDiary(diary.id)"
            class="border rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer"
          >
            <h3 class="font-semibold mb-2">{{ diary.title }}</h3>
            <p class="text-gray-600 text-sm mb-2 line-clamp-2">{{ diary.summary }}</p>
            <div class="flex items-center justify-between text-xs text-gray-500">
              <span>{{ diary.start_date }}</span>
              <div class="flex items-center space-x-2">
                <span>👁 {{ diary.view_count }}</span>
                <span>❤️ {{ diary.like_count }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- 右侧：游记详情/编辑器 -->
      <div class="lg:col-span-2 bg-white rounded-lg shadow-md p-6">
        <div v-if="selectedDiary" class="h-full">
          <h2 class="text-2xl font-bold mb-4">{{ selectedDiary.title }}</h2>
          
          <!-- 游记元信息 -->
          <div class="flex items-center space-x-4 text-sm text-gray-600 mb-6">
            <span>📅 {{ selectedDiary.start_date }} - {{ selectedDiary.end_date }}</span>
            <span>📍 {{ selectedDiary.visited_spots?.length || 0 }} 个景点</span>
            <span>📏 {{ selectedDiary.total_distance_km }} km</span>
          </div>
          
          <!-- 游记内容 -->
          <div class="prose max-w-none mb-6">
            <p>{{ selectedDiary.content }}</p>
          </div>
          
          <!-- 操作按钮 -->
          <div class="flex space-x-4">
            <button 
              @click="editDiary"
              class="bg-primary-600 hover:bg-primary-700 text-white px-4 py-2 rounded-md"
            >
              编辑
            </button>
            <button 
              @click="generateAIGC"
              class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md"
            >
              AI 润色
            </button>
            <button 
              @click="deleteDiary"
              class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md"
            >
              删除
            </button>
          </div>
        </div>
        
        <div v-else class="flex items-center justify-center h-full text-gray-400">
          <p>请选择一篇游记或创建新游记</p>
        </div>
      </div>
    </div>
    
    <!-- 新建/编辑对话框 -->
    <div v-if="showCreateDialog" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div class="p-6">
          <h2 class="text-2xl font-bold mb-4">新建游记</h2>
          
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">标题</label>
              <input 
                v-model="newDiary.title"
                type="text"
                class="w-full border rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">内容</label>
              <textarea 
                v-model="newDiary.content"
                rows="10"
                class="w-full border rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
              ></textarea>
            </div>
            
            <div class="flex space-x-4">
              <div class="flex-1">
                <label class="block text-sm font-medium text-gray-700 mb-1">开始日期</label>
                <input 
                  v-model="newDiary.start_date"
                  type="date"
                  class="w-full border rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>
              <div class="flex-1">
                <label class="block text-sm font-medium text-gray-700 mb-1">结束日期</label>
                <input 
                  v-model="newDiary.end_date"
                  type="date"
                  class="w-full border rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>
            </div>
          </div>
          
          <div class="flex justify-end space-x-4 mt-6">
            <button 
              @click="showCreateDialog = false"
              class="px-4 py-2 text-gray-600 hover:text-gray-800"
            >
              取消
            </button>
            <button 
              @click="createDiary"
              class="bg-primary-600 hover:bg-primary-700 text-white px-6 py-2 rounded-md"
            >
              保存
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '@/api'

const diaries = ref([])
const selectedDiary = ref(null)
const searchQuery = ref('')
const showCreateDialog = ref(false)
const newDiary = ref({
  title: '',
  content: '',
  start_date: '',
  end_date: ''
})

onMounted(async () => {
  await loadDiaries()
})

const loadDiaries = async () => {
  try {
    const response = await api.diary.list({ page: 1, page_size: 20 })
    if (response.code === 200) {
      diaries.value = response.data.items
    }
  } catch (error) {
    console.error('加载游记失败:', error)
  }
}

const searchDiaries = async () => {
  try {
    const response = await api.diary.search({ q: searchQuery.value })
    if (response.code === 200) {
      diaries.value = response.data.items
    }
  } catch (error) {
    console.error('搜索游记失败:', error)
  }
}

const viewDiary = async (id) => {
  try {
    const response = await api.diary.getDetail(id)
    if (response.code === 200) {
      selectedDiary.value = response.data
    }
  } catch (error) {
    console.error('加载游记详情失败:', error)
  }
}

const createDiary = async () => {
  try {
    const response = await api.diary.create(newDiary.value)
    if (response.code === 200) {
      showCreateDialog.value = false
      await loadDiaries()
      alert('游记创建成功')
    }
  } catch (error) {
    console.error('创建游记失败:', error)
    alert('创建失败，请稍后重试')
  }
}

const editDiary = () => {
  // TODO: 实现编辑功能
  alert('编辑功能待实现')
}

const generateAIGC = async () => {
  try {
    const response = await api.aigc.polish({
      content: selectedDiary.value.content,
      style: 'literary'
    })
    if (response.code === 200) {
      selectedDiary.value.content = response.data.polished
      alert('AI 润色完成')
    }
  } catch (error) {
    console.error('AI 润色失败:', error)
  }
}

const deleteDiary = async () => {
  if (!confirm('确定要删除这篇游记吗？')) return
  
  try {
    await api.diary.delete(selectedDiary.value.id)
    await loadDiaries()
    selectedDiary.value = null
    alert('游记已删除')
  } catch (error) {
    console.error('删除游记失败:', error)
    alert('删除失败，请稍后重试')
  }
}
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
