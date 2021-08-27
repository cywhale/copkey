import Spkey from '../models/spkey_mongoose';

const resolvers = {
      Query: {
		keys: async (_, obj) => {
                  const { sp } = obj;
                  let spx = sp.replace(/\s/g, "\\\s")
		  const keys = await Spkey.find({$text: {$search: spx}});
		  return keys;
		},
                getsp: async (_, obj) => {
                  const { sp } = obj;
                  let spx = sp.replace(/\s/g, "\\\s")
                  const keyx = await Spkey.find({"taxon":{$regex: spx, $options: "ix"}})
                  return keyx
                },
		key: async (_, obj, ctx) => {
		  const { sp } = obj; //if sp is String
                  let spx = decodeURIComponent(sp).replace(/\s/g, "\\\s")
                  ctx.reply.log.info("GraphQL to find: " + spx)
		  const keyx = await Spkey.find({$or:[
                    {"taxon": {$regex: spx, $options: "ix"} },
                    {"fullname": {$regex: spx, $options: "ix"} },
                    {"genus": {$regex: spx, $options: "ix"} },
                    {"family": {$regex: spx, $options: "ix"} }
                  ]}) //, {limit: 100}) //.sort({"rid":1})
		  return keyx;
                }
      }
}

export default resolvers;
