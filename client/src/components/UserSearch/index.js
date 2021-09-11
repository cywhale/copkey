import { render, Fragment } from 'preact';
import { useState, useEffect } from 'preact/hooks';
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
    init: true, //initial searching
    searched: false,
    searching: '',
    isLoading: false, //use react-query
  });
  const [searchSpkey, setSearchSpkey] = useState('');

  const searchx = process.env.NODE_ENV === 'production'? 'species/' : 'specieskey/';
  const queryClient = useQueryClient();

  const [result, setResult] = useState({
    spkey: ''
  });
/*//https://dmitripavlutin.com/react-throttle-debounce/
  const debouncedChangeHandler = useCallback(
    debounce(changeHandler, 300)
  , []);
*/
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
/*
  const waitData = useCallback(() => {
    const fetchingData = async () => {
      await render_search();
      console.log("Now await dataLoader and isLoading is: ", state.isLoading);
    };
    setState((prev) => ({
        ...prev,
        isLoading: true
    }))
    fetchingData();
  }, []);
*/
  useEffect(() => {
    if (state.init) {
      //waitData(state.searching);
      const data = queryClient.getQueryData("init");
      console.log("Data in initial stage: ", data); //Note that {data: {Query_Name_in_graphql: [{ctxt: }, ...]}}
      //so that "init" query has data.data.init not the same as spquery by name as: data.data.key !!
      let ctxt = data.data.init.reduce((acc, cur) => { return(acc + cur["ctxt"])}, "");
      console.log("Ctxt in initial stage: ", ctxt);
      setResult((prev) => ({
        ...prev,
        spkey: ctxt
      }));

      setState((prev) => ({
        ...prev,
        init: false
      }))
    }
  },[state.init]); //, waitData

  const render_search = () => {
    let searchtxt = state.searching;
    //const { isLoading, isError, data, error } =
    const qryx = useQuery(state.searching, async () => {
      const res = await fetch(searchx + state.searching);

      if (!res.ok) {
        throw new Error('Error: Network response was not ok when searching... ')
      }
      return res.json()
    },{ enabled: state.searched,//},
        keepPreviousData: true /*, !! Note that "init" query has data.data.init not the same as spquery by name as: data.data.key !!
        placeholderData: () => { //initialData
          return queryClient.getQueryData("init")
            //(searchx.replace("/",""))
            //?.find(d => d.name === "init")
        }*/
    })

    if (qryx.isError) { console.log(error.message) }; //not affect previous searching result

    let ctxt;
    let data = qryx.data;
    let NotFound = true;
    //let NotInit = false;
    if (state.searched && !qryx.isError && !qryx.isLoading) {
      if (data === null || data.data === {} || !data.data.key.length) {
        alert("Warning: Nothing found when searching: ", searchtxt);
      } else {
        NotFound = false;
        ctxt = data.data.key.reduce((acc, cur) => { return(acc + cur["ctxt"])}, ""); //.replace(/^(<\/div>)/g,''); //.replace(/class/g, 'className');
        setResult((prev) => ({
          ...prev,
          spkey: ctxt
        }));
      }
      setState((prev) => ({
        ...prev,
        searched: false,
        isLoading: false
      }))
    }

    let ctent;
    if (NotFound) { // Fragment(result.spkey)
      ctent = result.spkey
    } else {
      ctent = ctxt
    }

    return(//render(<Fragment>
        <Copkey ctxt={ctent} />
        //</Fragment>//, document.getElementById('resultxdiv'))
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
          {render_search()}
      </div>
    </Fragment>
  )
};
export default UserSearch;
