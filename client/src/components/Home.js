import { useEffect, useState, useCallback } from 'preact/hooks';
import { Fragment } from 'preact'; //options
//import { useQueryClient } from 'react-query'
import useHelp from './Helper/useHelp';
import useOpts from './TabModal/useOpts';
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
  const lang= useHelp(useCallback(state => state.lang, []));
  const pageLoaded = useOpts(useCallback(state => state.pageLoaded, []));
  const fuzzy = useOpts(useCallback(state => state.fuzzy, []));         //only for keystr search
  const sameTaxon= useOpts(useCallback(state => state.sameTaxon, []));  //only for keystr search
  const forceGenus= useOpts(useCallback(state => state.forceGenus, []));     //false
  const forceSpecies= useOpts(useCallback(state => state.forceSpecies, [])); //false
  const pageSize= useOpts(useCallback(state => state.pageSize, []));         //30
  const keyTree= useOpts(useCallback(state => state.keyTree, [])); //get tree of keys 202204

  const [appstate, setAppState] = useState({
    loaded: false,
    iniHash: '',
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

  const [search, setSearch] = useState({
    str: '',
    init: false,
    searched: false,
    keycheck: false,
    isLoading: false,
    //getsize: pageSize,
    param: { keystr: false, mode: 'genus', first: pageSize }, //mode: 'genus', 'species', 'All'
  });
  const [searchSpkey, setSearchSpkey] = useState('');

  const searchmodex = (mode) => (forceGenus? 'genus' : (forceSpecies? 'species' : mode));

  //const toHelp = useHelp(useCallback(state => state.toHelp, []));
  const iniHelp= useHelp(useCallback(state => state.iniHelp, []));

  const trigSearch = () => {
    let mode0 = (search.keycheck && sameTaxon? (fuzzy? ('fuzzy,' + searchmodex('All') + ',sameTaxon'): (searchmodex('All') + ',sameTaxon')):
                (fuzzy? ('fuzzy,' + searchmodex('All')): searchmodex('All')));
    let modex = keyTree? 'keytree': mode0; //20220419 added: list key-tree mode by option keyTree
    if (searchSpkey && searchSpkey.trim() !== '' && (searchSpkey !== search.str || search.param.keystr != search.keycheck ||
                                                     search.param.mode !== modex|| search.param.first != pageSize)) {
      return(
        setSearch((prev) => ({
          ...prev,
          str: searchSpkey,
          searched: true,
          isLoading: true,
          param: { keystr: search.keycheck,
                   mode: modex,
                   first: pageSize },
        }))
      )
    } //console.log("Repeated search, dismiss it..")
  };

  const toggleKeyTree = e => {
    let checked = !keyTree;
    useOpts.getState().setOpts({keyTree: checked}); //Note get keyTree if only for species, so forceGenus, and keycheck, will be omitted

    if (checked && (search.keycheck || forceGenus)) {
      alert("The option 'List nested identification keys of searched taxon' can only work for species searching. The options 'Enable searching characteristics' or 'Limit searching at only genus-level' would be disabled.\n" +
            "Please check your input of search box is the scientific names of species\n\n"  +
            "'列出所搜尋物種巢狀分類檢索'功能只可用於物種搜尋上，所以若勾選'搜尋分類特徵'或'僅在屬層級中搜尋'功能將被取消\n" +
            "並請確定在搜尋欄中所搜尋的文字為物種學名\n");
      if (checked && search.keycheck) {
        let keychk_checked = !search.keycheck;
        setSearch((prev) => ({
          ...prev,
          keycheck: keychk_checked,
        }))
      }

      if (checked && forceGenus) {
        let forcegenus_checked = !forceGenus;
        useOpts.getState().setOpts({forceGenus: forcegenus_checked});
      }
    }
  };

  const toggleKeystrSearch = e => { //use search input as key string to be searched
    let checked = !search.keycheck;
    setSearch((prev) => ({
        ...prev,
        keycheck: checked,
    }))

    if (checked && keyTree) { //keycheck (key string search) and keyTree options cannot be both enabled
      let keytree_checked = !keyTree;
      useOpts.getState().setOpts({keyTree: keyTree_checked});
    }
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
        handlend: true,
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
      let multiFig = false;
      if (spt.length > 1 && Number.isInteger(Number(spt[1]))) {
        multiFig = true; //modified 20220719: e.g. figs.154-158 may got #figs_153_154_155_156_157_158 don't open them, just scroll
      }
      if (spt.length == 1 && !isNaN(nkey)) {
        spx = padZero(nkey, 'fig');
        dir = 'genus';
      } else if (spt.length == 2 && !multiFig) {
        spx = spx + '_01'; //add a number fo species, but we don't validate species yet
      }
      if (spt.length && !multiFig) {
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
    //const handleLoad = () => {
      //console.log("DOMContent load: ", window.location.hash);
      if (window.location.hash) {
        //history.pushState(null, null, window.location.hash); //Cannot do it because initial page search/load not yet done
        //window.dispatchEvent(new HashChangeEvent('hashchange'));
        setAppState((preState) => ({
          ...preState,
          iniHash: window.location.hash,
        }));
      }
    //};
    //window.addEventListener('DOMContentLoaded', handleLoad)

    // Clean up event listeners on unmount
    //return () => {
    //  window.removeEventListener('DOMContentLoaded', handleLoad);
    //};
  }, []);

  useEffect(() => {
    if (pageLoaded && appstate.iniHash) {
        let inihashx = appstate.iniHash;
        //console.log("Hash keep after page loaded: ", inihashx);
        setAppState((preState) => ({
          ...preState,
          iniHash: '',
        }));
        history.pushState(null, null, inihashx);
        window.dispatchEvent(new HashChangeEvent('hashchange'));
    }
  }, [pageLoaded, appstate.iniHash])

  useEffect(() => {
//  prefetchInit();
    if (!appstate.loaded) {
      window.addEventListener("hashchange", (e) => {
        //console.log("Hash change:", window.location.hash)
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
      //console.log("Debug-1 hash change: ", hashstate.hash, hashstate.handling)
      if (hashstate.hash === '#error') {
        clear_uri();
        setSearch((prev) => ({
          ...prev,
          searched: false,
          isLoading: false,
        }));
      } else if (hashstate.hash === '#complete' && !hashstate.handling) {
        //console.log("Search complete and handle el, hash: ", hashstate.elem, search.isLoading);
        setHashState((prev) => ({
          ...prev,
          handling: true,
          handlend: false,
        }));
      } else if (!hashstate.handling && !search.isLoading) {
        //console.log("Debug-2 hash change: ", hashstate.hash, hashstate.handling)
        if (hashstate.hash.substring(0,8) == '#search=') {
            setHashState((prev) => ({
              ...prev,
              elem: '',
              scrollPos: 0, //scrollTop: true,
            }));

            setSearch((prev) => ({
              ...prev,
              str: hashstate.hash.substring(8).replace(/\_/g, ' '),
              isLoading: true,
              param: { keystr: false,
                       mode: searchmodex('All'),
                       first: pageSize },
            }));
        } else if (hashstate.hash !== '') {
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
                parx = { key: ukey, keystr: false, mode: modex, first: pageSize };
              } else {
                //ukey = spt[1] + '_00a_genus' //if just search taxon, can be removed
                modex= keyx === '#tax' && spt.length === 2? 'genus' : 'species';
                if (modex=='genus') {
                  ukey = '00a_genus_.*00x_' + spt[1];
                  spx = 'All'
                  parx = { key: ukey, keystr: false, mode: modex, first: pageSize };
                } else {
                  spx = spt[1]
                  parx = { keystr: false, mode: modex, first: pageSize };
                }
              }
              //console.log("Hash change: try search ukey: ", ukey, " and taxon: ", spx, " in mode: ", modex);
              //it's not really a 'after' key because it should search keys which >= ukey (not > ukey))
              //parx = {taxon: spt[1], first: search.getsize, after: ukey};
              //scrollTop = true; // new query will be on top
            } else if ((keyx === "#tax" && spt[2]) || keyx === "#fig") {
              if (keyx === '#fig' && spt.length >= 2 && !isNaN(nkey)) { //2021115 for genus
                ukey = padZero(nkey, '00a_genus.*figs.*', 2) + '.*';
                spx = '';
                modex = 'genus';
              } else {
                ukey = 'fig_' +  spt[1] + (spt[2]? '_'+spt[2] : ''); //fig key is not really fig_xxx_xxx in mongo, need re-index
                spx = spt[1] + (spt[2]? ' '+spt[2] : '');
                modex = 'species';
              }
              parx = { key: ukey, keystr: false, mode: modex, first: pageSize };
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
            if (el) {
              if (hashstate.elem.substring(0,5) === "#fig_") {
                fig_offset = 440; //330 is the height of thumb by imagemagick;// carousel + padding + margin > 400 pixel
              }
              to_pos = el.getBoundingClientRect().top + window.pageYOffset - fig_offset;
            } else {
              //console.log("Warning: cannot find elem: ", hashstate.elem);
              if (hashstate.elem.substring(0,5) === "#fig_") { //fig item hide behind Carousel, just scroll to it
                // but we may have #fig_Calanus_sinicus_09 that specify the number, so cannot just use has hashstate.elem.substring(5)
                let tmpspx = hashstate.elem.substring(5);
                let tmpspt = tmpspx.split(/\_/);
                let tmptosp;
                if (tmpspt.length <= 2) {
                  tmptosp = hashstate.elem.substring(5)
                } else {
                  tmptosp = tmpspt[0] + "_" + tmpspt[1]
                }

                el = document.querySelectorAll('[id^="figs_"][id*="' + tmptosp  + '"]');
                if (el) {
                  //console.log("Warning: scroll to alternatives: ", el[0]);
                  to_pos = el[0].getBoundingClientRect().top + window.pageYOffset;
                }
              }
            }
          } else {
            to_pos = 0
          }
          window.scrollTo({
              top: to_pos, // scroll so that the element is at the top of the view
              behavior: 'smooth' // smooth scroll
          })
        }
        if (hashstate.hash === '#complete' && !pageLoaded) {
          useOpts.getState().setOpts({pageLoaded: true}) //to make sure initial page loaded
        }
        setHashState((prev) => ({
            ...prev,
            handlend: true,
            scrollPos: to_pos,
            hash: '',
        }));
        openPopup();
        clear_uri();
      }
    }
  },[appstate.loaded, hashstate.hash, hashstate.handling]); //, prefetchInit
/*const render_userhelper = () => {
    if (appstate.loaded && search.init) {
      return <Helper reload={!iniHelp && search.isLoading} />
    }
    return null;
  };*/
  const searchlabel = lang === 'EN'? 'search': '搜尋'
  const searchplace = (lang === 'EN'? (search.keycheck? 'Search characteristics':'Search taxon'):
                                      (search.keycheck? '搜尋分類特徵':'搜尋屬、種名'));
  const keytreelabel = lang === 'EN'? 'Key-tree': '檢索樹';
  const keytreeinfo = lang === 'EN'? 'List nested identification keys of searched taxon': '列出所搜尋物種巢狀分類檢索';
  const keystrlabel = lang === 'EN'? 'Trait': '特徵';
  const keystrinfo = lang === 'EN'? 'Enable searching characteristics': '搜尋分類特徵';
  /*        { iniHelp &&
                <p style="text-indent:0;z-index:1101;" class="triangle-right top" id="search_tooltips">
                   Search taxon for its identification key, or search<br/>classification traits by enable the right checkbox<br/>搜尋物種分類檢索，輸入屬或種名<br/>或勾選右方欄，搜尋分類特徵
                </p>
            }*/
  //{ render_userhelper() }
  return(
    <Fragment>
      <div id="homediv" onClick={kickInitHelper}>
        <div class="headdiv">
          <div class="float-left-div">
              <p class="flexpspan">
                <label for="spkeysearch" style="color:grey;" />
                <input type="search" id="spkeysearch" name="spkeysearch" placeholder={searchplace}
                   onInput={(e) => { setSearchSpkey(e.target.value) }} />
                <button class="ctrlbutn" id="keysearchbutn" onClick={trigSearch}>{searchlabel}</button>
                <span style="margin-top:10px;margin-left:10px;"> 
                <span>{keytreelabel}&nbsp;&#9755;
                    <label for="keytreelist">
                      <input type="checkbox" id="keytreelist" aria-label={keytreeinfo}
                           checked={keyTree} onClick={toggleKeyTree} />
                    </label>
                </span>
                <span> {keystrlabel}&nbsp;&#9755;
                    <label for="keystrsearch">
                      <input type="checkbox" id="keystrsearch" aria-label={keystrinfo}
                           checked={search.keycheck} onClick={toggleKeystrSearch} />
                    </label>
                </span>
                </span>
              </p>
          </div>
          <MultiSelectSort />
        </div>
        <UserSearch query={querystr.par} search={search} onSearch={setSearch} />
        <Helper enable={appstate.loaded && search.init} reload={!iniHelp && search.isLoading} />
      </div>
      { figx.popup && <Popup ctxt={figx.html} onClose={closePopup} /> }
    </Fragment>
  );
};
export default Home;
