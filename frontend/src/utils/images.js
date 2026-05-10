import { localSpotAliases, localSpotImageUrlForKey, localSpotImageUrlForSeed } from '@/data/localSpotImages'

const KNOWN_GENERIC_IMAGE_MARKERS = [
  'photo-1469854523086-cc02fe5d8800',
  'photo-1566127992631-137a642a90f4',
  'photo-1500530855697-b586d89ba3ee',
  'photo-1566054757965-8c4085344c96',
  'photo-1513415756790-2ac1db1297d0',
  'photo-1519608487953-e999c86e7455',
  'photo-1444723121867-7a241cacace9',
  'photo-1547981609-4b6bfe67ca0b',
  'photo-1508804185872-d7badad00f7d'
]

const FALLBACK_TYPES = [
  {
    label: '博物馆',
    keywords: ['博物馆', '展览', '纪念馆', '室内', 'museum'],
    colors: ['#1f2937', '#475569', '#e0f2fe']
  },
  {
    label: '公园自然',
    keywords: ['公园', '自然', '湖', '山', '园林', '湿地', 'park'],
    colors: ['#14532d', '#16a34a', '#dcfce7']
  },
  {
    label: '历史古迹',
    keywords: ['历史', '古迹', '寺', '庙', '遗产', '长城', '故宫'],
    colors: ['#7f1d1d', '#b91c1c', '#fee2e2']
  },
  {
    label: '街区美食',
    keywords: ['商业', '美食', '购物', '步行街', '夜游', '街区'],
    colors: ['#7c2d12', '#ea580c', '#ffedd5']
  },
  {
    label: '城市地标',
    keywords: ['地标', '广场', '塔', '城市'],
    colors: ['#164e63', '#0891b2', '#cffafe']
  }
]

const DEFAULT_TYPE = {
  label: '旅游目的地',
  colors: ['#0f172a', '#0f766e', '#ccfbf1']
}

const svgDataUri = ({ label, colors }) => {
  const [dark, mid, light] = colors
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="1200" height="720" viewBox="0 0 1200 720">
      <defs>
        <linearGradient id="bg" x1="0" x2="1" y1="0" y2="1">
          <stop offset="0%" stop-color="${dark}"/>
          <stop offset="58%" stop-color="${mid}"/>
          <stop offset="100%" stop-color="${light}"/>
        </linearGradient>
      </defs>
      <rect width="1200" height="720" fill="url(#bg)"/>
      <path d="M0 520 C180 450 280 565 450 498 C620 430 760 485 930 420 C1040 378 1120 390 1200 345 L1200 720 L0 720 Z" fill="rgba(255,255,255,0.22)"/>
      <path d="M0 595 C180 545 285 635 455 570 C640 500 750 585 940 520 C1058 480 1130 485 1200 445 L1200 720 L0 720 Z" fill="rgba(255,255,255,0.24)"/>
      <circle cx="945" cy="170" r="78" fill="rgba(255,255,255,0.22)"/>
      <text x="72" y="104" fill="rgba(255,255,255,0.92)" font-family="Arial, sans-serif" font-size="46" font-weight="700">${label}</text>
      <text x="72" y="164" fill="rgba(255,255,255,0.72)" font-family="Arial, sans-serif" font-size="25">TourPilot image placeholder</text>
    </svg>
  `
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`
}

const looksEmpty = (value) => {
  if (!value) return true
  const text = String(value).trim()
  if (!text || text === 'null' || text === 'undefined') return true
  if (text.includes('example.com') || text.includes('placeholder')) return true
  return KNOWN_GENERIC_IMAGE_MARKERS.some(marker => text.includes(marker))
}

const normalizeImageText = (value) => String(value || '').trim()

const imageCandidatesFrom = (value) => {
  if (!value) return []
  if (Array.isArray(value)) return value
  if (typeof value === 'string') return value.split('|')
  return []
}

const imageCandidatesFromSpot = (spot = {}) => [
  spot.imageUrl,
  spot.image_url,
  spot.photoUrl,
  spot.photo_url,
  spot.thumbnailUrl,
  spot.thumbnail_url,
  spot.image,
  spot.cover,
  ...imageCandidatesFrom(spot.images)
].map(normalizeImageText).filter(Boolean)

const isAmapImageUrl = (value) => {
  const text = normalizeImageText(value).toLowerCase()
  return text.includes('amap.com') || text.includes('autonavi.com')
}

export const isUsableImageUrl = (value) => {
  const text = normalizeImageText(value)
  if (looksEmpty(text)) return false
  if (/^data:image\/[a-z0-9.+-]+;base64,/i.test(text)) return true
  if (/^https?:\/\//i.test(text)) return true
  if (text.startsWith('/') && !text.startsWith('//')) return true
  return false
}

const fallbackTypeForSpot = (spot = {}) => {
  const profile = [
    spot.name,
    spot.category,
    spot.district,
    spot.description,
    ...(spot.tags || [])
  ].join(' ').toLowerCase()

  return FALLBACK_TYPES.find(item =>
    item.keywords.some(keyword => profile.includes(keyword.toLowerCase()))
  ) || DEFAULT_TYPE
}

export const fallbackImageForSpot = (spot = {}) => svgDataUri(fallbackTypeForSpot(spot))

export const normalizeDiaryImages = (diary = {}) => {
  const candidates = []
  if (diary.cover) candidates.push(diary.cover)
  if (Array.isArray(diary.images)) {
    candidates.push(...diary.images)
  } else if (typeof diary.images === 'string') {
    candidates.push(...diary.images.split('|'))
  }

  const seen = new Set()
  return candidates
    .map(normalizeImageText)
    .filter(isUsableImageUrl)
    .filter((url) => {
      if (seen.has(url)) return false
      seen.add(url)
      return true
    })
}

export const diaryFallbackImage = (diary = {}) => fallbackImageForSpot({
  name: diary.title,
  category: diary.location || diary.category,
  tags: diary.tags || []
})

export const diaryDisplayImages = (diary = {}) => {
  const images = normalizeDiaryImages(diary)
  if (images.length || diary.disableLocalImageFallback) return images
  const localImage = localSpotImageUrl({
    ...diary,
    name: diary.title || diary.name,
    category: diary.location || diary.category
  })
  if (localImage) return [localImage]
  const genericLocalImage = localSpotImageUrlForSeed(`${diary.id || ''}|${diary.title || ''}|${diary.location || ''}`)
  return genericLocalImage ? [genericLocalImage] : []
}

export const diaryCoverImage = (diary = {}) => diaryDisplayImages(diary)[0] || diaryFallbackImage(diary)

export const handleDiaryImageError = (event, diary = {}) => {
  if (event?.target) {
    const current = event.target.getAttribute('src') || ''
    const localImage = diary.disableLocalImageFallback
      ? ''
      : localSpotImageUrl({
        ...diary,
        name: diary.title || diary.name,
        category: diary.location || diary.category
      }) || localSpotImageUrlForSeed(`${diary.id || ''}|${diary.title || ''}|${diary.location || ''}`)
    if (localImage && current !== localImage) {
      event.target.src = localImage
    } else {
      event.target.onerror = null
      event.target.src = diaryFallbackImage(diary)
    }
  }
}

export const localSpotImageUrl = (spot = {}) => {
  const profile = [
    spot.name,
    spot.title,
    spot.location,
    spot.address,
    spot.category,
    spot.description,
    spot.pinyin,
    spot.slug,
    ...imageCandidatesFrom(spot.tags)
  ].join(' ').toLowerCase()

  const matched = localSpotAliases.find(([key, aliases]) =>
    profile.includes(key.toLowerCase()) ||
    aliases.some(alias => profile.includes(String(alias).toLowerCase()))
  )
  return matched ? localSpotImageUrlForKey(matched[0]) : ''
}

export const spotImageUrl = (spot = {}) => {
  const candidates = imageCandidatesFromSpot(spot)
  const amapImage = candidates.find(candidate => isAmapImageUrl(candidate) && isUsableImageUrl(candidate))
  if (amapImage) return amapImage
  return localSpotImageUrl(spot) || fallbackImageForSpot(spot)
}

export const handleSpotImageError = (event, spot = {}) => {
  if (event?.target) {
    const current = event.target.getAttribute('src') || ''
    const localImage = localSpotImageUrl(spot)
    const fallbackImage = fallbackImageForSpot(spot)
    if (localImage && current !== localImage) {
      event.target.src = localImage
    } else {
      event.target.onerror = null
      event.target.src = fallbackImage
    }
  }
}
