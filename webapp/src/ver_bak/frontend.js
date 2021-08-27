import preactToString from 'preact-render-to-string';
import {h} from 'preact';
import App from './App.jsx';
import homepage from './homepage.js';

export default async function (fastify, opts) {
  const { db } = fastify.mongo.mongo1;
  const spkey = db.collection('spkey');
//can refer: https://github.com/Cristiandi/demo-fastify/blob/master/src/routes/api/persons/schemas.js
//see: https://developer.ibm.com/tutorials/learn-nodejs-mongodb/
  const ctxtSchema = {
              ctxt: { type: 'string' }
            };
    fastify.get('/:name', {
      schema: {
        response: {
          200: {
              type: 'array',
              items: {
                type: 'object',
                properties: ctxtSchema
            }
          }
        }
      }
    },
    (req, reply) => {
      spkey.find({$or:[
        {taxon: {$regex: req.params.name, $options: "ix"} },
        {genus: {$regex: req.params.name, $options: "ix"} },
        {family: {$regex: req.params.name, $options: "ix"} },
        {fullname: {$regex: req.params.name, $options: "ix"} }
        ]}//,
        //onFind
      ).toArray(async (err, key) => {
        if (err) {
          req.log.info("Error when searching in Mongo: ", err);
          await reply.send({});
        } else {
          if (key.length>0) {
            const res = key.reduce((acc, obj) => { return (acc.ctxt + obj.ctxt) })
            await reply.send({})
          }
      }

          await reply.send(key);
        }
      })
    })
  next()
}



  fastify.get('/', fopts, async (req, res) => {
      console.log("server rootdir")
      res.header('content-type', 'text/html; charset=UTF-8')
      const html = homepage(preactToString(h(App)))
      res.send(html)
  });

