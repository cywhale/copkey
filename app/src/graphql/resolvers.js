import Spkey from '../models/spkey_mongoose';

const resolvers = {
    Query: {
      taxontree: async (_, obj, ctx) => {
        const keyx = await Spkey
                           .aggregate([
                             { $match: {"taxon": {"$ne": ""}} },
                             { $group: {
                               /*_id: { //null
                                   family: "$family", //{$addToSet: "$family"}
                                   genus: "$genus",
                                   taxon: "$taxon"
                                 }*/
                                 _id: {
                                     family: "$family",
                                     genus: "$genus",
                                 },
                                 species: { $addToSet: {
                                       label: "$taxon",
                                       //value: { $replaceOne: { input: "$taxon", find: " ", replacement: "_" }}
                                   }   //add value after unwind and re-sort
                                 }
                             } },
                             { $unwind: "$species"}, //Need to re-sort taxon
                             { $sort: {"species.label":1} },
                             { $group: {
                                   _id: {
                                     family: "$_id.family",
                                     genus: "$_id.genus"
                                   },
                                   species: { $push: {
                                     label: "$species.label",
                                     value: { $replaceOne: { input: "$species.label", find: " ", replacement: "_" }}
                                   } }
                             } },
                             { $sort: {"_id.genus":1} },
                             { $group: {
                                 _id: "$_id.family",
                                 children: { $push: {
                                     label: "$_id.genus",
                                     value: "$_id.genus",
                                     children: "$species"
                                 } }
                             } },
                             { $addFields: {
                                   value: "$_id",
                                   label: "$_id"
                             } },
                             { $project: {label:"$_id", _id:0, value:1, children:1} },
                             { $sort: {label: 1}}
                           ]).exec()

        //ctx.reply.log.info("TaxonTree find data: " + keyx.children.length)
        return keyx
      },
/*      init: async (_, obj) => {
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
      },*/
      keys: async (_, obj, ctx) => {
        const { sp } = obj
        let spx = decodeURIComponent(sp).replace(/(\s|\_)/g, "\\\s")
      //const keyx = await Spkey.find({$text: {$search: spx}})
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
        const { taxon, first, last, after, before, key } = obj
        let spqry, data;
        let keyx = [];
        let cursor = '';
        let endCursor = '';
        let curidx = -1;
        let page = 0;
        let totalCount = 0;
        let hasNextPage = false;
        let hasPreviousPage = false;
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

        let spt = decodeURIComponent(taxon).replace(/\_/g, ' ')
        let spx = spt.replace(/\s/g, '\\\s')
        let chk_if_keystr = false
        spqry = {$or:[
                {"taxon": {$regex: spx, $options: "ix"} },
                {"fullname": {$regex: spx, $options: "ix"} },
                {"genus": {$regex: spx, $options: "ix"} },
                {"family": {$regex: spx, $options: "ix"} }
        ]}

        if (key) {
          chk_if_keystr = key.indexOf(spt.split(/(\s|\|)/)[0]) < 0; // if search not like 'Acartia_xxx' or 'fig_Acartia_xxx'
          if (chk_if_keystr) {
            let kstr = decodeURIComponent(key).replace(/\s/g, '|')
            let qry_kstr = {"keystr": {$regex: kstr, $options: "ix"}}
            ctx.reply.log.info("Perform keystr search: " + kstr)
            spqry = spx === ''? qry_kstr: {...spqry, qry_kstr}
          }
        } else if (spx === '') {
          spqry= {} //query all
        }

        //20211012 modified: if has a key index to find, then it must be firstly re-index, then can get correct page
        if (key) {
          let pgsize = first || last
          if (key.substring(0,3) === 'fig') {
            data = await Spkey.find(spqry, {unikey:1, kcnt:1, taxon:1, type:1, ctxt:1}, {sort: {unikey: 1}})
          } else {
            data = await Spkey.find(spqry, {unikey:1, kcnt:1, ctxt:1}, {sort: {unikey: 1}})
          }
          if (data && data.length) {
            if (chk_if_keystr) {
              curidx = 0
            } else if (key.substring(0,3) === 'fig') {
              let kt = key.split(/\_/)
              let spt= kt[1] + " " + kt[2]
              curidx = data.findIndex(item => item.taxon === spt && item.type === 2)
            } else {
              curidx = data.findIndex(item => item.unikey === key)
            }
            totalCount = data.length
            page = Math.floor((curidx+1)/pgsize) + (((curidx+1) % pgsize === 0) ? 0 : 1)
            hasNextPage = page < Math.floor(totalCount/pgsize) + ((totalCount % pgsize === 0) ? 0 : 1)? true: false
            hasPreviousPage = page > 1? true: false
            let pstart = page === 1? 0 : (page-1) * pgsize // index must -1
            keyx = hasNextPage? data.slice(pstart, pstart + pgsize): data.slice(pstart)
            endCursor= keyx[keyx.length-1]["unikey"] //Now endCursor always a page end, and cursor always a page start
            cursor = keyx[0]["unikey"] //so that when reverse in reading page can be right
            keyx.sort((x, y) => { return x.kcnt - y.kcnt })
          }
        } else if (first) {
        /*if (first && after) {
            const data = await Spkey.find({...spqry, {unikey:{$gt: after}}}, null,
                                          {sort: {unikey: 1}}); //, limit: first+1, sort: {kcnt: 1}});
        */
          data = await Spkey.find(spqry, {unikey:1, kcnt:1, ctxt:1}, {sort: {unikey: 1}}) //, limit: first+1, sort: {kcnt: 1}});
          if (data && data.length) {
            totalCount = data.length
            let filter = after? data.filter(d => d.unikey > after) :  data
            hasPreviousPage = after? true: false
            hasNextPage = filter.length > first
            keyx = hasNextPage? filter.slice(0, first) : filter
            endCursor= keyx[keyx.length-1]["unikey"] //Now endCursor always a page end, and cursor always a page start
            cursor = keyx[0]["unikey"] //so that when reverse in reading page can be right
            if (!after) {
                page = 1
            } else {
                curidx = data.findIndex(item => item.unikey === cursor);
                page = Math.floor((curidx+1)/first) + (((curidx+1) % first === 0) ? 0 : 1)
            }
            keyx.sort((x, y) => { return x.kcnt - y.kcnt })
          }
        } else if (last) {
          data = await Spkey.find(spqry, {unikey:1, kcnt:1, ctxt:1}, {sort: {unikey: -1}}) //, limit: last+1, sort: {kcnt: 1}});
          if (data && data.length) {
            totalCount = data.length
            let filter = before? data.filter(d => d.unikey < before) :  data
            hasNextPage = before? true: false
            hasPreviousPage = filter.length > last
            keyx = hasPreviousPage? filter.slice(0, last) : filter
            cursor= keyx[keyx.length-1]["unikey"]
            endCursor = keyx[0]["unikey"] //so that when reverse in reading page can be right
            // reverse order in keyx makes page index not consistent with in normal order
            // keyx.sort((x, y) => x.unikey > y.unikey ? 1 : -1);
            if (!before) {
              page = Math.floor(totalCount/last) + ((totalCount % last === 0) ? 0 : 1)
            } else {
              curidx = totalCount - data.findIndex(item => item.unikey === cursor) - 1; //it's reverse in order
            /*page = Math.floor(totalCount/last) + ((totalCount % last === 0) ? 0 : 1) -
                     Math.floor((curidx+1)/last) + (((curidx+1) % last === 0) ? 0 : 1)*/ //+ 1 //before is previous page, no need + 1
              page = Math.floor((curidx+1)/last) + (((curidx+1) % last === 0) ? 0 : 1)
            }
            keyx.sort((x, y) => { return x.kcnt - y.kcnt })
          }
        }

        return {
          totalCount: totalCount,
          pageInfo: {
            num: page,
            hasNextPage: hasNextPage,
            hasPreviousPage: hasPreviousPage
          },
          edges: {
            node: keyx,
            cursor: cursor,
            endCursor: endCursor
          }
        }
      }
    }
}
export default resolvers
