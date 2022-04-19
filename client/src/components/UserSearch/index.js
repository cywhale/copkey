import { Fragment } from 'preact';
import { useState, useEffect, useCallback, useRef } from 'preact/hooks';
import { useQueryClient } from 'react-query'; //useQuery
import useOpts from '../TabModal/useOpts';
import Copkey from 'async!../Copkey';
import SvgLoading from 'async!../Compo/SvgLoading';
import deKeytree from './deKeytree';
import (/* webpackMode: "lazy" */
        /* webpackPrefetch: true */
        "../../style/style_usersearch.scss");

const UserSearch = (props) => {
  const { query, search, onSearch } = props; //searched only trigger when str is set;
                                             //isLoading when any search start and wait for result written
  const sameTaxon= useOpts(useCallback(state => state.sameTaxon, []));
  const pageSize= useOpts(useCallback(state => state.pageSize, [])); //30
  const failRetry= 3;
/*const [state, setState] = useState({
    init: false, //initial searching (move upper, because useHelp need elements after first search)
    //querystring: ''
  });*/
  const [result, setResult] = useState({
    spkey: {key:'', fig:''},
    taxon: '', //initially loaded //2021118 change 'Acartia' to '' && mode=genus
    keyParam: {},
    totalCount: 0,
    cursor: '',
    endCursor: '',
    pageInfo: {num: 0, hasNextPage: false, hasPreviousPage: false}
  });
/*const [page, setPage] = useState({ //pageParam move upper, searh keyword should set param with only 'first'
    offset: 0,
  });*/
  const butnPrevRef = useRef(null); //use eleRef.current, instead of document.getElementById
  const butnNextRef = useRef(null);

  const def_queryOpts = {
    retry: failRetry,
    staleTime: Infinity,
    cacheTime: Infinity, //most data are static, need no update..
    keepPreviousData: true
  }

  const searchPrefix = process.env.NODE_ENV === 'production'? 'species/' : 'specieskey/';
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
    let ctxt = //data[key].reduce((acc, cur) => { return(acc + cur["ctxt"] + "\\n") }, "") //concat first make keyx overmatch because (.*) when a doc cross different genus
               data[key].reduce((acc, cur) => { return({
                   key: acc.key + (cur["ctxt"].match(/\<div (class=\"kblk|id=\"genus_|id=\"species_)(.*)\/p\>\<\/div\>(\<br\>)*/g)||[''])[0],
                   fig: (acc.fig +(cur["ctxt"].match(/\<div id=\"figs_(.*)\/span\>(\<\/div\>)+(\<br\>)*/g) || [""])[0] + "\\n")
                        .replace(/(\\n)+/g,'\\n') //needed in Copimg.js, and some additional fig append to the same figs_xxx div need separate it with \\n
                        .replace(/\<\/div\>(\<br\>){2,4}\<div class=\"blkfigure/g, '</div><br><br>\\n<div class="blkfigure')
                 })
               }, {key: '', fig: ''})
                 //.replace(/img\//g,'/assets/img/species/').replace(/\.(jpg|jpeg)/g, '.png') //no need in newer version data stored in mongo 20210921
                 //.replace(/a class=/g, 'a data-fancybox="gallery" class=');
  /*let keyx = (ctxt.match(/\<div (class=\"kblk|id=\"genus_|id=\"species_)(.*)(?=\/p\>\<\/div\>(\<br\>)*)/g)||[''])[0]
                 .replace(/\\n/g,'');
    let figx = (ctxt.match(/\<div id=\"figs_(.*)(?=\/span\>\<\/div\>(\\n)*)/g) || [""])[0]; //split that feed into Fancybox
    return({key: keyx, fig: figx});*/
    return ctxt;
  };

  const pageFetch = async (pageParam, signal) => {
      const gql = pageParam.mode === 'keytree'? 'keytree': 'page';
      console.log('Fetch graphQL: ', gql, ' for mode: ', pageParam.mode);
      const res = await fetch(searchPrefix + gql, {
            method: 'POST',
            body: JSON.stringify(pageParam),
            credentials: 'same-origin',
            mode: 'same-origin',
            redirect: 'follow',
            referrer: 'no-referrer',
            headers: {
              'content-type': 'application/json',
              'Accept': 'application/json'
            },
            signal: signal
      });
      if (!res.ok) {
        let { taxon, ...keyParam } = pageParam;
        /*await queryClient.cancelQueries([taxon, keyParam]); //it works but try another reset function in react-query
        throw new Error('Error: Network response was not ok when searching... ')*/
        console.log('Error: Network response was not ok when searching... ');
        queryClient.resetQueries([taxon, keyParam],
          { exact: true, ResetOptions: {throwOnError: false, cancelRefetch: true} })
        history.pushState(null, null, '#error');
        window.dispatchEvent(new HashChangeEvent('hashchange'));
      }
      return res.json()
  };

  const searchWrite = (data, taxon, keyParam) => {
    let dt = data;
    //if (!search.init && search.isLoading) { //!!Set WriteEnable cause init search not render correctly!!
/*    if (!data || !data.edges || !data.edges.node.length) {
        dt = queryClient.getQueryData([taxon, keyParam]).data['infq'];
        console.log("No data but fetched from queryClient, get nodes: ", dt.edges.node.length, " for ",taxon, " with ", keyParam);
      }*/
      let ctxt;
      if (keyParam.mode === 'keytree') {
        ctxt = deKeytree(dt.data['keytree'][0])
      } else {
        ctxt = trans_htmltxt(dt.data['infq'].edges, "node"); //data.data['infq'].edges
      }
      let taxonx = search.param.keystr? result.taxon: taxon; //if keystr search, don't overwrite result.taxon to do sameTaxon search 20211125
      setResult((prev) => ({
          ...prev,
          spkey: ctxt,
          taxon: taxonx,
          keyParam: keyParam, //store keyParam for this result, but not used yet
          totalCount: dt.totalCount,
          cursor: dt.edges.cursor,
          endCursor: dt.edges.endCursor,
          pageInfo: dt.pageInfo
      }));
      //console.log("Writing result: ", dt.edges.node.length," of ", taxon, " for cursor: ", dt.edges.cursor, dt.edges.endCursor);
    //}
    onSearch((prev) => ({
        ...prev,
        isLoading: false
    }))

    if (butnPrevRef.current) {
      if (data.pageInfo.hasPreviousPage) {
        //document.getElementById('butn_prev').disabled = false;
        butnPrevRef.current.removeAttribute('disabled');
      } else {
        butnPrevRef.current.setAttribute('disabled', 'disabled');
      }
    }
    if (butnNextRef.current) {
      if (data.pageInfo.hasNextPage) {
        butnNextRef.current.removeAttribute('disabled');
      } else {
        butnNextRef.current.setAttribute('disabled', 'disabled');
      }
    }
    if (window.location.hash) {
      history.pushState(null, null, '#complete');
      window.dispatchEvent(new HashChangeEvent('hashchange'));
    }
  };

  //useQuery hook must used inside component, here use fetchQuery //note: prefetchQuery will never return data
  const fetchingQuery = async (taxon, keyParam) => {
      if (search.keycheck && sameTaxon) {
        keyParam["mode"] = keyParam["mode"] + ":" + result.taxon; //limited to search current taxon 20211125
      }
      const pageParam = { taxon: taxon, ...keyParam };
      let searchtxt = taxon === ''? 'All' : taxon;
      let qstr = 'page?' + //if you use 'GET' method
                 Object.keys(pageParam).map((x) => { return x + '=' + pageParam[x] }).join('&')
      //document.getElementById('butn_prev').disabled = true;
      if (butnPrevRef.current) { butnPrevRef.current.setAttribute('disabled', 'disabled') }
      if (butnNextRef.current) { butnNextRef.current.setAttribute('disabled', 'disabled') }
/*    const timeout_ctrl = new AbortController(); //timeout controller
      const timeout = async (delay) => {
        try {
          await setTimeout(delay, undefined, { signal: timeout_ctrl.signal });
          //controller.abort(); //abort cancel request controller
          queryClient.cancelQueries([searchtxt, keyParam]);
        } catch (error) {
          return;
        }
        throw new Error(`Request aborted as it took longer than ${delay}ms`);
      };*/
      const pfetch = async () => {
        const controller = new AbortController(); //cancel request contorller
        const res = await queryClient.fetchQuery([searchtxt, keyParam], async () => {
            const data = await pageFetch(pageParam, controller.signal);
            await onSearch((prev) => ({
              ...prev,
              searched: false,
              //isLoading: false, //after write
            }))
            return data;
        }, def_queryOpts);
        //res.finally = () => timeout_ctrl.abort();
        res.cancel = () => controller.abort();
        return res;
      };

      try {
      //await Promise.race([pfetch(), timeout(1000)])
        await Promise.resolve(pfetch())
        .then((data) => {
          if (data) {
            //let dtk=keyParam.mode==='keytree'? data.data['keytree'][0]: data.data['infq'];
            searchWrite(data, taxon, keyParam); //dtk

            if (!search.init) {
              onSearch((prev) => ({
                ...prev,
                init: true,
              }))
            }
          }
        }, qstr, taxon)
      } catch (error) {
        console.log(error);
        onSearch((prev) => ({
            ...prev,
            searched: false,
            isLoading: false,
        }))
        history.pushState(null, null, '#error');
        window.dispatchEvent(new HashChangeEvent('hashchange'));
      }
  };

  const fetchQueryIF = (enable, taxon, keyParam) => {
    useEffect(() => enable && fetchingQuery(taxon, keyParam), [enable])
  };

  const waitInitData = useCallback((query) => {
  //return(queryClient.getQueryData("init")); //prefetchQuery may later than you want it, then undefined!
  /*let r = queryCache.find("init"); //It's a whole cache object
    if (r) { return Promise.resolve(r); }*/
    let kobj = {};
    if (query && (query.first || query.last)) {
        kobj["taxon"] = query.taxon??'';
        kobj["mode"] = query.mode? query.mode : 'All';
        if (typeof query.first !== 'undefined') { kobj["first"] = parseInt(query.first)??pageSize }
        if (typeof query.last !== 'undefined')  { kobj["last"] = parseInt(query.last??pageSize) }
        if (typeof query.after !== 'undefined') { kobj["after"] = query.after }
        if (typeof query.before !== 'undefined'){ kobj["before"] = query.before }
        if (typeof query.key !== 'undefined'){ kobj["key"] = query.key }
    } else {
        if (query && query.taxon) {
          kobj = { "taxon": query.taxon, "mode": "All", "first": pageSize }
        } else {
          kobj = { "taxon": "", "keystr": false, "mode": search.param.mode, "first": pageSize } //'init', change "Acatia" to genus 20211118
        }
    } // '?page=' + query.page : '?page=1'); //old, will be deprecated
    // 'GET', and now changed to use 'POST'
    /* let querystr = 'page?' + Object.keys(kobj).map(function(x) {
      return x + '=' + kobj[x];
    }).join('&') */
    onSearch((prev) => ({
       ...prev,
       isLoading: true
    }))

    const { taxon, ...keyParam } = kobj;
    fetchingQuery(taxon, keyParam);
  }, []);

  useEffect(() => {
    waitInitData(query)
  },[waitInitData, query]);
/*
  let taxon = (search.str !== '' && search.searched && state.init? search.str :
              (!state.init? (query.taxon??'Acartia') : (query.taxon??'')))*/
  const goPrevPage = () => {
    //if (!result.pageInfo.hasPreviousPage) return;
    onSearch((prev) => ({
      ...prev,
      param: {
        keystr: search.keycheck,
        mode: search.param.mode,
        last: pageSize,
        before: result.cursor
      },
      isLoading: true
    }))
  }

  const goNextPage = () => {
    //if (!result.pageInfo.hasNextPage) return;
    onSearch((prev) => ({
      ...prev,
      param: {
        keystr: search.keycheck,
        mode: search.param.mode,
        first: pageSize,
        after: result.endCursor
      },
      isLoading: true
    }))
  }

  const render_search = (query, keyParam) => {
    let searching = search.str;
    //let enable = search.searched;
    let qtaxon = (searching === ''? result.taxon :
                 (searching.toLowerCase() === 'all' || searching === '*'? '' : searching));
    let searchtxt = qtaxon === ''?  'All' : qtaxon;
  //console.log("Now search: ", qtaxon, " with param: ", keyParam);
/* !! Set SearchEnable may cause init search perform not correctly !!
    let chk_identical = qtaxon === result.taxon && keyParam === result.keyParam;
    console.log("Check with: ", result.taxon, " with param: ", result.keyParam, " at isLoading: ", search.isLoading);
    if (chk_identical || (!search.isLoading && result.taxon === 'Acartia' && Object.keys(result.keyParam).length === 0)) {
      console.log("While INIT or OLD search NOT performed: ", qtaxon, " with param: ", keyParam);
    } else {
      //useQuery actually cause some problems for async data loading and then update whole html
      const qryx = useQuery([searchtxt, keyParam], async () => {
        const pageParam = {
          taxon: qtaxon,
          ...keyParam
        }

        const data = await pageFetch(pageParam);
        await onSearch((prev) => ({
           ...prev,
           searched: false,
           //isLoading: false, //after write
        }))

        return data;
      },{ ...def_queryOpts,
          enabled: enable, // search.searched && state.init},
          //!! Note that "init" query has data.data.init not the same as spquery by name as: data.data.key !!
          initialData: () => { //placeholderData
            return waitInitData(query) //queryClient.getQueryData("init")
          }
      }, query)
*/
    fetchQueryIF(search.isLoading, qtaxon, keyParam);
    //}
    //console.log("After WriteIF Status with taxon: ", qtaxon, search.searched, search.isLoading); //, data.data['infq'].edges.cursor); //qryx.status
    //console.log("Have prev or next: ", result.pageInfo.hasPreviousPage, result.pageInfo.hasNextPage);
    return(
      <SvgLoading enable={true} isLoading={search.isLoading} />
    )
  };
  // only when isLoading, data write into result, and update Copkey, so that destroy old img carousel
  return (
    <Fragment>
      { render_search(query, search.param) }
      <Copkey ctxt={result.spkey} load={search.isLoading}>
          <div class='inlinebutn'>
            <button class='pagebutn' id='butn_prev' ref={butnPrevRef} onClick={goPrevPage}>&#60;</button>
            <span>{ result.pageInfo.num }</span>
            <button class='pagebutn' id='butn_next' ref={butnNextRef} onClick={goNextPage}>&#62;</button>
          </div>
      </Copkey>
    </Fragment>
  )
};
export default UserSearch;
