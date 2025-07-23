const http = require('http')
const https = require('https')
const url = require('url')
const querystring = require('querystring')

module.exports = function(req, res) {
  const parsed = url.parse(req.url)
  const query = querystring.parse(parsed.query)
  const targetUrl = query.url

  if (!targetUrl || !/^https?:\/\/[^ "]+$/.test(targetUrl)) {
    res.statusCode = 403
    return res.end('❌ Forbidden: Invalid or missing target URL')
  }

  const target = new URL(targetUrl)
  const protocol = target.protocol === 'https:' ? https : http

  const options = {
    method: req.method,
    hostname: target.hostname,
    port: target.port || (target.protocol === 'https:' ? 443 : 80),
    path: target.pathname + target.search,
    headers: req.headers
  }

  const proxy = protocol.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers)
    proxyRes.pipe(res)
  })

  proxy.on('error', (err) => {
    console.error('Proxy error:', err.message)
    res.statusCode = 500
    res.end('❌ Proxy request failed: ' + err.message)
  })

  if (req.method === 'POST' || req.method === 'PUT') {
    req.pipe(proxy)
  } else {
    proxy.end()
  }
}
