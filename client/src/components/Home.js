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
    //scrollPos: document.documentElement.scrollTop??0,
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
    handlend: true,
    scrollPos: 0,
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
    keycheck: false,
    isLoading: false,
    getsize: def_pageSize,
    param: { keystr: false, first: def_pageSize },
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
          param: { keystr: search.keycheck, first: search.getsize },
        }))
      )
    } //console.log("Repeated search, dismiss it..")
  };

  const toggleKeystrSearch = e => {
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

  const openPopup = () => {
    if (hashstate.elem.substring(0,4) === "#fig") {
      let spx = hashstate.elem.substring(hashstate.elem.indexOf('_')+1);
      let spt = spx.split(/\_/);
      let dir = 'species'
      if (spt.length == 2 && !isNaN(parseInt(spt[1]))) {
        let nkey = parseInt(spt[1])
        spx = 'fig' + (nkey < 10? '00' + spt[1] : (nkey < 100? '0' + spt[1] : spt[1]));
        dir = 'genus';
      } else if (spt.length == 2) {
        spx = spx + '_01'; //add a number fo species, but we don't validate species yet
      }
      if (spt.length >= 2) {
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
    //window.addEventListener('scroll', () => enscroller());
      window.addEventListener("hashchange", (e) => {
        //lockScreen();
        //window.scroll(0, appstate.scollPos);
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
              param: { keystr: search.keycheck, first: search.getsize },
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
            // Note 20211117 genus fig has the same span name as key, so when it's found, it will only scroll, not open, need handle it
            openPopup();
          } else {
            let parx, ukey, nkey, spx;
            //let scrollTop = false;
            let spt = hashstate.hash.split(/\_/);
            let keyx= hashstate.hash.substring(0,4);
            if ((keyx === '#tax' && spt.length === 2) || keyx === '#gen' || keyx === "#epi" || keyx === "#key") {
              if (keyx = "#key") {
              //20211115 add to detect genus: key_1 -> 00a_genus_001a
                if (spt.length === 2 && !isNaN(parseInt(spt[1]))) { //for e.g. key_005
                  nkey = parseInt(spt[1]);
                  ukey = '00a_genus_' + (nkey < 10? '00' + spt[1] :
                                        (nkey < 100? '0' + spt[1] : spt[1])) + 'a';
                  spx = '';
                } else {
                  let epi = spt[2]??'';
                  nkey = parseInt(epi.replace(/[a-z]/g,''));
                  let nkeyx= (isNaN(nkey)? '_00a_genus' : (nkey < 10? '_0' + spt[2] : '_' + spt[2]));
                  ukey = spt[1] + nkeyx
                  spx = spt[1]
                }
              } else {
                ukey = spt[1] + '_00a_genus'
                spx = spt[1]
              }
              console.log("Hash change: try search ukey: ", ukey, " and taxon: ", spx);
              //it's not really a 'after' key because it should search keys which >= ukey (not > ukey))
              //parx = {taxon: spt[1], first: search.getsize, after: ukey};
              //scrollTop = true; // new query will be on top
            } else if ((keyx === "#tax" && spt[2]) || keyx === "#fig") {
              if (keyx === '#fig' && spt.length == 2 && !isNaN(parseInt(spt[1]))) { //2021115 for genus
                ukey = '00a_genus.*figs.*' + (nkey < 10? '00' + spt[1] : (nkey < 100? '0' + spt[1] : spt[1])) + '.*'
                spx = ''
              } else {
                ukey = 'fig_' +  spt[1] + (spt[2]? '_'+spt[2] : ''); //fig key is not really fig_xxx_xxx in mongo, need re-index
                spx = spt[1] + (spt[2]? ' '+spt[2] : '');
              }
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
              param: { key: ukey, keystr: false, first: search.getsize },
            }));
          }
        }
      } else if (hashstate.handling) {
        let el; //, hashx;
        let to_el = 0;
        let fig_offset = 0;
        let to_pos= window.pageYOffset;
        if (!hashstate.handlend & hashstate.elem !== '') {
          if (hashstate.scrollPos != 0) {
            el = document.querySelector(hashstate.elem)
            if (hashstate.elem.substring(0,5) === "#fig_") {
              fig_offset = 440; //330 is the height of thumb by imagemagick;// carousel + padding + margin > 400 pixel
              //hashx = hashstate.elem.split(/\_/);
              //el = document.querySelector("#figs_" + hashx[1] + '_' + hashx[2]);
              //console.log("Hash change and prepare scrolling: ", "#figs_" + hashx[1] + '_' + hashx[2], el);
            } //else {
              //el = document.querySelector(hashstate.elem)
            //}
            to_pos = el.getBoundingClientRect().top + window.pageYOffset - fig_offset;
          } else {
            to_pos = 0
          }
          //console.log("Now to scroll(before unlock): ", to_pos);
          window.scrollTo({
              top: to_pos, // scroll so that the element is at the top of the view
              behavior: 'smooth' // smooth scroll
          })
        }
        //unlockScreen();
        setHashState((prev) => ({ // otherwise, this elseif may enter multple times, cause wrong scrolling
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
