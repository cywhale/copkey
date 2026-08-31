import assert from 'node:assert/strict'
import { after, before, test } from 'node:test'
import Fastify from 'fastify'
import querygql from '../src/routes/querygql.js'

const app = Fastify()

app.decorateReply('graphql', function (_query, _context, variables) {
  return variables
})

app.register(querygql, { prefix: '/species' })

before(async () => {
  await app.ready()
})

after(async () => {
  await app.close()
})

test('POST /species/page accepts the existing payload', async () => {
  const response = await app.inject({
    method: 'POST',
    url: '/species/page',
    payload: {
      taxon: '',
      keystr: false,
      mode: 'genus',
      first: 30
    }
  })

  assert.equal(response.statusCode, 200)
  assert.deepEqual(response.json(), {
    taxon: '',
    keystr: false,
    mode: 'genus',
    first: 30
  })
})

test('POST /species/page rejects mass-assignment fields', async () => {
  const response = await app.inject({
    method: 'POST',
    url: '/species/page',
    payload: {
      taxon: '',
      keystr: false,
      mode: 'genus',
      first: 30,
      is_admin: true,
      is_sso: true,
      role: 'admin'
    }
  })

  assert.equal(response.statusCode, 400)
  assert.match(response.json().message, /Unsupported properties: is_admin, is_sso, role/)
})

test('GET /species/page accepts and coerces the existing query parameters', async () => {
  const response = await app.inject({
    method: 'GET',
    url: '/species/page?taxon=Calanus&keystr=false&mode=genus&first=30'
  })

  assert.equal(response.statusCode, 200)
  assert.deepEqual(response.json(), {
    taxon: 'Calanus',
    keystr: false,
    mode: 'genus',
    first: 30
  })
})

test('GET /species/page rejects unknown query parameters', async () => {
  const response = await app.inject({
    method: 'GET',
    url: '/species/page?taxon=Calanus&role=admin'
  })

  assert.equal(response.statusCode, 400)
  assert.match(response.json().message, /Unsupported properties: role/)
})

test('POST /species/page rejects invalid parameter types', async () => {
  const response = await app.inject({
    method: 'POST',
    url: '/species/page',
    payload: {
      taxon: '',
      first: 'not-a-number'
    }
  })

  assert.equal(response.statusCode, 400)
  assert.match(response.json().message, /first must be integer/)
})
