import Spkey from '../models/spkey_mongoose';

const resolvers = {
      Query: {
		keys: async (_, obj) => {
                  const { sp } = obj;
                  let spx = sp.replace(/\s/g, "\\\s")
		  const keys = await Spkey.find({$text: {$search: spx}});
		  return keys;
		},
                init: async (_, obj) => {
                  let key = "genus_Acartia"
                  let spx = decodeURIComponent("Acartia bifilosa").replace(/\s/g, "\\\s")
                  //let fig = "fig_Acartia_bifilosa" //{"unikey": fig}
                  const out = await Spkey.find({$or:[{"unikey": key}, {"taxon": {$regex: spx, $options: "ix"}}]});
                  return out;
                },
                page: async (_, obj, ctx) => {
                  const { p } = obj;
                  //ctx.reply.log.info("GraphQL to find page: " + p)
                  const keyx = await Spkey.find({"page":p}, null, {sort: {kcnt: 1}}) //asc, desc, ascending, descending, 1, or -1
                  return keyx
                },
		key: async (_, obj, ctx) => {
		  const { sp } = obj;
                  let spx = decodeURIComponent(sp).replace(/\s/g, "\\\s")
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
