import fs from 'fs'
import zlib from 'zlib'

export async function save(filePath) {
  const directories = filePath.split('/')
  const fileName = directories[directories.length - 1]

  try {
    const data = fs.readFileSync(`${filePath}`)

    const payload = await zlib.deflateSync(data, {
      level: zlib.constants.Z_BEST_COMPRESSION,
      strategy: zlib.constants.Z_FILTERED
    })

    fs.writeFileSync(`${filePath}.gz`, payload)

    return true
  } catch (err) {
    console.log('on save error', filePath, err.message)
    return false
  }
}
