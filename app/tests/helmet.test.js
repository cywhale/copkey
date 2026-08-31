import assert from 'node:assert/strict'
import { after, before, test } from 'node:test'
import Helmet from '@fastify/helmet'
import Fastify from 'fastify'
import { helmetOptions } from '../src/routes/frontend.js'

const app = Fastify()

app.register(Helmet, helmetOptions)
app.get('/polyfills.js', async (_req, reply) => {
  reply.type('application/javascript').send('void 0')
})

before(async () => {
  await app.ready()
})

after(async () => {
  await app.close()
})

test('frontend resources require cross-origin resource isolation', async () => {
  const response = await app.inject({ method: 'GET', url: '/polyfills.js' })

  assert.equal(response.statusCode, 200)
  assert.equal(response.headers['cross-origin-embedder-policy'], 'require-corp')
  assert.equal(response.headers['cross-origin-opener-policy'], 'same-origin')
  assert.equal(response.headers['cross-origin-resource-policy'], 'same-origin')
})
