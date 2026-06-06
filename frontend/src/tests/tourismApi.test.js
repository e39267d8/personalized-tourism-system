/**
 * tourismApi.test.js
 * Frontend API tests using vitest
 * 
 * Tests API request construction, response handling, and error paths.
 * Run: cd frontend && npx vitest run src/tests/tourismApi.test.js
 */
import { describe, it, expect, vi, beforeEach } from 'vitest'

// Mock axios before importing the service
vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => mockAxiosInstance),
  },
  __esModule: true,
}))

const mockAxiosInstance = {
  get: vi.fn(),
  post: vi.fn(),
  put: vi.fn(),
  delete: vi.fn(),
}

// Reset mocks before each test
beforeEach(() => {
  Object.values(mockAxiosInstance).forEach(m => m.mockReset())
})

// Dynamic import to capture the mocked axios
let tourismApi
beforeEach(async () => {
  const mod = await import('@/services/tourismApi')
  tourismApi = mod.tourismApi
})

describe('tourismApi - Scenic Spots', () => {
  it('should request scenic spots with default params', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })
    await tourismApi.getScenicSpots()
    expect(mockAxiosInstance.get).toHaveBeenCalledWith(
      '/scenic-spots',
      expect.objectContaining({ params: expect.any(Object) })
    )
  })

  it('should request scenic spots with custom params', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })
    await tourismApi.getScenicSpots({ city: 'beijing', limit: 10, search: '故宫' })
    const call = mockAxiosInstance.get.mock.calls[0]
    expect(call[1].params.limit).toBe(10)
    expect(call[1].params.search).toBe('故宫')
  })

  it('should handle scenic spot detail', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: { id: 1, name: '故宫' } } })
    const result = await tourismApi.fetchScenicSpot(1)
    expect(result).toEqual({ id: 1, name: '故宫' })
  })

  it('should handle API errors for scenic spots', async () => {
    mockAxiosInstance.get.mockRejectedValue(new Error('Network error'))
    await expect(tourismApi.getScenicSpots()).rejects.toThrow()
  })
})

describe('tourismApi - Route Planning', () => {
  it('should plan a route with valid params', async () => {
    mockAxiosInstance.post.mockResolvedValue({ data: { data: { path: [1, 2, 3] } } })
    const result = await tourismApi.planRoute({
      start_id: 1, end_id: 10, travel_mode: 'walk', optimization: 'balanced'
    })
    expect(result).toEqual({ path: [1, 2, 3] })
    expect(mockAxiosInstance.post).toHaveBeenCalledWith(
      '/routes/plan',
      expect.objectContaining({ start_id: 1, end_id: 10 })
    )
  })

  it('should plan a tour (TSP) route', async () => {
    mockAxiosInstance.post.mockResolvedValue({
      data: { data: { route: [1, 2, 3], distance: 5000, algorithm: 'nearest_neighbor' } }
    })
    const result = await tourismApi.tourRoute({
      spot_ids: [1, 2, 3], travel_mode: 'walk', algorithm: 'nearest_neighbor'
    })
    expect(result.algorithm).toBe('nearest_neighbor')
  })
})

describe('tourismApi - Food Recommendation', () => {
  it('should get food recommendation with filters', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })
    await tourismApi.foodRecommend({ city: '北京', cuisine: '川菜', limit: 10, sort: 'rating' })
    const call = mockAxiosInstance.get.mock.calls[0]
    expect(call[1].params.cuisine).toBe('川菜')
    expect(call[1].params.sort).toBe('rating')
  })

  it('should get food cuisines list', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: ['川菜', '粤菜', '鲁菜'] } })
    const result = await tourismApi.foodCuisines()
    expect(result).toEqual(['川菜', '粤菜', '鲁菜'])
  })
})

describe('tourismApi - Diary Search', () => {
  it('should search diaries by fulltext', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })
    await tourismApi.searchDiaries({ q: '北京', mode: 'fulltext', limit: 20 })
    const call = mockAxiosInstance.get.mock.calls[0]
    expect(call[0]).toBe('/diaries/search/fulltext')
    expect(call[1].params.q).toBe('北京')
  })

  it('should search diaries by title', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })
    await tourismApi.searchDiaryByTitle({ q: '故宫游', limit: 5 })
    const call = mockAxiosInstance.get.mock.calls[0]
    expect(call[0]).toBe('/diaries/search/title')
  })

  it('should search diaries by scenic spot', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })
    await tourismApi.searchDiaryBySpot({ spot_id: 5, limit: 10 })
    const call = mockAxiosInstance.get.mock.calls[0]
    expect(call[1].params.spot_id).toBe(5)
  })
})

describe('tourismApi - Huffman Compression', () => {
  it('should compress text', async () => {
    mockAxiosInstance.post.mockResolvedValue({
      data: {
        data: {
          compressed: 'base64enc',
          original_size: 100,
          compressed_size: 65,
          compression_ratio: 0.35,
        }
      }
    })
    const result = await tourismApi.huffmanCompress({ text: 'Hello World' })
    expect(result.compression_ratio).toBe(0.35)
    expect(result.original_size).toBe(100)
  })

  it('should decompress text', async () => {
    mockAxiosInstance.post.mockResolvedValue({
      data: { data: { decompressed: 'Hello World' } }
    })
    const result = await tourismApi.huffmanDecompress({ data: 'base64enc' })
    expect(result.decompressed).toBe('Hello World')
  })
})

describe('tourismApi - AIGC', () => {
  it('should summarize a diary', async () => {
    mockAxiosInstance.post.mockResolvedValue({
      data: { data: { summary: '一次精彩的北京之旅' } }
    })
    const result = await tourismApi.summarizeDiary({ title: '北京', content: '...' })
    expect(result.summary).toBe('一次精彩的北京之旅')
  })

  it('should polish a diary', async () => {
    mockAxiosInstance.post.mockResolvedValue({
      data: { data: { polished: 'polished text' } }
    })
    const result = await tourismApi.polishDiary({ content: 'raw text' })
    expect(result.polished).toBe('polished text')
  })

  it('should generate image prompt', async () => {
    mockAxiosInstance.post.mockResolvedValue({
      data: { data: { promptEn: 'Beautiful scene', promptCn: '美景' } }
    })
    const result = await tourismApi.imagePrompt({ title: '北京', content: '' })
    expect(result.promptEn).toBe('Beautiful scene')
  })
})
