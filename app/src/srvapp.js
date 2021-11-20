//import Mongodb from 'fastify-mongodb'
import AutoLoad from 'fastify-autoload'
import { join } from 'desm'
import redis from 'fastify-redis'
import mercurius from 'mercurius'
import cache from 'mercurius-cache'
import db from './config/db'
import schema from './graphql/schema'
import resolvers from './graphql/resolvers'

export default async function (fastify, opts) {
  fastify.decorate('conf', {
    node_env: process.env.NODE_ENV || 'development',
    port: process.env.PORT || 3000,
    devTestPort: 3003,
    //srvTestPort: 3001,
    sessiondir: process.env.NODE_ENV === 'production'? '/session' : '/sessioninfo'
  })

  fastify.register(db, { url: fastify.config.MONGO_CONNECT }) //use mongoose
//fastify.register(logger, {})
/*
  fastify.register(Mongodb, {
      forceClose: true,
      url: fastify.config.MONGO_CONNECT,
      name: 'mongo1'
  })
*/
  fastify.register(mercurius, {
        schema: schema,
        resolvers: resolvers,
        graphiql: true, //'playground', //has been removed from mercuius issue #453
        jit: 1
  })

  fastify.register(redis)

  const ttl = 60 * 60

  fastify.register(cache, {
    policy: {
      Query: {
        taxontree: true,
        infq: true
      }
    },
    storage: {
      get: async function (key) {
        try {
          return JSON.parse(await fastify.redis.get(key))
        } catch (err) {
          fastify.log.error({ msg: 'error on get from redis', err, key })
        }
        return null
      },
      set: async function (key, value) {
        try {
          await fastify.redis.set(key, JSON.stringify(value), 'EX', ttl)
        } catch (err) {
          fastify.log.error({ msg: 'error on set into redis', err, key })
        }
      }
    },
    onHit: function (type, fieldName) {
      fastify.log.info({ msg: 'hit from cache', type, fieldName })
    },
    onMiss: function (type, fieldName) {
      fastify.log.info({ msg: 'miss from cache', type, fieldName })
    }
  })

  fastify.register(AutoLoad, {
      dir: join(import.meta.url, 'routes'),
      dirNameRoutePrefix: false,
      options: Object.assign({}, opts)
  })
}
