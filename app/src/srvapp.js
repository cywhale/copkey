//import Mongodb from 'fastify-mongodb'
import AutoLoad from '@fastify/autoload'
import Cors from '@fastify/cors'
import Favicon from 'fastify-favicon'
import { join } from 'desm'
//import redis from 'fastify-redis'
import mercurius from 'mercurius'
//import cache from 'mercurius-cache'
import db from './config/db.js'
import schema from './graphql/schema.js'
import resolvers from './graphql/resolvers.js'

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
        jit: 1,
        queryDepth: 11
  })

fastify.register(Favicon, { path: join(import.meta.url, '..', 'client'), name: 'favicon.ico' })

/* move to plugins/redis.js
  fastify.register(redis, {
    host: '127.0.0.1',
    port: 6379,
  }, { name: 'redis' })
*/
/* move to plugins/cache.js
  const ttl = 60 * 60

  fastify.register(cache, {
    policy: {
      Query: {
        taxontree: true,
        infq: true
      }
    },
    ttl: ttl,
    storage: {
      type: 'redis', options: { client: fastify.redis, invalidation: true }
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
      } //before mercurius-cache version 0.11
    },
    onHit: function (type, fieldName) {
      fastify.log.info({ msg: 'hit from cache', type, fieldName })
    },
    onMiss: function (type, fieldName) {
      fastify.log.info({ msg: 'miss from cache', type, fieldName })
    }
  })
*/
  fastify.register(Cors, (instance) => {
    return (req, callback) => {
      const corsOptions = {
        origin: true,
        credentials: true,
        preflight: true,
        preflightContinue: true,
        methods: ['GET', 'POST', 'OPTIONS'],
        allowedHeaders: ['Origin', 'X-Requested-With', 'Content-Type', 'Accept', 'Keep-Alive', 'User-Agent',
                         'Cache-Control', 'Authorization', 'DNT', 'X-PINGOTHER', 'Range'],
        exposedHeaders: ['Content-Range'],
        maxAge: 86400,
      };
      // do not include CORS headers for requests from localhost
      if (/^localhost$/m.test(req.headers.origin)) {
        corsOptions.origin = false
      }
      callback(null, corsOptions)
    }
  })

  fastify.register(AutoLoad, {
    dir: join(import.meta.url, 'plugins'),
    options: Object.assign({}, opts)
  })

  fastify.register(AutoLoad, {
      dir: join(import.meta.url, 'routes'),
      dirNameRoutePrefix: false,
      options: Object.assign({}, opts)
  })
}
