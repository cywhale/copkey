import { render, Fragment } from 'preact';
import { useState, useEffect, useCallback } from 'preact/hooks';
import { useQuery } from 'react-query';
//import debounce from 'lodash.debounce';
import Copkey from 'async!../Copkey';
import SvgLoading from 'async!../Compo/SvgLoading';
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       '../../style/style_ctrlcompo');

const UserSearch = (props) => {
  const [state, setState] = useState({
    searched: false,
    searching: '',
    isLoading: false, //use react-query
  });
  const [searchSpkey, setSearchSpkey] = useState('');
  const [result, setResult] = useState({
    spkey: '',
  });

  const searchx = process.env.NODE_ENV === 'production'? 'species/' : 'specieskey/';

/*//https://dmitripavlutin.com/react-throttle-debounce/
  const debouncedChangeHandler = useCallback(
    debounce(changeHandler, 300)
  , []);
*/

  const sendSearch = () => {
    if (searchSpkey && searchSpkey.trim() !== '' && searchSpkey !== state.searching) {
      history.pushState(null, null, '#search');
      window.dispatchEvent(new HashChangeEvent('hashchange'));

      return(
        setState((prev) => ({
          ...prev,
          searched: true,
          searching: searchSpkey,
          isLoading: true
        }))
      )
    }
    //console.log("Repeated search, dismiss it..")
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

  useEffect(() => {
    if (state.searched) {
      waitData(state.searching);
      history.pushState(null, null, '#search');
      window.dispatchEvent(new HashChangeEvent('hashchange'));
    }
  },[state.searched, waitData]);
*/
  const render_search = () => {
    let searchtxt = state.searching;
    const { isLoading, isError, data, error } = useQuery([searchx, searchtxt], async () => {
      const res = await fetch(searchx + searchtxt);

      if (!res.ok) {
        throw new Error('Error: Network response was not ok when searching... ')
      }
      return res.json()
    },{enabled: state.searched})

    if (isError) { console.log(error.message) }; //not affect previous searching result

    let ctxt = '';
    let NotFound = true;
    if (state.searched && !isError && !isLoading) {
      if (data === null || data.data === {} || !data.data.key.length) {
        alert("Warning: Nothing found when searching: ", searchtxt);
      } else {
        NotFound = false;
        ctxt = data.data.key.reduce((acc, cur) => { return(acc + cur["ctxt"])}, "").replace(/^(<\/div>)/g,''); //.replace(/class/g, 'className');
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
    //        {NotFound && <p>{result.spkey}</p>}
    //        {!NotFound && <p>{ctxt}</p>}
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
          <button class="ctrlbutn" id="keysearchbutn" onClick={sendSearch}>Search</button>
      </div>
      <div id="resultxdiv" style="position:relative;top:0px;margin-top:20px;">
          {render_search()}
      </div>
    </Fragment>
  )
};
export default UserSearch;
