import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

export function readCliOptions(argv = process.argv.slice(2)) {
  const options = {
    host: '127.0.0.1',
    port: undefined
  }

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index]
    if (arg === '--host' && argv[index + 1]) {
      options.host = argv[index + 1]
      index += 1
    } else if (arg.startsWith('--host=')) {
      options.host = arg.slice('--host='.length)
    } else if (arg === '--port' && argv[index + 1]) {
      options.port = Number(argv[index + 1])
      index += 1
    } else if (arg.startsWith('--port=')) {
      options.port = Number(arg.slice('--port='.length))
    }
  }

  return options
}

export function createViteConfig({ host, port } = {}) {
  return {
    configFile: false,
    plugins: [vue()],
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('../src', import.meta.url))
      }
    },
    server: {
      host,
      port: port || 3000,
      proxy: {
        '/api': {
          target: 'http://127.0.0.1:8080',
          changeOrigin: true
        }
      }
    },
    preview: {
      host,
      port: port || 4173
    },
    build: {
      outDir: 'dist',
      assetsDir: 'static',
      sourcemap: true
    }
  }
}
