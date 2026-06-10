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
  interceptors: {
    request: { use: vi.fn() },
    response: { use: vi.fn() },
  },
}

// Reset mocks before each test
beforeEach(() => {
  mockAxiosInstance.get.mockReset()
  mockAxiosInstance.post.mockReset()
  mockAxiosInstance.put.mockReset()
  mockAxiosInstance.delete.mockReset()
  mockAxiosInstance.interceptors.request.use.mockReset()
  mockAxiosInstance.interceptors.response.use.mockReset()
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
    await tourismApi.scenicSpots()
    expect(mockAxiosInstance.get).toHaveBeenCalledWith(
      '/scenic-spots',
      { params: undefined }
    )
  })

  it('should request scenic spots with custom params', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })
    await tourismApi.scenicSpots({ city: 'beijing', limit: 10, q: '故宫' })
    const call = mockAxiosInstance.get.mock.calls[0]
    expect(call[1].params.limit).toBe(10)
    expect(call[1].params.q).toBe('故宫')
  })

  it('should handle scenic spot detail', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: { id: 1, name: '故宫' } } })
    const result = await tourismApi.scenicSpot(1)
    expect(result).toEqual({ id: 1, name: '故宫' })
  })

  it('should handle API errors for scenic spots', async () => {
    mockAxiosInstance.get.mockRejectedValue(new Error('Network error'))
    await expect(tourismApi.scenicSpots()).rejects.toThrow()
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
    await tourismApi.searchDiaryByTitle({ title: '故宫游', limit: 5 })
    const call = mockAxiosInstance.get.mock.calls[0]
    expect(call[0]).toBe('/diaries/search/title')
    expect(call[1].params.title).toBe('故宫游')
  })

  it('should search diaries by scenic spot', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })
    await tourismApi.searchDiaryBySpot({ scenic_spot_id: 5, limit: 10 })
    const call = mockAxiosInstance.get.mock.calls[0]
    expect(call[1].params.scenic_spot_id).toBe(5)
  })
})

describe('tourismApi - Huffman Compression', () => {
  it('should fetch diary compression details', async () => {
    mockAxiosInstance.get.mockResolvedValue({
      data: {
        data: {
          diaryId: 7,
          algorithm: 'huffman',
          originalBytes: 100,
          compressedBytes: 65,
          compressionRatio: 65,
          verified: true
        }
      }
    })
    const result = await tourismApi.diaryCompression(7)
    expect(result.compressionRatio).toBe(65)
    expect(result.originalBytes).toBe(100)
    expect(mockAxiosInstance.get).toHaveBeenCalledWith('/diaries/7/compression')
  })

  it('should compress text', async () => {
    mockAxiosInstance.post.mockResolvedValue({
      data: {
        data: {
          compressed: 'base64enc',
          algorithm: 'huffman',
          originalBytes: 100,
          compressedBytes: 65,
          compressionRatio: 65,
        }
      }
    })
    const result = await tourismApi.huffmanCompress({ content: 'Hello World' })
    expect(result.compressionRatio).toBe(65)
    expect(result.originalBytes).toBe(100)
  })

  it('should decompress text', async () => {
    mockAxiosInstance.post.mockResolvedValue({
      data: { data: { content: 'Hello World', originalBytes: 11 } }
    })
    const result = await tourismApi.huffmanDecompress({ compressed: 'base64enc' })
    expect(result.content).toBe('Hello World')
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
