import { useEffect, useState, useCallback } from 'preact/hooks';
import { Fragment } from 'preact';
//import { useQueryClient } from 'react-query'
import useHelp from './Helper/useHelp';
import MultiSelectSort from 'async!./MultiSelectSort';
import UserSearch from 'async!./UserSearch';
import Helper from 'async!./Helper';
import Popup from 'async!./Compo/Popup';
//import draggable_element from './Compo/draggable_element';
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       '../style/style_ctrlcompo');
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       "@fancyapps/ui/dist/carousel.css");

const Home = () => {
  const searchx = process.env.NODE_ENV === 'production'? 'species/' : 'specieskey/';
  const [appstate, setAppState] = useState({
    loaded: false,
  });

  const [figx, setFigx] = useState({
    popup: false,
  /*hash to html: e.g.,  #fig_Acartia_bilobata_004 (Note no 's'
    '<a data-fancybox="gallery" href="#fig_Artia_bilobata_004"><img src="/assets/img/species/0004_Acartia_bilobata_$
  */
    html: '', //hash: #figs_xxx => get xxx
  });

  //const closeHelp = useHelp(state => state.closeHelp)
  const [hashstate, setHashState] = useState({
    handling: false,
    scrollTop: false,
    hash: '',
    elem: '', //store hash for scroll to element
  });
  const [querystr, setQueryStr] = useState({
    //handling: false,
    par: {},
  });

  const def_pageSize = 30;
  const [search, setSearch] = useState({
    str: '',
    init: false,
    searched: false,
    isLoading: false,
    getsize: def_pageSize,
    param: { first: def_pageSize },
  });
  const [searchSpkey, setSearchSpkey] = useState('');

  //const toHelp = useHelp(useCallback(state => state.toHelp, []));
  const iniHelp= useHelp(useCallback(state => state.iniHelp, []));

  const trigSearch = () => {
    if (searchSpkey && searchSpkey.trim() !== '' && searchSpkey !== search.str) {
      return(
        setSearch((prev) => ({
          ...prev,
          str: searchSpkey,
          searched: true,
          isLoading: true,
          param: { first: search.getsize },
        }))
      )
    } //console.log("Repeated search, dismiss it..")
  };

  const kickInitHelper = () => {
    if (iniHelp) {
      /*return(
        setAppState((prev) => ({
          ...prev,
          iniHelp: false,
          toHelp: false,
        }))
      )*/
      //closeHelp();
      useHelp.getState().closeHelp();
    }
  };
/*
  const queryClient = useQueryClient()
  const prefetchInit = useCallback(() => {
    const fetchingData = async () => {
      console.log("Prefetching: ", searchx.replace("/",""), "init");
      await Promise.resolve(queryClient.prefetchQuery("init", async () => {
        const res = await fetch(searchx + "init");
        if (!res.ok) {
          throw new Error('Error: Network response was not ok when prefetching... ')
        }
        return res.json()
      }, {
           staleTime: Infinity,
           cacheTime: Infinity //prefetchQuery will never return data
      })//.then((result) => {
        //   console.log("Data just got from perfectch: ", result);
        //   return(result);
        // })
      )
    };

    fetchingData();
  }, []);
*/
  const clear_uri = () => {
    let uri = window.location.toString();
    let clean_uri = uri.substring(0, uri.indexOf("#"));
    history.replaceState({}, document.title, clean_uri);
    return(
      setHashState((prev) => ({
        ...prev,
        handling: false,
        hash: '',
      }))
    )
  };

  const closePopup = () => {
    setFigx((prev) => ({
      ...prev,
      popup: false,
    }));

    clear_uri();
  };

  useEffect(() => {
//  prefetchInit();
    if (!appstate.loaded) {
      window.addEventListener("hashchange", (e) => {
        setHashState((prev) => ({
          ...prev,
          hash: window.location.hash,
        }))
      }, false);

      window.addEventListener("load", (e) => { //"popstate"
        let qstr = window.location.search
        let parx = qstr.substring(qstr.indexOf('?')).replace('?', '').split('&')
                       .reduce((r,e) => (r[e.split('=')[0]] = decodeURIComponent(e.split('=')[1]), r), {});
        //console.log("Popstate: ", parx);
        setQueryStr((prev) => ({
          ...prev,
          par: parx,
        }));
      }, false);
/*    let drag_opts = { dom: ".popup", dragArea: '.popup' };
      draggable_element(drag_opts);
*/
      setAppState((preState) => ({
        ...preState,
        loaded: true,
      }));
    } else {
      if (hashstate.hash === '#complete' && !hashstate.handling) {
        //console.log("Search complete and handle el, hash: ", hashstate.elem, search.isLoading);
        setHashState((prev) => ({
          ...prev,
          handling: true,
        }));
      } else if (!hashstate.handling && !search.isLoading) {
        if (hashstate.hash.substring(0,8) == '#search=') {
            setHashState((prev) => ({
              ...prev,
              elem: '',
              scrollTop: true,
            }));

            setSearch((prev) => ({
              ...prev,
              str: hashstate.hash.substring(8).replace(/\_/g, ' '),
              isLoading: true,
              param: { first: search.getsize },
            }));
        } else if (hashstate.hash !== '') {
          let el = document.querySelector(hashstate.hash);
          if (el) {
            setHashState((prev) => ({
              ...prev,
              handling: true,
              elem: hashstate.hash,
              scrollTop: false,
            }));
          } else {
            let parx, ukey, spx;
            let scrollTop = false;
            let spt = hashstate.hash.split(/\_/);
            let keyx= hashstate.hash.substring(0,4);
            if (keyx === '#gen' || keyx === "#epi" || keyx === "#key") {
              if (keyx = "#key") {
                let nkey = parseInt(spt[2].replace(/[a-z]/g,''));
                let nkeyx= (isNaN(nkey)? '_00a_genus' : (nkey < 10? '_0' + spt[2] : '_' + spt[2]));
                ukey = spt[1] + nkeyx
              } else {
                ukey = spt[1] + '_00a_genus'
              }
              spx = spt[1];
              //it's not really a 'after' key because it should search keys which >= ukey (not > ukey))
              //parx = {taxon: spt[1], first: search.getsize, after: ukey};
              //scrollTop = true; // new query will be on top
            } else if (keyx === "#tax" || keyx === "#fig") {
              ukey = 'fig_' +  spt[1] + (spt[2]? '_'+spt[2] : ''); //fig key is not really really fig_xxx_xxx in mongo, need re-index
              //parx = {taxon: spt[1] + (spt[2]? ' '+spt[2] : ''), first: search.getsize, after: ukey};
              spx = spt[1] + (spt[2]? ' '+spt[2] : '');
            }
            // NOT search ok would cause el is null and cannot scroll, so setting handling must wait seach completed!!
            setHashState((prev) => ({
              ...prev,
              //handling: true,
              elem: hashstate.hash,
              scrollTop: scrollTop,
            }));

            setSearch((prev) => ({
              ...prev,
              str: spx, //'', //cannot used default search original taxon that had been searched after supporting multi-species search
              isLoading: true,
              param: { key: ukey, first: search.getsize },
            }));
          }
        }
      } else if (hashstate.handling) {
        let el;
        if (hashstate.elem !== '') { el = document.querySelector(hashstate.elem) }
        //console.log("Hash change and scroll: ", hashstate.elem, hashstate.scrollTop, el);
        if (el) {
          let topPos = hashstate.scrollTop? 0 : el.getBoundingClientRect().top + window.pageYOffset;
          window.scrollTo({
            top: topPos, // scroll so that the element is at the top of the view
            behavior: 'smooth' // smooth scroll
          })
        }
        if (hashstate.elem.substring(0,4) === "#fig") {
          let spx = hashstate.elem.substring(hashstate.elem.indexOf('_')+1);
          let spt = spx.split(/\_/);
          if (spt.length == 2) {
            spx = spx + '_01'; //add a number fo species, but we don't validate species yet
          }
          if (spt.length >= 2) {
            let hstr='<a data-fancybox="gallery" href="/assets/img/species/' + spx + '.png" target="_blank"' +
                     '><img src="/assets/img/species/' + spx + '.png" border="0" /></a>';
            setFigx((prev) => ({
              ...prev,
              popup: true,
              html: hstr,
            }));
          }
        }
        clear_uri();
      } else {
        console.log("Check uncertain state: ", search.isLoading, hashstate);
      }
    }
  },[appstate.loaded, hashstate]); //, prefetchInit

  const render_userhelper = () => {
    if (appstate.loaded && search.init) {
      return <Helper />
    }
    return null;
  };

  return(
    <Fragment>
      <div id="homediv" onClick={kickInitHelper}>
        <div class="headdiv">
          <div class="float-left-div">
              <p class="flexpspan">
                <label for="spkeysearch" style="color:grey" />
                <input type="search" id="spkeysearch" name="spkeysearch" placeholder="Search species key"
                   onInput={(e) => { setSearchSpkey(e.target.value) }} />
                <button class="ctrlbutn" id="keysearchbutn" onClick={trigSearch}>Search</button>
              </p>
              { iniHelp &&
                <p style="text-indent:0;" class="triangle-right top" id="search_tooltips">Search taxon for its identification key<br/>搜尋物種分類檢索，輸入物種名</p>
              }
          </div>
          <MultiSelectSort />
        </div>
        <UserSearch query={querystr.par} search={search} onSearch={setSearch} />
        { render_userhelper() }
      </div>
      { figx.popup && <Popup ctxt={figx.html} onClose={closePopup} /> }
    </Fragment>
  );
};
export default Home;
