import { Fragment } from 'preact';
import { useState, useEffect, useCallback, useRef } from 'preact/hooks';
import { useQuery, useQueryClient } from 'react-query';
//import useHelp from '../Helper/useHelp';
import Copkey from 'async!../Copkey';

const UserSearch = (props) => {
  const { query, search, onSearch } = props;
  const pageSize = 30;
  const failRetry= 3;
  const [state, setState] = useState({
    init: false, //initial searching
    curpage: 1,
    queryed: {taxon:'', str:''}
  });
  const [result, setResult] = useState({
    spkey: {key:'', fig:''},
    totalCount: 0,
    cursor: '',
    pageInfo: {num: 0, hasNextPage: false, hasPreviousPage: false}
  });

  const searchx = process.env.NODE_ENV === 'production'? 'species/' : 'specieskey/';
  //const toHelp = useHelp.getState().toHelp;
  //const queryCache = queryClient.getQueryCache()
  const queryClient = useQueryClient();

  const trans_htmltxt = (data, key="node") => {
    //if (process.env.NODE_ENV === 'production') {
    // return(data.data[key].reduce((acc, cur) => { return(acc + cur["ctxt"])}, "").replace(/img\//g,'/img/species/'))
    //} //.replace(/^(<\/div>)/g,''); //.replace(/class/g, 'className');
    /*let dtk ;
    if (key === "infq") {
      dtk = data.data[key].edges.node;
    } else {
      dtk = data.data[key];
    }*/
    let ctxt = data[key].reduce((acc, cur) => { return(acc + cur["ctxt"] + "\\n") }, "")
                 //.replace(/img\//g,'/assets/img/species/').replace(/\.(jpg|jpeg)/g, '.png') //no need in newer version data stored in mongo 20210921
                 //.replace(/a class=/g, 'a data-fancybox="gallery" class=');
    let keyx = (ctxt.match(/\<div (class=\"kblk|id=\"genus_|id=\"species_)(.*)\/p\>\<\/div\>(\<br\>)*/g)||[''])[0]
                 .replace(/\\n/g,'');
    let figx = (ctxt.match(/\<div id=\"figs_(.*)\/span\>\<\/div\>(\\n)*/g) || [""])[0]; //split that feed into Fancybox

    return({key: keyx, fig: figx});
  };

  const waitInitData = useCallback((query) => {
  //return(queryClient.getQueryData("init")); //prefetchQuery may later than you want it, then undefined!
  /*let r = queryCache.find("init"); //It's a whole cache object
    if (r) { return Promise.resolve(r); }*/
    let kobj = {};
    if (query && (query.first || query.last)) {
        //if (typeof query.taxon !== 'undefined') {
        kobj["taxon"] = query.taxon??'' //|| '';//}
        if (typeof query.first !== 'undefined') { kobj["first"] = parseInt(query.first) }
        if (typeof query.last !== 'undefined')  { kobj["last"] = parseInt(query.last) }
        if (typeof query.after !== 'undefined') { kobj["after"] = query.after }
        if (typeof query.before !== 'undefined'){ kobj["before"] = query.before }
    } else {
        if (query && query.taxon) {
          kobj = { "taxon": query.taxon, "first": pageSize }
        } else {
          kobj = { "taxon": "Acartia", "first": pageSize } //'init'
        }
    } // '?page=' + query.page : '?page=1'); //old, will be deprecated
    let querystr = 'page?' + Object.keys(kobj).map(function(x) {
      return x + '=' + kobj[x];
    }).join('&')

    const fetchingInit = async (qstr, pageParam) => {
      const { taxon, ...keyParam } = pageParam;
      let searchtxt = taxon === ''? 'All' : taxon;
      await Promise.resolve(queryClient.fetchQuery([searchtxt, keyParam], async () => {
          const res = await fetch(searchx + qstr);
          if (!res.ok) {
            throw new Error('Error: Network response was not ok when fetchingInit: ' + qstr)
          }
          return res.json()
        }, { retry: failRetry,
             staleTime: Infinity,
             cacheTime: Infinity //prefetchQuery will never return data
        })
      ).then((data) => {
        if (data) {
          let dtk=data.data['infq'];
          //let qkey = ((qstr.substring(0,1) === "?")? qstr.substring(1,qstr.indexOf("=")) : qstr);
          let ctxt = trans_htmltxt(dtk.edges, 'node') //data, qkey
          setResult((prev) => ({
            ...prev,
            spkey: ctxt,
            totalCount: dtk.totalCount,
            cursor: dtk.edges.cursor,
            pageInfo: dtk.pageInfo
          }));

          setState((prev) => ({
            ...prev,
            init: true,
            curpage: dtk.pageInfo.num,
            queryed: { taxon: taxon, str: qstr }
          }))
        }
      }, qstr, taxon)
    };

    fetchingInit(querystr, kobj);
  }, []);

  useEffect(() => {
    //if (!state.init) {}
    waitInitData(query);
  },[waitInitData, query]);


  const render_search = (query, keyParam) => {
    let searchtxt = search.str === ''? 'All' : search.str;
    //const { isLoading, isError, data, error } = useQuery(
    const qryx = useQuery([searchtxt, keyParam], async () => {
      const pageParam = {
          taxon: search.str,
          ...keyParam
      }

      const res = await fetch(searchx + 'page', {
        method: 'POST',
        body: JSON.stringify(pageParam),
        credentials: 'same-origin',
        mode: 'same-origin',
        redirect: 'follow',
        referrer: 'no-referrer',
        headers: {
          'content-type': 'application/json',
          'Accept': 'application/json'
        }
      });

      if (!res.ok) {
        throw new Error('Error: Network response was not ok when searching... ')
      }
      return res.json()

    },{ enabled: search.searched,// && state.init},
        retry: failRetry,
        keepPreviousData: true, //!! Note that "init" query has data.data.init not the same as spquery by name as: data.data.key !!
        initialData: () => { //placeholderData
          return waitInitData(query) //queryClient.getQueryData("init")
            //(searchx.replace("/",""))
            //?.find(d => d.name === "init")
        }
    }, query)

    if (qryx.isError) {
      console.log("Error when searching: ", qryx.error.message, " and Failure count: ", qryx.failureCount);
      if (qryx.failureCount >= failRetry) {
        alert("Warning: Nothing found or uncertain errors occurred when searching: ", searchtxt);
        onSearch((prev) => ({
           ...prev,
           searched: false,
            isLoading: false
        }))
      }
    }; //not affect previous searching result

    let ctxt;
    let data = qryx.data;
    let NotFound = true;
    //let NotInit = false;
    if (data && search.searched && !qryx.isError && !qryx.isLoading) {
      if (data.data === {} || !data.data['infq'].edges.node.length) {
          alert("Warning: Nothing found when searching: ", searchtxt);
      } else {
          NotFound = false;
          ctxt = trans_htmltxt(data.data['infq'].edges, "node");
      }
      onSearch((prev) => ({
          ...prev,
          searched: false,
          isLoading: false
      }))
      /*else if (result.spkey==='') {
        NotFound = false;
        ctxt = data.data.init.reduce((acc, cur) => { return(acc + cur["ctxt"])}, "").replace(/img\//g,'/assets/img/species/');
      }*/
      if (ctxt) {
        setResult((prev) => ({
          ...prev,
          spkey: ctxt
        }));
      }
    }

    let ctent;
    if (NotFound) { // Fragment(result.spkey)
      //console.log("Note: using previous result", state.init);
      ctent = result.spkey
    } else {
      ctent = ctxt
    }

    return(//render(<Fragment />, document.getElementById('resultxdiv'))
      <Copkey ctxt={ctent} />
    )
  };
/*
  let taxon = (search.str !== '' && search.searched && state.init? search.str :
              (!state.init? (query.taxon??'Acartia') : (query.taxon??'')))*/
  return (
    <Fragment>
      {state.init && render_search(query, { first: pageSize })}
    </Fragment>
  )
};
export default UserSearch;
