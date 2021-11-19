import { useEffect, useState, useCallback } from 'preact/hooks';
import { Fragment } from 'preact'; //options
//import { useQueryClient } from 'react-query'
import useHelp from './Helper/useHelp';
import MultiSelectSort from 'async!./MultiSelectSort';
import UserSearch from 'async!./UserSearch';
import Helper from 'async!./Helper';
import Popup from 'async!./Compo/Popup';
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
    html: '', //hash: #figs_xxx_bbb => get xxx bbb (sp), fig_@@@ -> get fig@@@.jpg (genus)
  });

  //const closeHelp = useHelp(state => state.closeHelp)
  const [hashstate, setHashState] = useState({
    handling: false,
    handlend: true,
    scrollPos: 0,
    hash: '',
    elem: '', //store hash for scroll to element
  });
  const [querystr, setQueryStr] = useState({
    par: {},
  });

  const def_pageSize = 30;
  const forceGenus = false;
  const forceSpecies = false;

  const [search, setSearch] = useState({
    str: '',
    init: false,
    searched: false,
    keycheck: false,
    isLoading: false,
    getsize: def_pageSize,
    param: { keystr: false, mode: 'genus', first: def_pageSize }, //mode: 'genus', 'species', 'All'
  });
  const [searchSpkey, setSearchSpkey] = useState('');

  const searchmodex = (mode) => (forceGenus? 'genus' : (forceSpecies? 'species' : mode));

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
          param: { keystr: search.keycheck,
                   mode: searchmodex('All'),
                   first: search.getsize },
        }))
      )
    } //console.log("Repeated search, dismiss it..")
  };

  const toggleKeystrSearch = e => { //use search input as key string to be searched
    let checked = !search.keycheck;
    setSearch((prev) => ({
        ...prev,
        keycheck: checked,
    }))
  };

  const kickInitHelper = () => {
    if (iniHelp) {
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
  }, []);*/
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

  const padZero = (key, prefix='', pad=2) => {
    if (isNaN(key)) return prefix;
    if (pad === 2) return prefix + (key < 10? '00' + key : (key < 100? '0' + key : key));
    return prefix + (key < 10? '0' + key : key);
  };

  const openPopup = () => {
    if (hashstate.elem.substring(0,4) === "#fig") {
      let spx = hashstate.elem.substring(hashstate.elem.indexOf('_')+1);
      let spt = spx.split(/\_/);
      let dir = 'species';
      let nkey = parseInt(spt[0]);
      if (spt.length == 1 && !isNaN(nkey)) {
        spx = padZero(nkey, 'fig');
        dir = 'genus';
      } else if (spt.length == 2) {
        spx = spx + '_01'; //add a number fo species, but we don't validate species yet
      }
      if (spt.length) {
        //let hstr='<a data-fancybox="gallery" href="/assets/img/species/' + spx + '.jpg" target="_blank"' +
        //         '><img src="/assets/img/species/' + spx + '.jpg" border="0" /></a>';
        let hstr='<a data-fancybox="gallery" href="https://bio.odb.ntu.edu.tw/pub/copkey/' +
                 dir + '/' + spx + '.jpg" target="_blank"' +
                 '><img src="https://bio.odb.ntu.edu.tw/pub/copkey/' +
                 dir + '/' + spx + '.jpg" border="0" /></a>';
        setFigx((prev) => ({
          ...prev,
          popup: true,
          html: hstr,
        }));
      }
    }
  }

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
          handlend: false,
        }));
      } else if (!hashstate.handling && !search.isLoading) {
/*      if (hashstate.hash.substring(0,8) == '#search=') {
            setHashState((prev) => ({
              ...prev,
              elem: '',
              scrollPos: 0, //scrollTop: true,
            }));

            setSearch((prev) => ({
              ...prev,
              str: hashstate.hash.substring(8).replace(/\_/g, ' '),
              isLoading: true,
              param: { keystr: search.keycheck,
                       first: search.getsize },
            }));
        } else*/
        if (hashstate.hash !== '') {
          let el = document.querySelector(hashstate.hash);
          if (el) {
            setHashState((prev) => ({
              ...prev,
              handling: true,
              handlend: false,
              elem: hashstate.hash,
              //scrollTop: false,
              scrollPos: -1, // el.getBoundingClientRect().top + window.pageYOffset
            }));
            // Note 20211117 genus fig has the same span name as key, so when it's found, it will only scroll, not open, need handle it
            openPopup();
          } else {
            let parx, ukey, spx;
            //let scrollTop = false;
            let spt = hashstate.hash.split(/\_/);
            let keyx= hashstate.hash.substring(0,4);
            let nkey = parseInt(spt[1]);
            let modex= search.param.mode;
            if ((keyx === '#tax' && spt.length === 2) || keyx === '#gen' || keyx === "#epi" || keyx === "#key") {
              if (keyx === "#key") {
              //20211115 add to detect genus: key_1 -> 00a_genus_001a
                if (spt.length === 2 && !isNaN(nkey)) { //for e.g. key_005
                  ukey = padZero(nkey, '00a_genus_') + 'a';
                  modex= 'genus';
                  spx = '';
                } else {
                  let epi = spt[2]??'';
                  nkey = parseInt(epi.replace(/[a-z]/g,''));
                  ukey = padZero(nkey, spt[1] + '_', 1) + (isNaN(nkey)? '00a_genus' : 'a');
                  modex= 'species';
                  spx = spt[1];
                }
                parx = { key: ukey, keystr: false, mode: modex, first: search.getsize };
              } else {
                //ukey = spt[1] + '_00a_genus' //if just search taxon, can be removed
                modex= 'species';
                spx = spt[1]
                parx = { keystr: false, mode: modex, first: search.getsize };
              }
              //console.log("Hash change: try search ukey: ", ukey, " and taxon: ", spx, " in mode: ", modex);
              //it's not really a 'after' key because it should search keys which >= ukey (not > ukey))
              //parx = {taxon: spt[1], first: search.getsize, after: ukey};
              //scrollTop = true; // new query will be on top
            } else if ((keyx === "#tax" && spt[2]) || keyx === "#fig") {
              if (keyx === '#fig' && spt.length == 2 && !isNaN(nkey)) { //2021115 for genus
                ukey = padZero(nkey, '00a_genus.*figs.*', 2) + '.*'     //mode do not change
                spx = ''
              } else {
                ukey = 'fig_' +  spt[1] + (spt[2]? '_'+spt[2] : ''); //fig key is not really fig_xxx_xxx in mongo, need re-index
                spx = spt[1] + (spt[2]? ' '+spt[2] : '');
              }
              parx = { key: ukey, keystr: false, mode: modex, first: search.getsize };
            }
            // NOT search ok would cause el is null and cannot scroll, so setting handling must wait seach completed!!
            setHashState((prev) => ({
              ...prev,
              //handling: true,
              elem: hashstate.hash,
              //scrollTop: scrollTop,
              scrollPos: -1, //-1 means current hash not found, need search (still not know how to scroll)
            }));

            setSearch((prev) => ({
              ...prev,  //Note: str changed to '' will cause a server-stuck-on=searching key if multi=selected taxons and click a key not existed on current page
              str: spx, //'', //cannot used default search original taxon that had been searched after supporting multi-species search
              isLoading: true,
              param: parx, //{ key: ukey, keystr: false, mode: modex, first: search.getsize },
            }));
          }
        }
      } else if (hashstate.handling) {
        let el;
        let to_el = 0;
        let fig_offset = 0;
        let to_pos= window.pageYOffset;
        if (!hashstate.handlend & hashstate.elem !== '') {
          if (hashstate.scrollPos != 0) {
            el = document.querySelector(hashstate.elem)
            if (hashstate.elem.substring(0,5) === "#fig_") {
              fig_offset = 440; //330 is the height of thumb by imagemagick;// carousel + padding + margin > 400 pixel
            }
            to_pos = el.getBoundingClientRect().top + window.pageYOffset - fig_offset;
          } else {
            to_pos = 0
          }
          window.scrollTo({
              top: to_pos, // scroll so that the element is at the top of the view
              behavior: 'smooth' // smooth scroll
          })
        }
        setHashState((prev) => ({
            ...prev,
            handlend: true,
            scrollPos: to_pos,
        }));
        clear_uri();
        openPopup();
      }
    }
  },[appstate.loaded, hashstate.hash, hashstate.handling]); //, prefetchInit

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
                <label for="spkeysearch" style="color:grey;" />
                <input type="search" id="spkeysearch" name="spkeysearch" placeholder="Search species key"
                   onInput={(e) => { setSearchSpkey(e.target.value) }} />
                <button class="ctrlbutn" id="keysearchbutn" onClick={trigSearch}>Search</button>
                <label for="keystrsearch" style="margin-top:10px;">
                  <input type="checkbox" id="keystrsearch" aria-label="Enable searching identification key string"
                         checked={search.keycheck} onClick={toggleKeystrSearch} />
                </label>
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
