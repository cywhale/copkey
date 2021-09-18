import { useEffect, useState } from 'preact/hooks';
import { Fragment } from 'preact';
//import { useQueryClient } from 'react-query'
import useHelp from './Helper/useHelp';
import MultiSelectSort from 'async!./MultiSelectSort';
import UserSearch from 'async!./UserSearch';
import SvgLoading from 'async!./Compo/SvgLoading';
import Helper from 'async!./Helper';
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       '../style/style_ctrlcompo');

const Home = () => {
  const searchx = process.env.NODE_ENV === 'production'? 'species/' : 'specieskey/';
  const [appstate, setAppState] = useState({
    loaded: false,
  });

  //const closeHelp = useHelp(state => state.closeHelp)
  const [hashstate, setHashState] = useState({
    handling: false,
    hash: '',
  });
  const [querystr, setQueryStr] = useState({
    //handling: false,
    par: {},
  });

  const [search, setSearch] = useState({
    str: '',
    searched: false,
    isLoading: false,
  });
  const [searchSpkey, setSearchSpkey] = useState('');

  const trigSearch = () => {
    if (searchSpkey && searchSpkey.trim() !== '' && searchSpkey !== search.str) {
      //history.pushState(null, null, '#search');
      //window.dispatchEvent(new HashChangeEvent('hashchange'));
      return(
        setSearch((prev) => ({
          ...prev,
          str: searchSpkey,
          searched: true,
          isLoading: true
        }))
      )
    } //console.log("Repeated search, dismiss it..")
  };

  const kickInitHelper = () => {
    if (useHelp.getState().iniHelp) {
      //history.pushState(null, null, '#help');
      //window.dispatchEvent(new HashChangeEvent('hashchange'));
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
        let parx = window.location.search.replace('?', '').split('&').reduce((r,e) => (r[e.split('=')[0]] = decodeURIComponent(e.split('=')[1]), r), {});
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
    }
    if (hashstate.hash !== '' && !hashstate.handling) {
      if (hashstate.hash === "#search" || hashstate.hash === "#details" || hashstate.hash === "#close") {
        setHashState((prev) => ({
          ...prev,
          handling: true,
        }));
      } //else {
        //clear_uri();
      //}
    } else if (hashstate.handling) {
      console.log("simu el.click for hashstate handling");
    /*let el;
      if (hashstate.hash === "#search") {
        el = document.getElementById("tab-4");
      } else if (hashstate.hash === "#details") {
        el = document.getElementById("tab-3");
      }
      if (el) {
        if (typeof el.click == 'function') {
          el.click()
        } else if(typeof el.onclick == 'function') {
          el.onclick()
        }
      } else if (hashstate.hash === "#close") {
        setIsOpen(false)
      }*/
      clear_uri();
    }
  },[appstate.loaded, hashstate]); //, prefetchInit


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
          </div>
          <MultiSelectSort />
        </div>
        <UserSearch search={search} onSearch={setSearch} />
        <Helper />
      </div>
    </Fragment>
  );
};
export default Home;
