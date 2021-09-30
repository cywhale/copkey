//import S from 'fluent-json-schema'
export const autoPrefix = process.env.NODE_ENV === 'production'? '/species' : '/specieskey'
//import Spkey from '../models/spkey_mongoose'; //change to use graphql by mercurius
//import fp from 'fastify-plugin'

export default async function spquery (fastify, opts, next) {
  //const { db } = fastify.mongo.mongo1;
  //const spkey = db.collection('spkey');
  //fastify.decorate('spkey', spkey);
    const pageSchema = {
              sp: { type: 'string' },
              first: { type: 'number' },
              last: { type: 'number' },
              after: { type: 'string' },
              last: { type: 'string' },
              //keystr: { type: 'string' },
              //ctxt: { type: 'string' }
            }; // if not use graphql
    fastify.route({ //.get('/page', (req, reply) => {
      method: ['GET', 'POST'],
      url: '/page',
      schema: pageSchema,
      handler: (req, reply) => {
    /*const get_parx = (qstr) => {
          let withq = qstr.indexOf('?');
          if (withq>=0) {
            return qstr.substring(qstr.indexOf('?')).replace('?', '').split('&').reduce((r,e) => (r[e.split('=')[0]] = decodeURIComponent(e.split('=')[1]).replace(/\s/g, "\\\s"), r), {});
          }
          return decodeURIComponent(qstr).replace(/\s/g, "\\\s")
      }
    */
        let parm
        let kobj={}
        //req.log.info("Query method: " + req.method)
        if (req.method==='POST') {
          parm = req.body
        } else {
          parm = req.query
        }
      //let parm = get_parx(req.query)
      //if (parm != null && parm.constructor.name === "Object") {
        //if (typeof parm.taxon !== 'undefined') {
        kobj["taxon"] = parm.taxon??'' //}
        if (typeof parm.first !== 'undefined') { kobj["first"] = parseInt(parm.first) }
        if (typeof parm.last !== 'undefined')  { kobj["last"] = parseInt(parm.last) }
        if (typeof parm.after !== 'undefined') { kobj["after"] = parm.after }
        if (typeof parm.before !== 'undefined'){ kobj["before"] = parm.before }
      //}
        if (kobj !== {}) {
          const pqry = `query ($taxon: String!, $first: Int, $last: Int, $after: String, $before: String) {
                     infq(taxon: $taxon, first: $first, last: $last, after: $after, before: $before)
              {
                totalCount
                pageInfo {
                  num
                  hasNextPage
                  hasPreviousPage
                }
                edges {
                  node {
                    ctxt
                  }
                  cursor
                }
              }
          }`
          return reply.graphql(pqry, null, kobj)
        } else {
          return {}
        }
      }
    })

    fastify.get('/', {
      schema: {
        query: {
          //$id: 'common_schema',
          properties: {
            page: {
              type: 'number'
            }/*,
            fig_only: {
              type: 'boolean'
            },
            taxon: {
              type: 'string'
            }*/
          }
        }
      }
    },(req, reply) => {
      const qstr = req.query
      let pqry; //, fqry, tqry
      //if (typeof qstr.fig_only !== 'undefined' && qstr.fig_only==true) {}
      if (typeof qstr.page !== 'undefined') {
        let pg = parseInt(qstr.page);
        req.log.info("Query use graphql with page: " + pg)
        if (!isNaN(pg)) {
          pqry = `query ($pg: Int!) { page(p: $pg) {ctxt} }`
          return reply.graphql(pqry, null, {"pg": pg})
        } else {
          return {}
        }
      } else {
        return {}
      }
    })

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
          await reply.send([...key]); // use mongoose
        }
      })*/
      let name = req.params.name
      if (name==="init") {
        return reply.graphql('{ init {ctxt} }')
      }
      const query = `query ($name: String!) { key(sp: $name) {ctxt} }` //{unikey ctxt}
      //req.log.info("Query use graphql: "+ query + " with sp: " + name)
      return reply.graphql(query, null, {"name": name})
    })

  next()
}
/*
export default fp(spquery, {
  name: 'spquery'
})
*/


