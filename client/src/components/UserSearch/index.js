import { render, Fragment } from 'preact';
import { useState, useEffect, useCallback } from 'preact/hooks';
import { useQuery, useQueryClient } from 'react-query';
//import debounce from 'lodash.debounce';
import Copkey from 'async!../Copkey';
import SvgLoading from 'async!../Compo/SvgLoading';
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       '../../style/style_ctrlcompo');

const UserSearch = (props) => {
  const { urlqry } = props;
  const [state, setState] = useState({
    init: false, //initial searching
    searched: false,
    searching: '',
    isLoading: false, //use react-query
  });
  const [searchSpkey, setSearchSpkey] = useState('');

  const searchx = process.env.NODE_ENV === 'production'? 'species/' : 'specieskey/';
  const queryClient = useQueryClient();
  //const queryCache = queryClient.getQueryCache()

  const [result, setResult] = useState({
    spkey: {key:'', fig:''}
  });
/*//https://dmitripavlutin.com/react-throttle-debounce/
  const debouncedChangeHandler = useCallback(
    debounce(changeHandler, 300)
  , []);
*/
  const trans_htmltxt = (data, key="key") => {
    //if (process.env.NODE_ENV === 'production') {
    // return(data.data[key].reduce((acc, cur) => { return(acc + cur["ctxt"])}, "").replace(/img\//g,'/img/species/'))
    //} //.replace(/^(<\/div>)/g,''); //.replace(/class/g, 'className');
    let ctxt = data.data[key].reduce((acc, cur) => { return(acc + cur["ctxt"] + "\\n") }, "")
                 .replace(/img\//g,'/assets/img/species/').replace(/\.(jpg|jpeg)/g, '.png')
                 .replace(/a class=/g, 'a data-fancybox="gallery" class=');

    let keyx = (ctxt.match(/\<div (class=\"kblk|id=\"genus_|id=\"species_)(.*)\/p\>\<\/div\>(\<br\>)*/g)||[''])[0]
                 .replace(/\\n/g,'');
    let figx = (ctxt.match(/\<div id=\"fig_(.*)\/span\>\<\/div\>(\\n)*/g) || [""])[0]; //split that feed into Fancybox

    return({key: keyx, fig: figx});
  };

  const trigSearch = () => {
    if (searchSpkey && searchSpkey.trim() !== '' && searchSpkey !== state.searching) {
      //history.pushState(null, null, '#search');
      //window.dispatchEvent(new HashChangeEvent('hashchange'));
      return(
        setState((prev) => ({
          ...prev,
          searched: true,
          searching: searchSpkey,
          isLoading: true
        }))
      )
    } //console.log("Repeated search, dismiss it..")
  };

  const waitInitData = useCallback(() => {
  //return(queryClient.getQueryData("init")); //prefetchQuery may later than you want it, then undefined!
  /*let r = queryCache.find("init"); //It's a whole cache object
    if (r) {
       return Promise.resolve(r);
    }*/
    const fetchingInit = async () => {
      await Promise.resolve(queryClient.fetchQuery("init", async () => {
          const res = await fetch(searchx + "init");
          if (!res.ok) {
            throw new Error('Error: Network response was not ok when fetchingInit... ')
          }
          return res.json()
        }, {
             staleTime: Infinity,
             cacheTime: Infinity //prefetchQuery will never return data
        })
      ).then((data) => {
        //console.log("Result just got from init fetch: ", data);
        if (data) {
          let ctxt = trans_htmltxt(data, "init")
          setResult((prev) => ({
            ...prev,
            spkey: ctxt
          }));

          setState((prev) => ({
            ...prev,
            init: true
          }))
        }
      })
    };

    fetchingInit();
  }, []);

  useEffect(() => {
    //if (!state.init) {}
    waitInitData();
  },[waitInitData]);

  const render_search = () => {
    let searchtxt = state.searching;
    //const { isLoading, isError, data, error } =
    const qryx = useQuery(state.searching, async () => {
      const res = await fetch(searchx + state.searching);

      if (!res.ok) {
        throw new Error('Error: Network response was not ok when searching... ')
      }
      return res.json()
    },{ enabled: state.searched,// && state.init},
        keepPreviousData: true/*, //!! Note that "init" query has data.data.init not the same as spquery by name as: data.data.key !!
        placeholderData: () => { //initialData
          return queryClient.getQueryData("init")
            //(searchx.replace("/",""))
            //?.find(d => d.name === "init")
        }*/
    })

    if (qryx.isError) { console.log("Error when searching: ", error.message) }; //not affect previous searching result

    let ctxt;
    let data = qryx.data;
    let NotFound = true;
    //let NotInit = false;
    if (data && state.searched && !qryx.isError && !qryx.isLoading) {
      if (data.data === {} || !data.data.key.length) {
          alert("Warning: Nothing found when searching: ", searchtxt);
      } else {
          NotFound = false;
          ctxt = trans_htmltxt(data, "key");

           setState((prev) => ({
             ...prev,
             searched: false,
             isLoading: false
           }))
      }
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
      ctent = result.spkey
    } else {
      ctent = ctxt
    }

    return(//render(<Fragment />, document.getElementById('resultxdiv'))
        <Copkey ctxt={ctent} />
    )
  };

  return (
    <Fragment>
      <SvgLoading enable = {state.searched} isLoading = {state.isLoading} />
      <div>
          <label for="spkeysearch" style="font-size:0.8em;color:grey">Searching...</label>
          <input type="search" id="spkeysearch" name="spkeysearch" placeholder="Search species key"
                  onInput={(e) => { setSearchSpkey(e.target.value) }} />
          <button class="ctrlbutn" id="keysearchbutn" onClick={trigSearch}>Search</button>
      </div>
      <div id="resultxdiv" style="position:relative;top:0px;margin-top:20px;">
          {state.init && render_search()}
      </div>
    </Fragment>
  )
};
export default UserSearch;
