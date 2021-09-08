import { useEffect, useState } from 'preact/hooks';
//import { Fragment } from 'preact';
import MultiSelectSort from 'async!./MultiSelectSort';
import UserSearch from 'async!./UserSearch';


const Home = () => {

  const [appstate, setAppState] = useState({
    loaded: false,
  });

  const [hashstate, setHashState] = useState({
    handling: false,
    hash: '',
  });

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
    if (!appstate.loaded) {
      window.addEventListener("hashchange", function(e) {
        setHashState((prev) => ({
          ...prev,
          hash: window.location.hash,
        }))
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
      } else {
        clear_uri();
      }
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
  },[appstate.loaded, hashstate]);


  return(
	<div>
	     <h1>Copkey App</h1>
             <p> Testing... </p>
             <div>
                <label for="spkeysearch" style="font-size:0.8em;color:grey">Searching...</label>
                <div id="searchxdiv" data-searchin="" data-searchout="" />
                <input type="search" id="spkeysearch" name="spkeysearch" aria-label="Search species key" />
                <button class="keysearchBut">Search</button>
                <div id="resultxdiv" />
             </div><br />
             <UserSearch /><br />
             <div style="max-width:50%;"><MultiSelectSort /></div>
	</div>
  );
};
export default Home;
