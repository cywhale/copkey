import { render, Fragment } from 'preact';
import { useState, useEffect } from 'preact/hooks';
/*
import(// webpackMode: "lazy" //
       // webpackPrefetch: true //
       '../../style/style_ctrlcompo');
*/
const UserSearch = (props) => {
  const [state, setState] = useState(false);
  const [searchSpkey, setSearchSpkey] = useState('');
  const [result, setResult] = useState({
    spkey: '',
  });
  const searchx = process.env.NODE_ENV === 'production'? 'species/' : 'specieskey/';

/* old test code from fastify-preact
  const onLayerSearch = () => {
    let term = document.getElementById("searchtxt").value;
    if (term !== '') {
      console.log('Searching: ', term);
      setSearchSpkey(term);
    }
  }
*/
  const set_searchingtext= (elem_search, dom, evt) => {
    let x = elem_search.value;
    if (x && x.trim() !== "" && x !== dom.dataset.searchin) {
      dom.dataset.searchin = x;
    }
  };

  const get_searchingtext = (dom, evt) => {
    //let REGEX_EAST = /[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\uff66-\uff9f\u3131-\uD79D]/;
    //if (dom.dataset.search && dom.dataset.search.trim() !== "") { //|| dom.dataset.search.match(REGEX_EAST))
    setSearchSpkey(dom.dataset.searchin);
    dom.dataset.searchout = dom.dataset.searchin;
  };

  const enable_search_listener = async () => {
    let elem_search = document.getElementById("spkeysearch");
    let search_term = document.getElementById("searchxdiv");
    let butt_search = document.querySelector(".keysearchBut");
    await elem_search.addEventListener("change", set_searchingtext.bind(null, elem_search, search_term), false);
    await elem_search.addEventListener("search",get_searchingtext.bind(null, search_term), false);
    await butt_search.addEventListener("click", get_searchingtext.bind(null, search_term), false);
  }

  const sendSearch = async (searchtxt) => {
    let headers = new Headers();
    headers.append('Content-Type', 'application/json; charset=utf-8');
    headers.append('Accept', 'application/json');
    let searchurl = searchx + searchtxt; // + 'key/' +

    try {
      await fetch(searchurl, {
        method: 'GET',
        //mode: 'same-origin',
        //redirect: 'follow',
        //credentials: 'include',
        //withCredentials: true,
        headers: headers,
        //body: JSON.stringify( {})
      })
      .then(res => res.json())
      .then(json => {
        let data = JSON.stringify(json);
        if (data === null || data === '' || data === '{}' || data === '[]') {
          return(setResult((prev) => ({
              ...prev,
              spkey: 'Spkey not found...'
            }))
          )
        }
        return(
          setResult((prev) => ({
              ...prev,
              spkey: data
          }))
        );
      });
    } catch(err) {
      console.log("Error when search: ", err);
    }
  }

  useEffect(() => {
    if(!state) {
      enable_search_listener();
      setState(true);
    } else {
      if (searchSpkey !== '') {
        sendSearch(searchSpkey);
        history.pushState(null, null, '#search');
        window.dispatchEvent(new HashChangeEvent('hashchange'));
      }
    }
  }, [state, searchSpkey]);

  const render_searchresult = (output) => {
      return(
        render(<Fragment>
                 <div style="position:relative;top:0px;margin:10px;"/>
                   { output.spkey === '' && <p>Not perform searching yet...</p>}
                   { output.spkey !== '' && <p>{output.spkey}</p>}
               </Fragment>,
               document.getElementById('resultxdiv'))
      )
  };

  return (
    <Fragment>
      { render_searchresult(result) }
    </Fragment>
  )
};
export default UserSearch;
