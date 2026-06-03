import { diaryImages } from './imageCatalog'

// Local demo data keeps the app usable when the C++ API is not running.
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
    image: '/images/diary/gugong_0.jpg',
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
    image: '/images/diary/qianmen_0.jpg',
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
    image: '/images/diary/jingshangongyuan_0.jpg',
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
    image: '/images/diary/guojiabowuguan_0.jpeg',
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
    image: '/images/diary/qianmen_1.jpg',
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
    image: '/images/diary/shichahai_0.jpg',
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
    tradeoff: '体验完整，适合首次到访的旅行者。'
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
    location: '北京东城',
    mood: '充实',
    cover: diaryImages['1_cover'],
    images: [diaryImages['1_0'], diaryImages['1_1'], diaryImages['1_2']],
    tags: ['历史', '一日游', '中轴线'],
    excerpt: '上午从前门出发，经过天安门广场进入故宫，下午登上景山看完整条中轴线。',
    content: '<h2>从前门启程</h2><p>清晨七点半从前门大街出发，阳光刚刚铺满整条街道。走过正阳门箭楼，穿越地下通道就到了天安门广场。广场上已经有不少游人，但清晨的空气依然清冽。</p><h2>故宫深处</h2><p>从午门进入故宫，沿着中轴线一路向北。太和殿的恢弘让人屏息，御花园的精致又让人流连。在东六宫偶遇了一只晒太阳的故宫猫。</p><p>建议提前网上预约，避开周末和节假日。带好水和干粮，里面走一圈下来至少三个小时。</p><h2>景山远眺</h2><p>从故宫北门出来直奔景山公园，登顶后俯瞰整条中轴线，故宫的黄色琉璃瓦在阳光下金光闪闪。这是北京最值得的俯瞰角度之一。</p>',
    author: { nickname: '城市漫步者', avatar: '' },
    stats: { views: 430, likes: 38, comments: 6 },
    ratingScore: 4.6,
    ratingCount: 12,
    bookmarkCount: 15
  },
  {
    id: 2,
    title: '博物馆和王府井的轻松半日',
    date: '2026-04-18',
    location: '北京王府井',
    mood: '放松',
    cover: diaryImages['2_cover'],
    images: [diaryImages['2_0'], diaryImages['2_1'], diaryImages['2_2']],
    tags: ['博物馆', '低预算', '夜游'],
    excerpt: '白天看展，傍晚去王府井吃饭购物，适合预算有限但想把体验做完整的路线。',
    content: '<h2>国博之旅</h2><p>国家博物馆永远是北京最值得反复去的地方。这次特意去看了古代中国展和最新的临时特展。免费预约，性价比极高。</p><h2>王府井美食</h2><p>从博物馆步行到王府井大约20分钟。避开商业化严重的小吃街，转入胡同里的老北京涮肉馆。铜锅清汤，手切鲜羊肉，人均不过百元。</p>',
    author: { nickname: '旅行小白', avatar: '' },
    stats: { views: 360, likes: 31, comments: 4 },
    ratingScore: 4.2,
    ratingCount: 8,
    bookmarkCount: 9
  },
  {
    id: 3,
    title: '鼓楼到北海的 citywalk',
    date: '2026-04-26',
    location: '北京什刹海',
    mood: '治愈',
    cover: diaryImages['3_cover'],
    images: [diaryImages['3_0'], diaryImages['3_1'], diaryImages['3_2'], diaryImages['3_3']],
    tags: ['摄影', 'citywalk', '公园'],
    excerpt: '从鼓楼出发，经什刹海到北海公园，最后到景山看日落，节奏很舒服。',
    content: '<h2>鼓楼晨光</h2><p>选择了一个工作日的清晨出发，鼓楼周围游客稀少。钟鼓楼之间的广场上，老北京人在晨练。阳光斜射在红墙上，特别适合拍照。</p><h2>什刹海漫步</h2><p>沿着烟袋斜街走到什刹海，湖面上偶尔有野鸭游过。春天的柳树刚刚抽芽，嫩绿映在水面上。银锭桥上远望西山，果然名不虚传。</p><h2>北海公园</h2><p>穿过后门进入北海公园，白塔倒映在碧水中。租了一条小船划了半小时，湖心岛上的琼华岛值得细逛。</p>',
    author: { nickname: '胡同猎人', avatar: '' },
    stats: { views: 290, likes: 24, comments: 3 },
    ratingScore: 4.8,
    ratingCount: 15,
    bookmarkCount: 22
  },
  {
    id: 4,
    title: '颐和园春日长廊漫记',
    date: '2026-05-02',
    location: '北京海淀',
    mood: '惬意',
    cover: diaryImages['4_cover'],
    images: [diaryImages['4_0'], diaryImages['4_1']],
    tags: ['皇家园林', '春游', '摄影'],
    excerpt: '昆明湖畔走长廊，佛香阁上望西山。春风十里，不如颐和园的一步一景。',
    content: '<h2>东宫门入园</h2><p>选择从东宫门进入，穿过仁寿殿直奔昆明湖。五月初的颐和园，玉兰和海棠正盛。长廊上的彩绘故事看不完，每一幅都是一段历史。</p><h2>佛香阁远眺</h2><p>爬上万寿山，从佛香阁俯瞰整个昆明湖，视野开阔到让人忘却城市的喧嚣。十七孔桥静卧湖面，美得像一幅工笔画。</p>',
    author: { nickname: '园林探索家', avatar: '' },
    stats: { views: 520, likes: 45, comments: 8 },
    ratingScore: 4.5,
    ratingCount: 18,
    bookmarkCount: 30
  },
  {
    id: 5,
    title: '798艺术区的午后时光',
    date: '2026-05-05',
    location: '北京朝阳',
    mood: '灵感迸发',
    cover: diaryImages['5_cover'],
    images: [diaryImages['5_0'], diaryImages['5_1'], diaryImages['5_2']],
    tags: ['艺术', '文创', '咖啡'],
    excerpt: '在废旧工厂改造的艺术空间里，每一面墙都是表达，每一个转角都有惊喜。',
    content: '<h2>工业与艺术的碰撞</h2><p>798的魅力在于新旧交融。红砖烟囱下是先锋画廊，老厂房里是装置艺术。这种反差感让人每次来都有新发现。</p><h2>小众画廊推荐</h2><p>推荐三个不太拥挤但质量很高的空间：UCCA当代艺术中心的常设展、林冠艺术基金会的摄影展，以及藏在二层的独立书店。</p><p>午后的咖啡馆找一个靠窗的位置，看着窗外来往的人群和涂鸦墙，时间好像慢了下来。</p>',
    author: { nickname: '文艺青年', avatar: '' },
    stats: { views: 180, likes: 16, comments: 2 },
    ratingScore: 4.3,
    ratingCount: 6,
    bookmarkCount: 11
  },
  {
    id: 6,
    title: '长城日出挑战记',
    date: '2026-04-30',
    location: '北京怀柔',
    mood: '震撼',
    cover: diaryImages['6_cover'],
    images: [diaryImages['6_0'], diaryImages['6_1']],
    tags: ['长城', '徒步', '日出'],
    excerpt: '凌晨四点出发，只为在长城上看第一缕阳光。当金色光芒洒满烽火台，一切辛苦都值了。',
    content: '<h2>摸黑出发</h2><p>凌晨三点半闹钟响起，四点准时从住处出发。选择了慕田峪长城，人少景美。到达时天边刚刚泛白。</p><h2>登城观日</h2><p>头灯照亮台阶，一步步向上攀登。到达敌楼时，东方已经有了橙红色的光晕。当太阳从山脊线跃出的那一刻，整个世界都被点亮了。</p><p>长城蜿蜒在晨光中，像一条金色的巨龙。这大概是我在北京最难忘的瞬间。</p>',
    author: { nickname: '追光者', avatar: '' },
    stats: { views: 680, likes: 72, comments: 12 },
    ratingScore: 4.9,
    ratingCount: 25,
    bookmarkCount: 45
  },
  {
    id: 7,
    title: '南锣鼓巷的慢时光',
    date: '2026-05-06',
    location: '北京东城',
    mood: '悠闲',
    cover: diaryImages['7_cover'],
    images: [diaryImages['7_0'], diaryImages['7_1']],
    tags: ['胡同', '美食', '文创'],
    excerpt: '穿梭在灰墙之间，转角遇见一家文艺小店，点一杯手冲慢慢品味老北京的烟火气。',
    content: '<p>南锣鼓巷虽然商业化了不少，但拐进两旁的小胡同依然能找到安静的角落。帽儿胡同的梧桐树下坐着下棋的老人，菊儿胡同里藏着好喝的精品咖啡。</p>',
    author: { nickname: '胡同漫游者', avatar: '' },
    stats: { views: 220, likes: 19, comments: 5 },
    ratingScore: 3.9,
    ratingCount: 10,
    bookmarkCount: 8
  },
  {
    id: 8,
    title: '天坛祈年殿的光影魔法',
    date: '2026-04-20',
    location: '北京天坛',
    mood: '敬畏',
    cover: diaryImages['8_cover'],
    images: [diaryImages['8_0'], diaryImages['8_1']],
    tags: ['古建筑', '摄影', '世界遗产'],
    excerpt: '日落时分的祈年殿，金色琉璃瓦在夕阳下散发着神圣的光芒，仿佛穿越了六百年。',
    content: '<p>天坛公园的傍晚特别推荐。游客散去后，你可以安静地欣赏这座建筑奇迹。回音壁、圜丘、祈年殿，每一处都承载着古人对天地的敬畏。</p>',
    author: { nickname: '光影猎手', avatar: '' },
    stats: { views: 340, likes: 42, comments: 7 },
    ratingScore: 4.7,
    ratingCount: 14,
    bookmarkCount: 20
  },
  {
    id: 9,
    title: '三里屯到工体的夜行记',
    date: '2026-05-03',
    location: '北京朝阳',
    mood: '微醺',
    cover: diaryImages['9_cover'],
    images: [diaryImages['9_0'], diaryImages['9_1']],
    tags: ['夜生活', '美食', '城市'],
    excerpt: '霓虹灯下的三里屯从来不缺故事，从精酿啤酒到深夜拉面，这是属于夜晚的北京。',
    content: '<p>晚上八点从三里屯太古里出发，先去那家藏在地下的精酿酒吧点了两杯IPA。十点多转场到工体附近的居酒屋，烤串配清酒，微醺刚刚好。最后在路边的深夜食堂吃了一碗热气腾腾的牛肉面收尾。</p>',
    author: { nickname: '夜行动物', avatar: '' },
    stats: { views: 150, likes: 12, comments: 3 },
    ratingScore: 4.0,
    ratingCount: 5,
    bookmarkCount: 6
  },
  {
    id: 10,
    title: '奥森公园晨跑日志',
    date: '2026-05-07',
    location: '北京奥林匹克公园',
    mood: '活力满满',
    cover: diaryImages['10_cover'],
    images: [diaryImages['10_0']],
    tags: ['跑步', '公园', '健康'],
    excerpt: '5公里环湖跑道，清晨六点的奥森满是晨跑的人。湖面薄雾缭绕，鸟鸣声此起彼伏。',
    content: '<p>奥森南园的环湖步道是北京最舒服的跑步路线之一。全程平坦，树荫覆盖率高，夏天也不会太晒。跑完在湖边做拉伸，看着白鹭从水面掠过，身心都得到了治愈。</p>',
    author: { nickname: '晨跑打卡', avatar: '' },
    stats: { views: 95, likes: 8, comments: 1 },
    ratingScore: 4.1,
    ratingCount: 4,
    bookmarkCount: 3
  },
  {
    id: 11,
    title: '雍和宫的檀香与钟声',
    date: '2026-04-15',
    location: '北京雍和宫',
    mood: '宁静',
    cover: diaryImages['11_cover'],
    images: [diaryImages['11_0'], diaryImages['11_1']],
    tags: ['寺庙', '文化', '静心'],
    excerpt: '在城市的喧嚣中找到一片净土，檀香袅袅，钟声悠扬，心一下子就静了下来。',
    content: '<p>雍和宫是北京城里最大的藏传佛教寺院。工作日的上午人不多，可以慢慢走完每一个殿堂。万福阁里那尊26米高的白檀木弥勒大佛让人叹为观止。出来后去对面的五道营胡同转转，安静又文艺。</p>',
    author: { nickname: '寻禅旅人', avatar: '' },
    stats: { views: 260, likes: 28, comments: 4 },
    ratingScore: 4.4,
    ratingCount: 9,
    bookmarkCount: 14
  },
  {
    id: 12,
    title: '圆明园遗址的春天',
    date: '2026-04-22',
    location: '北京海淀',
    mood: '感慨',
    cover: diaryImages['12_cover'],
    images: [diaryImages['12_0'], diaryImages['12_1']],
    tags: ['历史', '遗址', '春天'],
    excerpt: '残垣断壁间开满了野花，历史的沉重与春天的生机形成了最动人的对比。',
    content: '<p>圆明园的春天格外美。西洋楼遗址的石柱间，不知名的野花肆意生长。福海水面开阔，远处的荷花还没开，但荷叶已经铺满了水面。租一条小船在福海上划一圈，想象着这里曾经的盛景，感慨万千。</p>',
    author: { nickname: '历史爱好者', avatar: '' },
    stats: { views: 310, likes: 35, comments: 6 },
    ratingScore: 4.5,
    ratingCount: 11,
    bookmarkCount: 17
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
  { label: '精选景点', value: '8', detail: '含地理坐标与标签' },
  { label: '路线连接', value: '32', detail: '支持城市路线规划' },
  { label: '游记样例', value: '3', detail: '可编辑可扩展' },
  { label: '成就徽章', value: '4', detail: '记录旅行成长' }
]
