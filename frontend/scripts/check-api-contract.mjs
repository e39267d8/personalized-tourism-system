import { readFileSync, readdirSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const scriptDir = dirname(fileURLToPath(import.meta.url))
const frontendDir = resolve(scriptDir, '..')
const repoDir = resolve(frontendDir, '..')
const apiClientPath = join(frontendDir, 'src', 'services', 'tourismApi.js')
const backendApiDir = join(repoDir, 'backend', 'src', 'api')

const apiSource = readFileSync(apiClientPath, 'utf8')

const normalizeFrontendPath = (path) => {
  const withoutTemplateExpressions = path.replace(/\$\{[^}]+\}/g, ':param')
  return `/api/v1${withoutTemplateExpressions}`.replace(/\/+/g, '/')
}

const normalizeBackendPath = (path) => (
  path
    .replace(/<[^>]+>/g, ':param')
    .replace(/\/+/g, '/')
)

const frontendRoutes = new Set()
const clientCallPattern = /client\.(?:get|post|put|delete)\(\s*(?:`([^`]+)`|'([^']+)'|"([^"]+)")/g

for (const match of apiSource.matchAll(clientCallPattern)) {
  const path = match[1] ?? match[2] ?? match[3]
  if (!path || !path.startsWith('/')) continue
  frontendRoutes.add(normalizeFrontendPath(path))
}

const backendRoutes = new Set()
const backendRoutePattern = /CROW_ROUTE\([^,]+,\s*"([^"]+)"/g

for (const fileName of readdirSync(backendApiDir)) {
  if (!fileName.endsWith('_routes.cpp')) continue
  const source = readFileSync(join(backendApiDir, fileName), 'utf8')
  for (const match of source.matchAll(backendRoutePattern)) {
    backendRoutes.add(normalizeBackendPath(match[1]))
  }
}

const ignoredRoutes = new Set([
  // 前端代理会把 /api/v1 前缀交给后端；这里不检查静态资源或非 API 路径。
])

const missingRoutes = [...frontendRoutes]
  .filter(route => !ignoredRoutes.has(route))
  .filter(route => !backendRoutes.has(route))
  .sort()

if (missingRoutes.length > 0) {
  console.error('以下前端 API 路径没有匹配的后端 CROW_ROUTE：')
  for (const route of missingRoutes) {
    console.error(`- ${route}`)
  }
  process.exit(1)
}

console.log(`API contract check passed: ${frontendRoutes.size} frontend routes matched.`)
