import assert from 'node:assert/strict'
import { after, before, test } from 'node:test'
import Cors from '@fastify/cors'
import Fastify from 'fastify'
import { createCorsOptions } from '../src/config/cors.js'

const app = Fastify()

app.register(Cors, () => (req, callback) => {
  callback(null, createCorsOptions(req, 'production'))
})
app.get('/test', async () => ({ ok: true }))

before(async () => {
  await app.ready()
})

after(async () => {
  await app.close()
})

for (const origin of [
  'https://bio.odb.ntu.edu.tw',
  'https://api.odb.ntu.edu.tw',
  'https://eco.odb.ntu.edu.tw'
]) {
  test(`production allows ${origin}`, async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/test',
      headers: { origin }
    })

    assert.equal(response.statusCode, 200)
    assert.equal(response.headers['access-control-allow-origin'], origin)
    assert.equal(response.headers['access-control-allow-credentials'], undefined)
  })
}

test('production does not return CORS headers to an unlisted origin', async () => {
  const response = await app.inject({
    method: 'GET',
    url: '/test',
    headers: { origin: 'https://bogus.hcl.com' }
  })

  assert.equal(response.statusCode, 200)
  assert.equal(response.headers['access-control-allow-origin'], undefined)
  assert.equal(response.headers['access-control-allow-credentials'], undefined)
})

test('requests without Origin continue to work without CORS headers', async () => {
  const response = await app.inject({ method: 'GET', url: '/test' })

  assert.equal(response.statusCode, 200)
  assert.equal(response.headers['access-control-allow-origin'], undefined)
})

test('development allows the isolated client origin', () => {
  const options = createCorsOptions({
    headers: { origin: 'https://192.168.2.29:3004' }
  }, 'development')

  assert.equal(options.origin, true)
})

test('production does not allow the isolated client origin', () => {
  const options = createCorsOptions({
    headers: { origin: 'https://192.168.2.29:3004' }
  }, 'production')

  assert.equal(options.origin, false)
})
