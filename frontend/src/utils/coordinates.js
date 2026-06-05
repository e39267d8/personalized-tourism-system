const PI = Math.PI
const AXIS = 6378245.0
const OFFSET = 0.006693421622965943

function outOfChina(latitude, longitude) {
  return longitude < 72.004 || longitude > 137.8347 || latitude < 0.8293 || latitude > 55.8271
}

function transformLatitude(x, y) {
  let result = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * Math.sqrt(Math.abs(x))
  result += (20.0 * Math.sin(6.0 * x * PI) + 20.0 * Math.sin(2.0 * x * PI)) * 2.0 / 3.0
  result += (20.0 * Math.sin(y * PI) + 40.0 * Math.sin(y / 3.0 * PI)) * 2.0 / 3.0
  result += (160.0 * Math.sin(y / 12.0 * PI) + 320 * Math.sin(y * PI / 30.0)) * 2.0 / 3.0
  return result
}

function transformLongitude(x, y) {
  let result = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * Math.sqrt(Math.abs(x))
  result += (20.0 * Math.sin(6.0 * x * PI) + 20.0 * Math.sin(2.0 * x * PI)) * 2.0 / 3.0
  result += (20.0 * Math.sin(x * PI) + 40.0 * Math.sin(x / 3.0 * PI)) * 2.0 / 3.0
  result += (150.0 * Math.sin(x / 12.0 * PI) + 300.0 * Math.sin(x / 30.0 * PI)) * 2.0 / 3.0
  return result
}

export function wgs84ToGcj02(latitude, longitude) {
  const lat = Number(latitude)
  const lng = Number(longitude)
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return { latitude: lat, longitude: lng }
  if (outOfChina(lat, lng)) return { latitude: lat, longitude: lng }

  let dLat = transformLatitude(lng - 105.0, lat - 35.0)
  let dLng = transformLongitude(lng - 105.0, lat - 35.0)
  const radLat = lat / 180.0 * PI
  let magic = Math.sin(radLat)
  magic = 1 - OFFSET * magic * magic
  const sqrtMagic = Math.sqrt(magic)
  dLat = (dLat * 180.0) / ((AXIS * (1 - OFFSET)) / (magic * sqrtMagic) * PI)
  dLng = (dLng * 180.0) / (AXIS / sqrtMagic * Math.cos(radLat) * PI)

  return {
    latitude: lat + dLat,
    longitude: lng + dLng
  }
}

export function gcj02ToWgs84(latitude, longitude) {
  const lat = Number(latitude)
  const lng = Number(longitude)
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return { latitude: lat, longitude: lng }
  if (outOfChina(lat, lng)) return { latitude: lat, longitude: lng }

  const gcj = wgs84ToGcj02(lat, lng)
  return {
    latitude: lat * 2 - gcj.latitude,
    longitude: lng * 2 - gcj.longitude
  }
}

export function toAmapLngLat(point) {
  const converted = wgs84ToGcj02(point?.latitude, point?.longitude)
  if (!Number.isFinite(converted.latitude) || !Number.isFinite(converted.longitude)) return null
  return [converted.longitude, converted.latitude]
}

export function toBackendLatLng(lngLat) {
  const longitude = typeof lngLat?.getLng === 'function' ? lngLat.getLng() : lngLat?.longitude ?? lngLat?.lng
  const latitude = typeof lngLat?.getLat === 'function' ? lngLat.getLat() : lngLat?.latitude ?? lngLat?.lat
  return gcj02ToWgs84(latitude, longitude)
}
