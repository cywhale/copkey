import S from 'fluent-json-schema'
import { Spfig } from '../models/spkey_mongoose.js'

export default async function spfig (fastify, opts, next) {

  const scinameSchemaObj = {
      type: 'object',
      properties: {
        name: { type: 'string',
                description: 'Use scientific name of species'
        }
      },
      required: ['name']
  }

  const spfigSchema = S.object()
    .id('#spfigSchema')
    .description('fig metadata ok')
    .prop('taxon', S.string())
    .prop('fsex', S.string())
    .prop('fkey', S.string())
    .prop('ckey', S.string())
    .prop('caption', S.string())
    .prop('citation', S.string())

  fastify.get('/taxon/:name/fig',
    {
      schema: {
        description: 'Taxon figs for key to the Calanoid Copepods',
        tags: ['Copkey'],
        params: scinameSchemaObj,
        querystring: {
          type: "object",
          properties: {
            sex: { type: 'string',
                    description: 'query specific gender(female/male)'
            }
          }
        },
        response: {
          200: S.array().items(spfigSchema)
        }
      }
    },
    async (req, reply) => {
      let name = decodeURIComponent(req.params.name)
      let spx = name.replace(/\([\s\S]*?\)/g, '')
      let spqry = {"taxon": {$eq: spx} }
      if (typeof req.query.sex !== 'undefined' && req.query.sex !== '') {
         spqry = {...spqry, "fsex": {$eq: req.query.sex}}
      }
      const data = await Spfig.find(spqry)
      reply.send(data)
    }
  )

  next()
}

