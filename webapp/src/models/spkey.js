//import fp from 'fastify-plugin'
var spkey;

function spkeydb (fastify, opts, done) {
  const { db } = fastify.mongo.mongo1
  if (!spkey) spkey = db.collection('spkey')
  //const { spkey } = fastify
  //fastify.decorate('spkey', spkey)
  fastify.log.info("Test found: ",spkey.findOne({taxon:"Acartia hongi"}))
  done()
  return spkey
}

export default spkeydb;
//export default fp(spkeydb, {
//  name: 'spkeydb'
//})
