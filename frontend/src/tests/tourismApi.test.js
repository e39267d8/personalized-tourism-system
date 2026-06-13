/**
 * tourismApi.test.js
 * 使用 Vitest 校验前端 API 客户端的请求路径、payload 和响应解包。
 */
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mockAxiosInstance = vi.hoisted(() => ({
  get: vi.fn(),
  post: vi.fn(),
  put: vi.fn(),
  delete: vi.fn(),
  interceptors: {
    request: { use: vi.fn() },
    response: { use: vi.fn() }
  }
}))

vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => mockAxiosInstance)
  },
  __esModule: true
}))

let tourismApi

beforeEach(async () => {
  vi.resetModules()
  mockAxiosInstance.get.mockReset()
  mockAxiosInstance.post.mockReset()
  mockAxiosInstance.put.mockReset()
  mockAxiosInstance.delete.mockReset()
  mockAxiosInstance.interceptors.request.use.mockReset()
  mockAxiosInstance.interceptors.response.use.mockReset()

  const mod = await import('@/services/tourismApi')
  tourismApi = mod.tourismApi
})

describe('tourismApi - 景点', () => {
  it('请求景点列表时保留默认参数', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })

    await tourismApi.scenicSpots()

    expect(mockAxiosInstance.get).toHaveBeenCalledWith('/scenic-spots', { params: undefined })
  })

  it('请求景点列表时透传筛选参数', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })

    await tourismApi.scenicSpots({ city: '北京', limit: 10, q: '故宫' })

    const [, options] = mockAxiosInstance.get.mock.calls[0]
    expect(options.params).toMatchObject({ city: '北京', limit: 10, q: '故宫' })
  })

  it('读取景点详情并解包 data 字段', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: { id: 1, name: '故宫' } } })

    const result = await tourismApi.scenicSpot(1)

    expect(result).toEqual({ id: 1, name: '故宫' })
    expect(mockAxiosInstance.get).toHaveBeenCalledWith('/scenic-spots/1')
  })

  it('请求景点内部设施', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [{ id: 3, name: '游客中心' }] } })

    const result = await tourismApi.scenicFacilities(9, { type: 'toilet' })

    expect(result[0].name).toBe('游客中心')
    expect(mockAxiosInstance.get).toHaveBeenCalledWith('/scenic-spots/9/facilities', {
      params: { type: 'toilet' }
    })
  })
})

describe('tourismApi - 路线规划', () => {
  it('规划普通路线', async () => {
    mockAxiosInstance.post.mockResolvedValue({ data: { data: { path: [1, 2, 3] } } })

    const payload = { start_id: 1, end_id: 10, travel_mode: 'walk', optimization: 'balanced' }
    const result = await tourismApi.planRoute(payload)

    expect(result).toEqual({ path: [1, 2, 3] })
    expect(mockAxiosInstance.post).toHaveBeenCalledWith('/routes/plan', payload)
  })

  it('规划 TSP 多点路线', async () => {
    mockAxiosInstance.post.mockResolvedValue({
      data: { data: { route: [1, 2, 3], distance: 5000, algorithm: 'nearest_neighbor' } }
    })

    const payload = { nodeIds: [1, 2, 3], travelMode: 'walking', optimization: 'nearest_neighbor' }
    const result = await tourismApi.tourRoute(payload)

    expect(result.algorithm).toBe('nearest_neighbor')
    expect(mockAxiosInstance.post).toHaveBeenCalledWith('/routes/tour', payload)
  })

  it('规划拥挤度感知路线', async () => {
    mockAxiosInstance.post.mockResolvedValue({ data: { data: { route: [], score: 0.82 } } })

    const payload = { start_id: 1, end_id: 2, avoid_crowds: true }
    const result = await tourismApi.congestionRoute(payload)

    expect(result.score).toBe(0.82)
    expect(mockAxiosInstance.post).toHaveBeenCalledWith('/routes/plan/congestion', payload)
  })

  it('规划室内跨层路线', async () => {
    mockAxiosInstance.post.mockResolvedValue({ data: { data: { segments: [], floorChanges: 1 } } })

    const payload = { start_feature_id: 11, end_feature_id: 18 }
    const result = await tourismApi.planCrossLayerRoute(5, payload)

    expect(result.floorChanges).toBe(1)
    expect(mockAxiosInstance.post).toHaveBeenCalledWith('/indoor-buildings/5/routes/plan-cross', payload)
  })
})

describe('tourismApi - 美食推荐', () => {
  it('带筛选条件获取美食推荐', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })

    await tourismApi.foodRecommend({
      scenic_spot_id: 8,
      q: '咖啡',
      cuisine: 'coffee_shop',
      limit: 10,
      sort: 'distance',
      lat: 39.9928,
      lng: 116.3103
    })

    const [, options] = mockAxiosInstance.get.mock.calls[0]
    expect(options.params).toMatchObject({
      scenic_spot_id: 8,
      q: '咖啡',
      cuisine: 'coffee_shop',
      limit: 10,
      sort: 'distance',
      lat: 39.9928,
      lng: 116.3103
    })
  })

  it('按景点或学校获取菜系列表', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: ['川菜', '粤菜', '鲁菜'] } })

    const result = await tourismApi.foodCuisines({ scenic_spot_id: 8 })

    expect(result).toEqual(['川菜', '粤菜', '鲁菜'])
    expect(mockAxiosInstance.get).toHaveBeenCalledWith('/foods/cuisines', { params: { scenic_spot_id: 8 } })
  })
})

describe('tourismApi - 游记', () => {
  it('创建游记时保留 videos 字段', async () => {
    mockAxiosInstance.post.mockResolvedValue({ data: { data: { id: 8, videos: ['https://example.com/v.mp4'] } } })

    const payload = { title: '北海一日', content: '湖边散步', videos: ['https://example.com/v.mp4'] }
    const result = await tourismApi.createDiary(payload)

    expect(result.videos).toEqual(['https://example.com/v.mp4'])
    expect(mockAxiosInstance.post).toHaveBeenCalledWith('/diaries', payload)
  })

  it('更新游记时保留 videos 字段', async () => {
    mockAxiosInstance.put.mockResolvedValue({ data: { data: { id: 8, videos: [] } } })

    const payload = { title: '更新标题', videos: [] }
    await tourismApi.updateDiary(8, payload)

    expect(mockAxiosInstance.put).toHaveBeenCalledWith('/diaries/8', payload)
  })

  it('生成日记动画分镜', async () => {
    mockAxiosInstance.post.mockResolvedValue({
      data: { data: { title: '北海一日', caption: '旅行动画预览', scenes: [{ caption: '湖边散步' }] } }
    })

    const result = await tourismApi.generateDiaryAnimation(8)

    expect(result.scenes).toHaveLength(1)
    expect(mockAxiosInstance.post).toHaveBeenCalledWith('/diaries/8/animation')
  })
})

describe('tourismApi - 游记搜索', () => {
  it('全文搜索游记', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })

    await tourismApi.searchDiaries({ q: '北京', mode: 'fulltext', limit: 20 })

    const [url, options] = mockAxiosInstance.get.mock.calls[0]
    expect(url).toBe('/diaries/search/fulltext')
    expect(options.params.q).toBe('北京')
  })

  it('按标题搜索游记', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })

    await tourismApi.searchDiaryByTitle({ title: '故宫游', limit: 5 })

    const [url, options] = mockAxiosInstance.get.mock.calls[0]
    expect(url).toBe('/diaries/search/title')
    expect(options.params.title).toBe('故宫游')
  })

  it('按景点搜索游记', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: [] } })

    await tourismApi.searchDiaryBySpot({ scenic_spot_id: 5, limit: 10 })

    expect(mockAxiosInstance.get).toHaveBeenCalledWith('/diaries/search/spot', {
      params: { scenic_spot_id: 5, limit: 10 }
    })
  })
})

describe('tourismApi - Huffman 压缩', () => {
  it('读取单篇游记压缩详情', async () => {
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
    expect(mockAxiosInstance.get).toHaveBeenCalledWith('/diaries/7/compression')
  })

  it('读取压缩统计', async () => {
    mockAxiosInstance.get.mockResolvedValue({ data: { data: { diaryCount: 12, compressedCount: 10 } } })

    const result = await tourismApi.diaryCompressionStats()

    expect(result.compressedCount).toBe(10)
    expect(mockAxiosInstance.get).toHaveBeenCalledWith('/diaries/compression/stats')
  })

  it('触发压缩迁移', async () => {
    mockAxiosInstance.post.mockResolvedValue({ data: { data: { migrated: 3 } } })

    const result = await tourismApi.migrateDiaryCompression()

    expect(result.migrated).toBe(3)
    expect(mockAxiosInstance.post).toHaveBeenCalledWith('/diaries/compression/migrate')
  })

  it('压缩文本', async () => {
    mockAxiosInstance.post.mockResolvedValue({
      data: { data: { compressed: 'base64enc', algorithm: 'huffman', originalBytes: 100, compressedBytes: 65 } }
    })

    const result = await tourismApi.huffmanCompress({ content: 'Hello World' })

    expect(result.compressedBytes).toBe(65)
    expect(mockAxiosInstance.post).toHaveBeenCalledWith('/huffman/compress', { content: 'Hello World' })
  })

  it('解压文本', async () => {
    mockAxiosInstance.post.mockResolvedValue({ data: { data: { content: 'Hello World', originalBytes: 11 } } })

    const result = await tourismApi.huffmanDecompress({ compressed: 'base64enc' })

    expect(result.content).toBe('Hello World')
    expect(mockAxiosInstance.post).toHaveBeenCalledWith('/huffman/decompress', { compressed: 'base64enc' })
  })
})

describe('tourismApi - AIGC', () => {
  it('总结游记', async () => {
    mockAxiosInstance.post.mockResolvedValue({ data: { data: { summary: '一次精彩的北京之旅' } } })

    const result = await tourismApi.summarizeDiary({ title: '北京', content: '...' })

    expect(result.summary).toBe('一次精彩的北京之旅')
  })

  it('润色游记', async () => {
    mockAxiosInstance.post.mockResolvedValue({ data: { data: { polished: '润色后的正文' } } })

    const result = await tourismApi.polishDiary({ content: '原始正文' })

    expect(result.polished).toBe('润色后的正文')
  })

  it('生成配图提示词', async () => {
    mockAxiosInstance.post.mockResolvedValue({ data: { data: { promptEn: 'Beautiful scene', promptCn: '美景' } } })

    const result = await tourismApi.imagePrompt({ title: '北京', content: '' })

    expect(result.promptEn).toBe('Beautiful scene')
  })
})
