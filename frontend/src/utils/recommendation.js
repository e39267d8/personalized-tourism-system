export const PROFILE_STORAGE_KEY = 'tourism_user_profile'

export const budgetLabels = {
  low: '低预算',
  medium: '中等预算',
  high: '高预算'
}

export const crowdLabels = {
  avoid_crowded: '避开拥挤',
  popular: '偏好热门',
  any: '都可以'
}

export const intensityLabels = {
  light: '轻松',
  medium: '适中',
  high: '充实'
}

const categoryAliases = {
  历史古迹: ['历史古迹', '历史', '古建', '世界遗产', '中轴线', '故宫'],
  博物馆: ['博物馆', '展览', '室内'],
  自然公园: ['自然公园', '城市公园', '公园', '自然', '日落', '轻徒步'],
  城市地标: ['城市地标', '地标', '中轴线', '步行'],
  商业街区: ['商业街区', '购物', '夜游', '美食'],
  美食街区: ['美食街区', '美食', '夜游', '商业街区'],
  摄影打卡: ['摄影打卡', '摄影', '观景摄影', '日落', '俯瞰'],
  亲子休闲: ['亲子休闲', '亲子', '室内', '公园', '低预算'],
  城市漫步: ['城市漫步', 'citywalk', '胡同', '步行', '轻徒步']
}

export const defaultProfile = () => ({
  preferredCategories: [],
  preferredTags: [],
  budgetLevel: 'medium',
  crowdPreference: 'any',
  intensity: 'medium'
})

export const normalizeProfile = (value = {}) => ({
  ...defaultProfile(),
  ...value,
  preferredCategories: Array.isArray(value.preferredCategories) ? value.preferredCategories : [],
  preferredTags: Array.isArray(value.preferredTags) ? value.preferredTags : []
})

export const hasMeaningfulProfile = (value) => Boolean(
  value?.preferredTags?.length ||
  value?.preferredCategories?.length ||
  (value?.budgetLevel && value.budgetLevel !== 'medium') ||
  (value?.crowdPreference && value.crowdPreference !== 'any') ||
  (value?.intensity && value.intensity !== 'medium')
)

export const readStoredProfile = () => {
  const raw = localStorage.getItem(PROFILE_STORAGE_KEY)
  if (!raw) return null
  try {
    return normalizeProfile(JSON.parse(raw))
  } catch (error) {
    localStorage.removeItem(PROFILE_STORAGE_KEY)
    return null
  }
}

export const writeStoredProfile = (profile) => {
  localStorage.setItem(PROFILE_STORAGE_KEY, JSON.stringify(normalizeProfile(profile)))
}

export const clearStoredProfile = () => {
  localStorage.removeItem(PROFILE_STORAGE_KEY)
}

export const budgetMaxTicket = (profile) => ({
  low: 60,
  medium: 120,
  high: 300
})[profile?.budgetLevel] || 120

const durationHours = (value) => {
  const match = String(value || '').match(/[\d.]+/)
  return match ? Number(match[0]) : 2
}

export const spotTags = (spot) =>
  Array.isArray(spot.tags) ? spot.tags : String(spot.tags || '').split(/[,\s，、]+/).filter(Boolean)

const spotText = (spot) => [
  spot.name,
  spot.category,
  spot.district,
  spot.description,
  ...spotTags(spot)
].filter(Boolean).join(' ')

const unique = (items) => [...new Set(items.filter(Boolean))]

const matchedCategories = (spot, selectedCategories) => {
  const text = spotText(spot)
  return selectedCategories.filter(category =>
    (categoryAliases[category] || [category]).some(alias => text.includes(alias))
  )
}

const matchedTags = (spot, selectedTags) => {
  const text = spotText(spot)
  return selectedTags.filter(tag => text.includes(tag))
}

export const preferenceScore = (spot, profile) => {
  const prefs = normalizeProfile(profile)
  const categories = matchedCategories(spot, prefs.preferredCategories)
  const tags = matchedTags(spot, prefs.preferredTags)
  const ticket = Number(spot.ticket || 0)
  const hours = durationHours(spot.duration)
  const crowd = String(spot.crowd || '')
  let score = Number(spot.rating || 0) * 10

  score += categories.length * 18
  score += tags.length * 14
  score += ticket <= budgetMaxTicket(prefs) ? 12 : -Math.min(18, Math.ceil((ticket - budgetMaxTicket(prefs)) / 10))

  if (prefs.crowdPreference === 'avoid_crowded') {
    if (crowd.includes('低')) score += 12
    else if (crowd.includes('中')) score += 4
    else if (crowd.includes('高')) score -= 10
  }
  if (prefs.crowdPreference === 'popular') {
    if (crowd.includes('高')) score += 10
    else if (crowd.includes('中')) score += 6
    if (Number(spot.rating || 0) >= 4.6) score += 6
  }
  if (prefs.intensity === 'light') {
    if (hours <= 2) score += 10
    else if (hours <= 3) score += 3
    else score -= 8
  }
  if (prefs.intensity === 'high') {
    if (hours >= 3) score += 10
    else if (hours >= 2.5) score += 6
  }
  if (prefs.intensity === 'medium' && hours >= 1.5 && hours <= 3) score += 5

  return {
    score: Math.max(1, Math.min(99, Math.round(score))),
    categories,
    tags
  }
}

export const recommendationReason = (spot, profile, matches) => {
  const prefs = normalizeProfile(profile)
  const parts = []
  if (matches.categories.length) parts.push(`匹配你的「${matches.categories.join('、')}」类型偏好`)
  if (matches.tags.length) parts.push(`命中「${matches.tags.join('、')}」标签`)
  if (Number(spot.ticket || 0) <= budgetMaxTicket(prefs)) {
    parts.push(`门票符合${budgetLabels[prefs.budgetLevel] || '当前预算'}`)
  }
  if (prefs.crowdPreference === 'avoid_crowded') parts.push('更适合避开拥挤的人流选择')
  if (prefs.crowdPreference === 'popular') parts.push('兼顾热门程度和评分表现')
  if (prefs.intensity === 'light') parts.push('游玩节奏轻松')
  if (prefs.intensity === 'high') parts.push('适合更充实的行程')
  return `${(parts.length ? parts.slice(0, 3) : ['综合评分、成本和游玩节奏更均衡']).join('，')}。`
}

export const normalizeRecommendation = (item, profile) => {
  const scenicSpot = item.scenic_spot || item.scenicSpot || item
  const prefs = normalizeProfile(profile)
  const localMatch = preferenceScore(scenicSpot, prefs)
  const backendScore = Number(item.score ?? scenicSpot.score ?? 0)
  const score = backendScore
    ? Math.round(localMatch.score * 0.85 + Math.min(100, backendScore) * 0.15)
    : localMatch.score

  return {
    scenicSpot,
    score,
    matchedTags: unique([...localMatch.categories, ...localMatch.tags, ...spotTags(scenicSpot)]).slice(0, 3),
    reason: recommendationReason(scenicSpot, prefs, localMatch)
  }
}
