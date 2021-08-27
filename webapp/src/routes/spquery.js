//import S from 'fluent-json-schema'
//export const autoPrefix = process.env.NODE_ENV === 'production'? '/search/layers' : '/searchinfo/layers'
export const autoPrefix = '/spkey'
//import Spkey from '../models/spkey_mongoose'; //change to use graphql by mercurius
//import fp from 'fastify-plugin'

export default async function spquery (fastify, opts, next) {
  //const { db } = fastify.mongo.mongo1;
  //const spkey = db.collection('spkey');
  //fastify.decorate('spkey', spkey);
  /*const spkeySchema = {
              unikey: { type: 'string' },
              taxon: { type: 'string' },
              genus: { type: 'string' },
              family: { type: 'string' },
              fullname: { type: 'string' },
              keystr: { type: 'string' },
              ctxt: { type: 'string' }
            }; */ // if not use graphql
    fastify.get('/:name', /*{ //if not use graphql
      schema: {
        tags: ['spkey'],
        response: {
          200: {
              type: 'array',
              items: {
                type: 'object',
                properties: spkeySchema
            }
          }
        }
      }
    },*/
    (req, reply) => {
      //let sp = decodeURIComponent(req.params.name).replace(/\s/g, "\\\s") //if not use graphql
      //fastify.log.info("To find sp: " + sp)
      /*Spkey.find({$or:[
        {taxon: {$regex: sp, $options: "ix"} },
        {genus: {$regex: sp, $options: "ix"} },
        {family: {$regex: sp, $options: "ix"} },
        {fullname: {$regex: sp, $options: "ix"} }
        ]},
      //).toArray(async (err, key) => { //if use fastify-mongodb
      async (err, key) => {
        if (err) {
          req.log.info("Error when searching in Mongo: ", err);
          await reply.send({});
        } else {
          //await reply.send(key); // if use fastify-mongodb
          await reply.send([...key]);
        }
      })*/
      let name = req.params.name
      const query = `query ($name: String!) { key(sp: $name) {unikey ctxt} }`
      req.log.info("Query use graphql: "+ query + " with sp: " + name)
      return reply.graphql(query, null, {"name": name})
    })
  next()
}
/*
export default fp(spquery, {
  name: 'spquery'
})
*/


