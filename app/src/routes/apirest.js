import S from 'fluent-json-schema'
import Spkey from '../models/spkey_mongoose.js'

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
          tags: ['Copkey'],
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
                description: 'Use scientific name (family/genus/species);\nBut for /key, available only by querying species'
        }
      },
      required: ['name']
    }

    //https://mongoplayground.net/p/mMjvMyEajhT
    fastify.get('/taxon/:name',
      {
        schema: {
          description: 'Key to the Calanoid Copepods(Copkey) taxon data',
          tags: ['Copkey'],
          params: scinameSchemaObj,
          response: {
            200: S.array().items(taxonomySchema)
          },
        }
      },
      async (req, reply) => {
        //const { name } = req.params
        let name = decodeURIComponent(req.params.name)
        let spx = name.replace(/ \([\s\S]*?\)/g, '') //"Acartia (Acartiura) longiremis" -> "Acartia longiremis"
        const keyx = await Spkey
                           .aggregate([
                             { $match: {taxon: {"$ne": ""},
                               $or: [
                                {taxon: { "$eq": spx }},
                                {genus: { "$eq": spx }},
                                {family:{ "$eq": spx }}
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
    //slightly diff with ktreeqry in querygl.js (get keystr)
    const kstrxqry =`query($sp: String!) {
      keys(sp: $sp)
      {
        _id
        unikey
        taxon
        sex
        keystr
        parent {
          unikey
          keystr
          parent {
            unikey
            keystr
            parent {
              unikey
              keystr
              parent {
                unikey
                keystr
                parent {
                  unikey
                  keystr
                  parent {
                    unikey
                    keystr
                    parent {
                      unikey
                      keystr
                      parent {
                        unikey
                        keystr
                        parent {
                          unikey
                          keystr
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }`
    fastify.get('/taxon/:name/key',
      {
        schema: {
          description: 'Classification key to the Calanoid Copepods',
          tags: ['Copkey'],
          params: scinameSchemaObj,
          //response: {
          //  200: S.array().items(taxonomySchema)
          //},
        }
      },
      (req, reply) => {
        let name = decodeURIComponent(req.params.name)
        let spx = name.replace(/\([\s\S]*?\)/g, '')
        return reply.graphql(kstrxqry, null, {sp: spx})
    })

    next()
}

