import home from './ui/home.js';

export default async function frontend (fastify, opts, next) {
  //const { db } = fastify.mongo.mongo1;
  //const spkey = db.collection('spkey');
  //fastify.decorate('spkey', spkey);

  fastify.get('/', (req, reply) => {
        reply.header('Content-Type', 'text/html');
        reply.send(home('Home', {
                   dateString: (new Date()).toString() + ' Server-side rendered!'
      }));
    }
  });
}

