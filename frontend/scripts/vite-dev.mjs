import { createServer } from 'vite'
import { createViteConfig, readCliOptions } from './vite-runtime-config.mjs'

const options = readCliOptions()
const server = await createServer(createViteConfig(options))

await server.listen()
server.printUrls()
