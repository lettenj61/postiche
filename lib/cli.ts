import * as fs from 'fs'
import * as path from 'path'
import * as os from 'os'
import * as Eta from 'eta'
import yargs from 'yargs/yargs'
import { hideBin } from 'yargs/helpers'

interface Bundle {
  fqn: string
  slug: string
  markdown: string
}

interface BundleOutput {
  name: string
  bundle: Bundle[]
}

type Send<T> = {
  send(value: T): void
}

type Subscribe<T> = {
  subscribe(f: (x: T) => void): void
}

type Flags = {
  spec: string
}

type Elm = {
  Worker: {
    init(options: { flags: Flags }): {
      ports: {
        docsFinder: Subscribe<string>
        docsWriter: Subscribe<BundleOutput>
        abort: Subscribe<{ code: number; message: string }>

        moduleLoader: Send<unknown>
      }
    }
  }
}

type Args = {
  spec?: string
  output?: string
  docs: string
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

const parser = yargs(hideBin(process.argv))
  .option('output', {
    alias: 'o',
    type: 'string',
    description: 'where to generate HTML into'
  })
  .option('spec', {
    alias: 'p',
    type: 'string',
    description: 'package specification, <author>/<package>'
  })
  .option('docs', {
    type: 'string',
    description: 'path of JSON file contains document info'
  })

;
(async () => {
  Eta.configure({
    views: path.join(__dirname, 'template')
  })
  const args: Args = parser.parse() as unknown as Args
  const spec = args.spec ?? ''
  const worker = Elm.Worker.init({
    flags: {
      spec,
    }
  })

  worker.ports.abort.subscribe(({ code, message }) => {
    console.error('ERROR: %s', message)
    process.exit(code)
  })

  worker.ports.docsWriter.subscribe(async ({ bundle }) => {
    const outDir = args.output ?? 'output'
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir)
    }

    const pageTitle = args.spec ?? 'unnamed package'
    const indexContent = await Eta.renderFile('base.html', { title: pageTitle }) as string
    fs.writeFileSync(path.join(outDir, 'index.html'), indexContent)
    fs.writeFileSync(
      path.join(outDir, 'README.md'),
      await Eta.renderFile(
        'top.md',
        {
          title: pageTitle,
          bundle,
        }
      ) as string
    )

    bundle.forEach(mod => {
      fs.writeFileSync(
        path.join(outDir, `${mod.slug}.md`),
        mod.markdown
      )
    })

    console.log(`Success! contents are generated in ${outDir}`)
  })

  worker.ports.docsFinder.subscribe(spec => {
    const docsJson = fs.readFileSync(args.docs, { encoding: 'utf8' })
    worker.ports.moduleLoader.send(
      JSON.parse(docsJson)
    )
  })
})()