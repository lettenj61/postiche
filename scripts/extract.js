/**
 * @typedef { import('./docs').Module } Module
 */

const fs = require('fs')
const path = require('path')
const os = require('os')

const support = {
  elmVersion: '0.19.1'
}

let Elm

try {
  Elm = require('./lib/reader.js').Elm
} catch (err) {
  console.error('this script requires an Elm module to be compiled separatedly.')
  console.error('please refer to README and follow build instructions')
  process.exit(1)
}

const dest = process.argv[3] || 'target'
const app = Elm.Reader.init({ flags: process.argv[2] || '' })
;

app.ports.elmReady.subscribe(descriptor => {
  try {
    const pkgPath = getVersionedPackage(descriptor)
    const docsJson = path.join(pkgPath, 'docs.json')
    const docEntries = JSON.parse(fs.readFileSync(docsJson, 'utf-8'))
  
    app.ports.resolvedPackage.send(docEntries)
  } catch (err) {
    app.ports.allDone.send(null)
  }
})

app.ports.newContentMap.subscribe(contentMap => {
  const target = path.resolve(dest)
  if (!fs.existsSync(target)) {
    fs.mkdirSync(target)
  }
  contentMap.forEach(([file, content]) => {
    const savePath = path.join(target, file)
    fs.writeFileSync(savePath, content)
    console.log(`saved: ${savePath}`)
  })
})

app.ports.terminate.subscribe(({ code, errors }) => {
  if (errors) {
    console.error(errors)
  }
  process.exit(code)
})


/**
 * @param { {version: string, author: string, project: string} } package 
 * @returns {string | null}
 */
function getVersionedPackage({ version, author, project }) {
  const base = findElmCacheDirectory()
  if (base == null) return null
  ;

  const pkgRoot = path.join(base, author, project)
  if (!fs.existsSync(pkgRoot)) {
    console.warn(`required package not found in local cache: ${pkgRoot}`)
    return null
  }

  const withVersion = path.join(pkgRoot, version)
  if (!fs.existsSync(withVersion)) {
    console.warn(`package found but version mismatch: ${pkgRoot} - ${version}`)
    return null
  }

  return withVersion
}

/**
 * @returns {string | undefined}
 */
function findElmCacheDirectory() {
  // this may be incorrent in non windows OS
  const localApp = os.platform() === 'win32' ? 'AppData' : 'HOME'
  return process.env[localApp] && path.join(process.env[localApp], 'elm', support.elmVersion, 'packages')
}