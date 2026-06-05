const AMAP_LOADER_URL = 'https://webapi.amap.com/loader.js'
const AMAP_VERSION = '2.0'
const AMAP_PLUGINS = ['AMap.Scale', 'AMap.ToolBar']
const DEFAULT_AMAP_JS_KEY = 'b28f4cae3c38fd619a41f994a20e4c9e'

let loaderScriptPromise
let amapPromise

function readAmapConfig() {
  return {
    key: import.meta.env.VITE_AMAP_JS_KEY || DEFAULT_AMAP_JS_KEY,
    securityJsCode: import.meta.env.VITE_AMAP_SECURITY_JS_CODE || ''
  }
}

function appendLoaderScript() {
  if (window.AMapLoader) return Promise.resolve()
  if (loaderScriptPromise) return loaderScriptPromise

  loaderScriptPromise = new Promise((resolve, reject) => {
    const existingScript = document.querySelector(`script[src="${AMAP_LOADER_URL}"]`)
    if (existingScript) {
      existingScript.addEventListener('load', resolve, { once: true })
      existingScript.addEventListener('error', () => reject(new Error('高德地图加载器加载失败')), { once: true })
      return
    }

    const script = document.createElement('script')
    script.src = AMAP_LOADER_URL
    script.async = true
    script.onload = resolve
    script.onerror = () => reject(new Error('高德地图加载器加载失败'))
    document.head.appendChild(script)
  })

  return loaderScriptPromise
}

export function getAmapConfigStatus() {
  const { key, securityJsCode } = readAmapConfig()
  return {
    ready: Boolean(key),
    hasKey: Boolean(key),
    hasSecurityJsCode: Boolean(securityJsCode)
  }
}

export async function loadAmap() {
  const { key, securityJsCode } = readAmapConfig()
  if (!key) {
    throw new Error('请配置 VITE_AMAP_JS_KEY 后使用高德地图')
  }

  if (securityJsCode) {
    window._AMapSecurityConfig = {
      securityJsCode
    }
  }

  if (!amapPromise) {
    amapPromise = appendLoaderScript().then(() => {
      if (!window.AMapLoader) throw new Error('高德地图加载器不可用')
      return window.AMapLoader.load({
        key,
        version: AMAP_VERSION,
        plugins: AMAP_PLUGINS
      })
    })
  }

  return amapPromise
}
