export const scenicSpots = [
  {
    id: 1,
    name: '故宫博物院',
    category: '历史古迹',
    district: '东城',
    rating: 4.8,
    duration: '4 小时',
    ticket: 60,
    crowd: '高',
    tags: ['世界遗产', '中轴线', '亲子'],
    image: 'https://images.unsplash.com/photo-1624193367099-c65ec0976e7e?auto=format&fit=crop&w=1200&q=80',
    description: '明清皇家宫殿建筑群，适合做历史文化路线的核心节点。'
  },
  {
    id: 2,
    name: '天安门广场',
    category: '城市地标',
    district: '东城',
    rating: 4.6,
    duration: '1 小时',
    ticket: 0,
    crowd: '中',
    tags: ['地标', '步行', '摄影'],
    image: 'https://images.unsplash.com/photo-1599571234909-29ed5d1321d6?auto=format&fit=crop&w=1200&q=80',
    description: '北京中轴线上的开放式城市广场，可与故宫、前门串联。'
  },
  {
    id: 3,
    name: '景山公园',
    category: '观景摄影',
    district: '西城',
    rating: 4.55,
    duration: '1.5 小时',
    ticket: 2,
    crowd: '低',
    tags: ['日落', '俯瞰故宫', '轻徒步'],
    image: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
    description: '登上万春亭可以俯瞰故宫和北京中轴线。'
  },
  {
    id: 4,
    name: '国家博物馆',
    category: '博物馆',
    district: '东城',
    rating: 4.7,
    duration: '3 小时',
    ticket: 0,
    crowd: '中',
    tags: ['室内', '展览', '低预算'],
    image: 'https://images.unsplash.com/photo-1566054757965-8c4085344c96?auto=format&fit=crop&w=1200&q=80',
    description: '大型综合博物馆，适合文化主题推荐和雨天室内路线。'
  },
  {
    id: 5,
    name: '前门大街',
    category: '商业街区',
    district: '东城',
    rating: 4.3,
    duration: '2 小时',
    ticket: 0,
    crowd: '中',
    tags: ['美食', '夜游', '购物'],
    image: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=80',
    description: '传统商业街区，可作为餐饮和夜游节点。'
  },
  {
    id: 6,
    name: '鼓楼与什刹海',
    category: '城市漫步',
    district: '西城',
    rating: 4.4,
    duration: '2.5 小时',
    ticket: 20,
    crowd: '低',
    tags: ['胡同', 'citywalk', '摄影'],
    image: 'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?auto=format&fit=crop&w=1200&q=80',
    description: '老城地标与水岸街区，适合慢行和摄影。'
  }
]

export const routePlans = [
  {
    id: 1,
    title: '中轴线经典一日',
    stops: ['前门大街', '天安门广场', '故宫博物院', '景山公园'],
    distance: '5.2 km',
    time: '7 小时',
    cost: 92,
    intensity: '中',
    transport: '步行 + 地铁',
    bestFor: '初次来北京、历史文化'
  },
  {
    id: 2,
    title: '低预算室内文化线',
    stops: ['国家博物馆', '天安门东', '王府井'],
    distance: '2.1 km',
    time: '4 小时',
    cost: 48,
    intensity: '低',
    transport: '步行',
    bestFor: '学生、雨天、轻松游'
  },
  {
    id: 3,
    title: '鼓楼北海摄影线',
    stops: ['鼓楼', '什刹海', '北海公园', '景山公园'],
    distance: '3.8 km',
    time: '5 小时',
    cost: 52,
    intensity: '中',
    transport: '步行 + 骑行',
    bestFor: '摄影、citywalk、日落'
  }
]

export const budgetPlans = [
  {
    id: 'lite',
    label: '轻预算',
    budget: 80,
    title: '免费展览 + 城市漫步',
    route: '国家博物馆 -> 天安门广场 -> 前门大街',
    includes: ['门票 0 元', '餐饮约 45 元', '交通约 12 元'],
    tradeoff: '景点密度适中，主要靠步行和公共交通。'
  },
  {
    id: 'balanced',
    label: '平衡型',
    budget: 180,
    title: '中轴线完整体验',
    route: '前门 -> 天安门 -> 故宫 -> 景山',
    includes: ['核心门票约 62 元', '餐饮约 80 元', '交通约 20 元'],
    tradeoff: '体验完整，适合课程演示和首次旅游用户。'
  },
  {
    id: 'comfort',
    label: '舒适型',
    budget: 360,
    title: '少排队 + 好餐厅 + 轻交通',
    route: '故宫 -> 景山 -> 王府井餐饮',
    includes: ['预约优先级', '餐饮约 180 元', '打车/骑行约 80 元'],
    tradeoff: '成本更高，但减少转场压力。'
  }
]

export const diaries = [
  {
    id: 1,
    title: '中轴线一日游：从前门到景山',
    date: '2026-04-12',
    distance: '5.2 km',
    mood: '充实',
    cover: scenicSpots[0].image,
    tags: ['历史', '一日游', '中轴线'],
    excerpt: '上午从前门出发，经过天安门广场进入故宫，下午登上景山看完整条中轴线。',
    stats: { views: 430, likes: 38, comments: 6 }
  },
  {
    id: 2,
    title: '博物馆和王府井的轻松半日',
    date: '2026-04-18',
    distance: '2.1 km',
    mood: '放松',
    cover: scenicSpots[3].image,
    tags: ['博物馆', '低预算', '夜游'],
    excerpt: '白天看展，傍晚去王府井吃饭购物，适合预算有限但想把体验做完整的路线。',
    stats: { views: 360, likes: 31, comments: 4 }
  },
  {
    id: 3,
    title: '鼓楼到北海的 citywalk',
    date: '2026-04-26',
    distance: '3.8 km',
    mood: '治愈',
    cover: scenicSpots[5].image,
    tags: ['摄影', 'citywalk', '公园'],
    excerpt: '从鼓楼出发，经什刹海到北海公园，最后到景山看日落，节奏很舒服。',
    stats: { views: 290, likes: 24, comments: 3 }
  }
]

export const achievements = [
  {
    id: 1,
    name: '中轴线探索者',
    level: 'Lv.1',
    progress: 100,
    status: '已解锁',
    description: '完成包含前门、天安门、故宫、景山的路线。'
  },
  {
    id: 2,
    name: '博物馆爱好者',
    level: 'Lv.1',
    progress: 75,
    status: '进行中',
    description: '收藏或评价 3 个博物馆类景点。'
  },
  {
    id: 3,
    name: '城市漫步达人',
    level: 'Lv.2',
    progress: 60,
    status: '进行中',
    description: '完成一条 3 公里以上 citywalk 路线并发布游记。'
  },
  {
    id: 4,
    name: '预算规划师',
    level: 'Lv.2',
    progress: 35,
    status: '未解锁',
    description: '连续 3 次生成预算内路线，并完成实际支出记录。'
  }
]

export const dashboardStats = [
  { label: '演示景点', value: '8', detail: '含地理坐标与标签' },
  { label: '路线边', value: '32', detail: '支持 Dijkstra 演示' },
  { label: '游记样例', value: '3', detail: '可编辑可扩展' },
  { label: '成就徽章', value: '4', detail: '适合答辩展示' }
]
