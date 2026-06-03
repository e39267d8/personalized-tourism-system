const BASE = '/images/diary/'

export const localSpotImageGroups = {
  '798': ['798_0.jpg', '798_1.jpeg', '798_2.jpeg', '798_3.jpeg', '798_4.jpeg', '798_5.jpeg', '798_6.jpeg', '798_7.jpeg'],
  aosen: ['aosen_0.jpeg', 'aosen_1.jpg', 'aosen_2.jpg', 'aosen_3.jpeg', 'aosen_4.jpg', 'aosen_5.jpeg', 'aosen_6.jpeg', 'aosen_7.jpeg'],
  beihaigongyuan: ['beihaigongyuan_0.jpeg', 'beihaigongyuan_1.jpeg', 'beihaigongyuan_2.jpeg', 'beihaigongyuan_3.jpg', 'beihaigongyuan_4.jpeg'],
  changcheng: ['changcheng_0.jpg', 'changcheng_1.jpg', 'changcheng_2.jpg', 'changcheng_3.jpg'],
  gongti: ['gongti_0.png', 'gongti_1.jpg', 'gongti_2.jpg', 'gongti_3.jpg', 'gongti_4.jpg'],
  gugong: ['gugong_0.jpg', 'gugong_1.jpg', 'gugong_2.jpg', 'gugong_3.jpg', 'gugong_4.jpg'],
  gulou: ['gulou_0.jpeg', 'gulou_1.jpeg', 'gulou_2.jpeg', 'gulou_3.jpeg', 'gulou_4.jpeg', 'gulou_5.jpeg', 'gulou_6.jpeg'],
  guojiabowuguan: ['guojiabowuguan_0.jpeg', 'guojiabowuguan_1.jpeg', 'guojiabowuguan_2.jpeg', 'guojiabowuguan_3.jpeg', 'guojiabowuguan_4.jpeg', 'guojiabowuguan_5.jpeg', 'guojiabowuguan_6.png', 'guojiabowuguan_7.jpeg'],
  jingshangongyuan: ['jingshangongyuan_0.jpg'],
  nanluoguxiang: ['nanluoguxiang_0.jpg', 'nanluoguxiang_1.jpg', 'nanluoguxiang_2.jpg', 'nanluoguxiang_3.jpg', 'nanluoguxiang_4.jpg', 'nanluoguxiang_5.jpg', 'nanluoguxiang_6.png'],
  qianmen: ['qianmen_0.jpg', 'qianmen_1.jpg'],
  sanlitun: ['sanlitun_0.jpeg', 'sanlitun_1.jpeg', 'sanlitun_2.jpeg', 'sanlitun_3.jpeg', 'sanlitun_4.jpeg', 'sanlitun_5.jpeg', 'sanlitun_6.jpg'],
  shichahai: ['shichahai_0.jpg', 'shichahai_1.jpeg', 'shichahai_2.jpg', 'shichahai_3.jpg', 'shichahai_4.jpg', 'shichahai_5.jpg', 'shichahai_6.jpg', 'shichahai_7.jpg', 'shichahai_8.jpg'],
  tiantan: ['tiantan_0.jpg', 'tiantan_1.jpg', 'tiantan_2.jpg', 'tiantan_3.jpg'],
  wangfujing: ['wangfujing_0.jpg', 'wangfujing_1.jpg', 'wangfujing_2.jpg', 'wangfujing_3.jpg', 'wangfujing_4.jpg', 'wangfujing_5.jpg'],
  yiheyuan: ['yiheyuan_0.jpg', 'yiheyuan_1.jpg', 'yiheyuan_2.jpg'],
  yonghegong: ['yonghegong_0.jpeg', 'yonghegong_1.jpeg', 'yonghegong_2.jpeg', 'yonghegong_3.jpeg', 'yonghegong_4.jpeg', 'yonghegong_5.jpg', 'yonghegong_6.jpg'],
  yuanmingyuan: ['yuanmingyuan_0.jpg', 'yuanmingyuan_1.jpg', 'yuanmingyuan_2.jpg', 'yuanmingyuan_3.jpg']
}

export const localSpotAliases = [
  ['guojiabowuguan', ['guojiabowuguan', '国家博物馆', '中国国家博物馆', '国博', '博物馆']],
  ['jingshangongyuan', ['jingshangongyuan', 'jingshan', '景山公园', '景山']],
  ['beihaigongyuan', ['beihaigongyuan', 'beihai', '北海公园', '北海']],
  ['nanluoguxiang', ['nanluoguxiang', 'nanluo', '南锣鼓巷']],
  ['yuanmingyuan', ['yuanmingyuan', '圆明园遗址公园', '圆明园']],
  ['yonghegong', ['yonghegong', '雍和宫']],
  ['wangfujing', ['wangfujing', '王府井步行街', '王府井']],
  ['shichahai', ['shichahai', '什刹海', '后海', 'houhai']],
  ['changcheng', ['changcheng', '长城', '八达岭', '慕田峪']],
  ['qianmen', ['qianmen', '前门大街', '前门', '正阳门']],
  ['tiantan', ['tiantan', '天坛公园', '天坛', '祈年殿']],
  ['gugong', ['gugong', '故宫博物院', '故宫', '紫禁城', '中轴线']],
  ['yiheyuan', ['yiheyuan', '颐和园']],
  ['sanlitun', ['sanlitun', '三里屯']],
  ['gongti', ['gongti', '工体', '工人体育场']],
  ['gulou', ['gulou', '鼓楼', '钟楼']],
  ['aosen', ['aosen', '奥森', '奥林匹克森林公园', '奥林匹克公园', '北京奥林匹克公园']],
  ['798', ['798', '798艺术区', '七九八']]
]

export const localSpotImageUrlForKey = (key, index = 0) => {
  const files = localSpotImageGroups[key]
  return files?.[index] ? BASE + files[index] : ''
}

const allLocalSpotImageFiles = Object.values(localSpotImageGroups).flat()

export const localSpotImageUrlForSeed = (seed = '') => {
  if (!allLocalSpotImageFiles.length) return ''
  const text = String(seed || 'tourpilot')
  let hash = 0
  for (let i = 0; i < text.length; i += 1) {
    hash = ((hash << 5) - hash + text.charCodeAt(i)) | 0
  }
  const index = Math.abs(hash) % allLocalSpotImageFiles.length
  return BASE + allLocalSpotImageFiles[index]
}

export const diaryImages = {
  '1_cover': BASE + 'gugong_0.jpg',
  '1_0': BASE + 'qianmen_0.jpg',
  '1_1': BASE + 'gugong_1.jpg',
  '1_2': BASE + 'jingshangongyuan_0.jpg',
  '2_cover': BASE + 'guojiabowuguan_0.jpeg',
  '2_0': BASE + 'guojiabowuguan_1.jpeg',
  '2_1': BASE + 'wangfujing_0.jpg',
  '2_2': BASE + 'wangfujing_1.jpg',
  '3_cover': BASE + 'shichahai_0.jpg',
  '3_0': BASE + 'gulou_0.jpeg',
  '3_1': BASE + 'shichahai_1.jpeg',
  '3_2': BASE + 'beihaigongyuan_0.jpeg',
  '3_3': BASE + 'beihaigongyuan_1.jpeg',
  '4_cover': BASE + 'yiheyuan_0.jpg',
  '4_0': BASE + 'yiheyuan_1.jpg',
  '4_1': BASE + 'yiheyuan_2.jpg',
  '5_cover': BASE + '798_0.jpg',
  '5_0': BASE + '798_1.jpeg',
  '5_1': BASE + '798_2.jpeg',
  '5_2': BASE + '798_3.jpeg',
  '6_cover': BASE + 'changcheng_0.jpg',
  '6_0': BASE + 'changcheng_1.jpg',
  '6_1': BASE + 'changcheng_2.jpg',
  '7_cover': BASE + 'nanluoguxiang_0.jpg',
  '7_0': BASE + 'nanluoguxiang_1.jpg',
  '7_1': BASE + 'nanluoguxiang_2.jpg',
  '8_cover': BASE + 'tiantan_0.jpg',
  '8_0': BASE + 'tiantan_1.jpg',
  '8_1': BASE + 'tiantan_2.jpg',
  '9_cover': BASE + 'sanlitun_0.jpeg',
  '9_0': BASE + 'sanlitun_1.jpeg',
  '9_1': BASE + 'gongti_0.png',
  '10_cover': BASE + 'aosen_0.jpeg',
  '10_0': BASE + 'aosen_1.jpg',
  '11_cover': BASE + 'yonghegong_0.jpeg',
  '11_0': BASE + 'yonghegong_1.jpeg',
  '11_1': BASE + 'yonghegong_2.jpeg',
  '12_cover': BASE + 'yuanmingyuan_0.jpg',
  '12_0': BASE + 'yuanmingyuan_1.jpg',
  '12_1': BASE + 'yuanmingyuan_2.jpg'
}
