import Spkey from '../models/spkey_mongoose';

const resolvers = {
    Query: {
      keys: async (_, obj) => {
        const { sp } = obj
        let spx = sp.replace(/\s/g, "\\\s")
	const keys = await Spkey.find({$text: {$search: spx}})
        return keys
      },
      init: async (_, obj) => {
        let key = "genus_Acartia"
        let spx = decodeURIComponent("Acartia bifilosa").replace(/\s/g, "\\\s")
        //let fig = "fig_Acartia_bifilosa" //{"unikey": fig}
        const out = await Spkey.find({$or:[{"unikey": key}, {"taxon": {$regex: spx, $options: "ix"}}]})
        return out
      },
      page: async (_, obj, ctx) => {
        const { p } = obj
        //ctx.reply.log.info("GraphQL to find page: " + p)
        const keyx = await Spkey.find({"page":p}, null, {sort: {kcnt: 1}}) //asc, desc, ascending, descending, 1, or -1
        return keyx
      },
      key: async (_, obj, ctx) => {
        const { sp } = obj
        let spx = decodeURIComponent(sp).replace(/\s/g, "\\\s")
        const keyx = await Spkey.find({$or:[
                {"taxon": {$regex: spx, $options: "ix"} },
                {"fullname": {$regex: spx, $options: "ix"} },
                {"genus": {$regex: spx, $options: "ix"} },
                {"family": {$regex: spx, $options: "ix"} }
              ]}) //, {limit: 100}) //.sort({"rid":1})
        return keyx
      },
// ---------------------------------------------
/* modified from https://jiepeng.me/2019/12/06/learning-how-to-implement-graphql-pagination */
// ---------------------------------------------
      infq: async (_, obj, ctx) => {
        const { sp, first, last, after, before } = obj

        let spqry, keyx, cursor, curidx, page, totalCount, hasNextPage, hasPreviousPage;
        //first with after, last with before. if only first(no after)/ last(no before) get 1st/last page
        //const emptyx = {}
        if (!first && !last) {
            ctx.reply.log.info("Pagination should have one argument: first or last");
            //data = await emptyx;
            return; //result;
        }
        if (first && last) {
            ctx.reply.log.info("Pagination cannot have both arguments: first & last")
            return;
        }
        if (after && before) {
            ctx.reply.log.info("Pagination cannot have both arguments: after & before")
            return;
        }

        let spx = decodeURIComponent(sp).replace(/\s/g, "\\\s")
        if (spx==='') {
            spqry = {}
        } else {
            spqry = {$or:[
                {"taxon": {$regex: spx, $options: "ix"} },
                {"fullname": {$regex: spx, $options: "ix"} },
                {"genus": {$regex: spx, $options: "ix"} },
                {"family": {$regex: spx, $options: "ix"} }
            ]}
        }

        if (first) {
        /*if (first && after) {
            const data = await Spkey.find({...spqry, {unikey:{$gt: after}}}, null,
                                          {sort: {unikey: 1}}); //, limit: first+1, sort: {kcnt: 1}});
        */
          const data = await Spkey.find(spqry, {unikey:1, kcnt:1, ctxt:1}, {sort: {unikey: 1}}); //, limit: first+1, sort: {kcnt: 1}});
          totalCount = data.length;
          let filter = after? data.filter(d => d.unikey > after) :  data;
          hasPreviousPage = after? true: false;
          hasNextPage = filter.length > first;
          keyx = hasNextPage? filter.slice(0, first+1) : filter
          cursor= keyx[keyx.length-1]["unikey"];
          if (!after) {
            page = 1
          } else {
            curidx= data.findIndex(item => item.unikey === cursor);
            page = Math.floor((curidx+1)/first) + (((curidx+1) % first === 0) ? 0 : 1)
          }
          keyx.sort((x, y) => { return x.kcnt - y.kcnt });
        } else if (last) {
          const data = await Spkey.find(spqry, {unikey:1, kcnt:1, ctxt:1}, {sort: {unikey: -1}}); //, limit: last+1, sort: {kcnt: 1}});
          totalCount = data.length;
          let filter = before? data.filter(d => d.unikey < before) :  data;
          hasNextPage = before? true: false;
          hasPreviousPage = filter.length > last;
          keyx = hasNextPage? filter.slice(0, last+1) : filter
          cursor= keyx[keyx.length-1]["unikey"];
          if (!before) {
            page = Math.floor(totalCount/last) + ((toralCount % last === 0) ? 0 : 1)
          } else {
            curidx= data.findIndex(item => item.unikey === cursor); //it's reverse in order
            page = Math.floor(totalCount/last) + ((toralCount % last === 0) ? 0 : 1) -
                   Math.floor((curidx+1)/last) + (((curidx+1) % last === 0) ? 0 : 1) + 1
          }
          keyx.sort((x, y) => { return x.kcnt - y.kcnt });
        }
        ctx.reply.log.info("GraphQL to find length of keyx: " + keyx.length)
        ctx.reply.log.info("GraphQL to find last ctxt keyx: " + keyx[keyx.length-1]["ctxt"])

        return {
          totalCount: totalCount,
          pageInfo: {
            num: page,
            hasNextPage: hasNextPage,
            hasPreviousPage: hasPreviousPage
          },
          edges: {
            node: keyx,
            cursor: cursor
          }
        }
      }
    }
};
export default resolvers;
