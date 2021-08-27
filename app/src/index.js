import Fastify from 'fastify';
import Env from 'fastify-env'
import S from 'fluent-json-schema'
import { join } from 'desm'
//import mercurius from 'mercurius';
//import db from './config/index';
//import schema from './graphql/schema';
//import resolvers from './graphql/resolvers';
import srvapp from './srvapp.js'

const PORT = process.env.PORT || 3000;
const fastify = Fastify({ logger: true });

fastify.register(Env, {
    //confKey: 'config',
    dotenv: {
      path: join(import.meta.url, 'config/.env'),
    //debug: true
    },
    schema: S.object()
      //.prop('NODE_ENV', S.string().required())
      .prop('COOKIE_SECRET', S.string().required())
      .prop('MONGO_CONNECT', S.string().required())
      .valueOf()
}).ready((err) => {
    if (err) console.error(err)
  //console.log("fastify config: ", fastify.config)
})



//fastify.register(db, { uri }); //use mongoose
fastify.register(srvapp) //old: use fastify-mongodb, but not work used in graphql resolvers
//  .after(err => {
//    if (err) throw err
//  })
/*
fastify.register(mercurius, {
	schema,
	resolvers,
	graphiql: 'playground'
});
*/
// create server
const start = async () => {
	try {
	    await fastify.listen(PORT);
	} catch (err) {
	    fastify.log.error(err);
	    process.exit(1);
	}
};
start();
