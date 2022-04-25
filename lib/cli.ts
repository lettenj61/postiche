import * as fs from 'fs'
import * as path from 'path'
import * as os from 'os'
import yargs from 'yargs/yargs'
import { hideBin } from 'yargs/helpers'

interface Bundle {
  fqn: string
  slug: string
  markdown: string
}

type Send<T> = {
  send(value: T): void
}

type Subscribe<T> = {
  subscribe(f: (x: T) => void): void
}

type Flags = {
  specifier: string
}

type Elm = {
  Worker: {
    init(options: { flags: Flags }): {
      ports: {
        docsFinder: Subscribe<string>
        docsWriter: Subscribe<Bundle[]>
        abort: Subscribe<{ code: number; message: string }>

        moduleLoader: Send<unknown>
      }
    }
  }
}

type Args = {
  specifier?: string
}

// Copied from https://github.com/dmy/elm-doc-preview/blob/3fd888fc1c8fd4a8c2ce5ffd2eb1676eab60b770/lib/elm-doc-server.ts#L196
function getElmCache(elmVersion: string) {
  const dir = os.platform() === 'win32' ? 'AppData/Roaming/elm' : '.elm'
  const home = process.env.ELM_HOME || path.join(os.homedir(), dir)
  const packages = elmVersion === '0.19.0' ? 'package' : 'packages'
  const cache = path.join(home, elmVersion, packages)
  return cache
}

const Elm: Elm = require('./worker').Elm
const VERSION = '0.19.1'

;
(async () => {
  const argv: Args = yargs(hideBin(process.argv)).argv as unknown as Args
  const worker = Elm.Worker.init({
    flags: {
      specifier: argv.specifier ?? ''
    }
  })

  worker.ports.abort.subscribe(({ code, message }) => {
    console.error(message)
    process.exit(code)
  })

  worker.ports.docsWriter.subscribe(bundle => {
    const tmpdir = fs.mkdtempSync('output/elm-postiche-')
    bundle.forEach(mod => {
      fs.writeFileSync(
        path.join(tmpdir, `${mod.slug}.md`),
        mod.markdown
      )
    })

    console.log(tmpdir)
  })

  worker.ports.docsFinder.subscribe(spec => {
    worker.ports.moduleLoader.send(
      require('./docs.json')
    )
  })
})()