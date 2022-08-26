import S from 'fluent-json-schema'
import Spkey from '../models/spkey_mongoose'

//export const autoPrefix = process.env.NODE_ENV === 'production'? '/species' : '/specieskey'

export default async function apirest (fastify, opts, next) {

  const taxonomySchema = S.object()
    .id('#taxonomySchema')
    .description('taxon data ok')
    .prop('family', S.string())
    .prop('taxon', S.array().items(
      S.object()
        .prop('genus', S.string())
        .prop('species', S.array().items(S.string()))))

    fastify.get('/taxon',
      {
        schema: {
          description: 'Key to the Calanoid Copepods(Copkey) taxon collections',
          tags: ['copkey'],
          response: {
            200: S.array().items(taxonomySchema)
          },
        }
      },
      async (req, reply) => {
        const keyx = await Spkey
                           .aggregate([
                             { $match: {taxon: {"$ne": ""}, unikey: {"$regex": /^(?!00a_genus).*/i}} },
                             { $group: {
                                   _id: {
                                     family: "$family",
                                     genus: "$genus"
                                   },
                                   children: { $addToSet: {
                                     taxon: "$taxon"
                                   } },
                             } },
                             { $unwind: "$children"}, //Need to re-sort taxon
                             { $sort: {"children.taxon":1} },
                             { $group: {
                                   _id: {
                                     family: "$_id.family",
                                     genus: "$_id.genus"
                                   },
                                   children: { $push: {
                                     taxon: "$children.taxon"
                                   } }
                             } },
                             { $sort: {"_id.genus":1} },
                             { $group: {
                                   _id:"$_id.family",
                                   taxon: { $push: {
                                       genus: "$_id.genus",
                                       species: "$children.taxon"
                                   } }
                             } },
                             { $project: {family:"$_id", _id:0, taxon:1} },
                             { $sort: {family:1} }
                           ]).exec()
        await reply.send(keyx)
    })

    const scinameSchemaObj = {
      type: 'object',
      properties: {
        name: { type: 'string',
                description: 'Use scientific name (family/genus/species)'
        }
      },
      required: ['name']
    }

    //https://mongoplayground.net/p/mMjvMyEajhT
    fastify.get('/taxon/:name',
      {
        schema: {
          description: 'Key to the Calanoid Copepods(Copkey) taxon data',
          tags: ['copkey'],
          params: scinameSchemaObj,
          response: {
            200: S.array().items(taxonomySchema)
          },
        }
      },
      async (req, reply) => {
        const { name } = req.params
        const keyx = await Spkey
                           .aggregate([
                             { $match: {taxon: {"$ne": ""},
                               $or: [
                                {taxon: { "$eq": name }},
                                {genus: { "$eq": name }},
                                {family:{ "$eq": name }}
                               ],
                               unikey: {"$regex": /^(?!00a_genus).*/i}} },
                             { $group: {
                                   _id: {
                                     family: "$family",
                                     genus: "$genus"
                                   },
                                   children: { $addToSet: {
                                     taxon: "$taxon"
                                   } },
                             } },
                             { $unwind: "$children"}, //Need to re-sort taxon
                             { $sort: {"children.taxon":1} },
                             { $group: {
                                   _id: {
                                     family: "$_id.family",
                                     genus: "$_id.genus"
                                   },
                                   children: { $push: {
                                     taxon: "$children.taxon"
                                   } }
                             } },
                             { $sort: {"_id.genus":1} },
                             { $group: {
                                   _id:"$_id.family",
                                   taxon: { $push: {
                                       genus: "$_id.genus",
                                       species: "$children.taxon"
                                   } }
                             } },
                             { $project: {family:"$_id", _id:0, taxon:1} },
                             { $sort: {family:1} }
                           ]).exec()
        await reply.send(keyx)
    })

    next()
}

