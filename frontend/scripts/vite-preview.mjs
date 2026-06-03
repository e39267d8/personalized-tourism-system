import { preview } from 'vite'
import { createViteConfig, readCliOptions } from './vite-runtime-config.mjs'

const options = readCliOptions()
const server = await preview(createViteConfig(options))

server.printUrls()
