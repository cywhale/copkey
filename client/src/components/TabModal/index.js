import { Fragment } from 'preact';
import { useEffect, useState, useCallback } from 'preact/hooks';
import TabInframe from 'async!./TabInframe';
import AboutUs from 'async!./AboutUs';
import Guides from 'async!./Guides';
import useHelp from '../Helper/useHelp';
import useOpts from './useOpts';
//import Draggable from 'react-draggable';
import draggable_element from '../Compo/draggable_element';
import style from '../style/style_modal.scss';
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       '../../style/style_modal_tab.scss');
const { optsdata } = require('./optsinfo.js');

const TabModal = (props) => {
  const [ isOpen, setIsOpen ] = useState(true);
  const [ loaded, setLoaded ] = useState(false);

  const lang= useHelp(useCallback(state => state.lang, []));
  const iniHelp= useHelp(useCallback(state => state.iniHelp, []));
  const toggleBtnx = () => {
    if (isOpen && iniHelp) {
      useHelp.getState().closeHelp();
    }
    setIsOpen(!isOpen)
  }
  const closeBtnx = () => {
    setIsOpen(false);
    if (iniHelp) {
      useHelp.getState().closeHelp();
    }
  };

  const fuzzy= useOpts(useCallback(state => state.fuzzy, []));
  const sameTaxon= useOpts(useCallback(state => state.sameTaxon, []));
  const forceGenus= useOpts(useCallback(state => state.forceGenus, []));
  const forceSpecies= useOpts(useCallback(state => state.forceSpecies, []));
  const pageSize= useOpts(useCallback(state => state.pageSize, []));
  const toggleFuzzy = e => {
    let checked = !fuzzy;
    useOpts.getState().setOpts({fuzzy: checked});
  };
  const toggleSameTaxon = e => {
    let checked = !sameTaxon;
    useOpts.getState().setOpts({sameTaxon: checked});
  };
  const toggleForceGenus = e => {
    let checked = !forceGenus;
    useOpts.getState().setOpts({forceGenus: checked});
  };
  const toggleForceSpecies = e => {
    let checked = !forceSpecies;
    useOpts.getState().setOpts({forceSpecies: checked});
  };
  const setPageSize = e => {
    let val = parseInt(e.target.value);
    if (isNaN(val) || (val && val<= 0)) {
      alert("Error: Not valid input, should be number > 0\n錯誤：應為大於零之整數")
    } else {
      useOpts.getState().setOpts({pageSize: val});
    }
  }
/*const loadIframex = () => {
    let vidDefer = document.getElementsByTagName('iframe');
    for (let i=0; i<vidDefer.length; i++) {
       if(vidDefer[i].getAttribute('src') === '' && vidDefer[i].getAttribute('data-src')) {
         vidDefer[i].setAttribute('src',vidDefer[i].getAttribute('data-src'));
    } }
  }*/
  const tabCheckListenx = (tabid, adjust=true) => {
    let elchk = document.getElementById(tabid);
    elchk.addEventListener('change', function() {
      let elo= document.getElementById("ctrl");
      if (adjust) {
        let el = document.getElementById(tabid.replace(/\-/g,'') + 'ifr');
        let elo= document.getElementById("ctrl");
        if (el && elo) {
          if(this.checked) {
            let width = parseInt(window.innerWidth * 0.9);
            let height = window.innerHeight;
            width = width >= 960 ? 960 : width;
            //height= height - 20;
            elo.style.maxWidth = "66em";
            elo.style.width = width + "px";
            el.style.width  = width + "px";
            el.style.height = height+ "px";
            elo.style.height= "auto"; //height+ "px";

          } else {
            el.style.width  = "100%";
            el.style.height = "100%";
          }
        }
      } else if (elo) {
        if (this.checked) {
          elo.style.width = "auto";
          elo.style.height= "auto";
          elo.style.maxWidth = "34.5em";
        }
      }
    });
  }

  useEffect(() => {
    if (!loaded) {
      const drag_opts = { dom: "#ctrl", dragArea: '#ctrlheader' };
      draggable_element(drag_opts);
      document.getElementById('tab-1').checked = true; // give a default
      tabCheckListenx('tab-1', false);
      tabCheckListenx('tab-2');
      tabCheckListenx('tab-3');
    //tabCheckListenx('tab-4', false);
/*    document.addEventListener("DOMContentLoaded", (e) => {
         loadIframex();
      });*/
      setLoaded(true);
    }
  },[loaded]);

  let modalClass;
  if (!isOpen) {
    modalClass=`${style.modalOverlay} ${style.notshown}`;
  } else {
    modalClass=`${style.modalOverlay}`
  }
  const colClass = `${style.ctrlcolumn}` //.not-draggable
  const tabClass = 'tablab'; //.not-draggable
  const xlang = lang === 'EN'? 'TW': 'EN';
/*const label1 = lang === 'EN'? 'Guides': '簡介'
  const label2 = lang === 'EN'? 'Overview': '綜述'
  const label3 = lang === 'EN'? 'About': '關於'
  const label4 = lang === 'EN'? 'Options': '選項'
  const startDrag= { x: 40, y: 30 };
  <Draggable cancel=".not-draggable" defaultPosition={startDrag}>
*/
  return (
    <Fragment>
      <div id="toolToggle" class = {style.menuToggle}>
          <div class = {style.menuBtn_in_span}>
            <button id="toolButn" class = {style.menuButn} type="button" onClick={()=>{toggleBtnx()}}><i></i>
            </button>
          </div>
      </div>

      <div id="ctrl" class={modalClass}>
        <div class={style.modalHeader} id="ctrlheader">
          <a id="toolClose" class={style.close} onClick={()=>{closeBtnx()}}>&times;</a>
        </div>
        <div class={style.modal}>
          <div class="nav-tabs">
            <label class={tabClass} for="tab-1" tabindex="0" />
            <input id="tab-1" type="radio" name="tabs" aria-hidden="true" />
            <h2 data-toggle="tab">{optsdata["label1"][lang]}</h2>
              <div class={style.ctrlwrapper}>
                  <section class={style.ctrlsect}>
                    <div class={colClass}>
                      <Guides />
                    </div>
                  </section>
              </div>
            <label class={tabClass} for="tab-2" tabindex="1" />
            <input id="tab-2" type="radio" name="tabs" aria-hidden="true" />
            <h2 data-toggle="tab">{optsdata["label2"][lang]}</h2>
              <div class={style.ctrlwrapper}>
                  <section class={style.ctrlsect}>
                    <div class={colClass}>
                      {loaded && <TabInframe ifrid="tab2ifr" enable={loaded} srcurl="https://bio.odb.ntu.edu.tw/pub/copkey"/>}
                    </div>
                  </section>
              </div>
            <label class={tabClass} for="tab-3" tabindex="2" />
            <input id="tab-3" type="radio" name="tabs" aria-hidden="true" />
            <h2 data-toggle="tab">{optsdata["label3"][lang]}</h2>
              <div class={style.ctrlwrapper}>
                  <section class={style.ctrlsect}>
                    <div class={colClass}>
                      <AboutUs />
                    </div>
                  </section>
              </div>
            <label class={tabClass} for="tab-4" tabindex="3" />
            <input id="tab-4" type="radio" name="tabs" aria-hidden="true" />
            <h2 data-toggle="tab">{optsdata["label4"][lang]}</h2>
              <div class={style.ctrlwrapper}>
                  <section class={style.ctrlsect}>
                    <div class={colClass}>
                      <div class='guideinfo'>
                      <p><label for="fuzzysearch" style="margin-top:10px;">
                        <input type="checkbox" id="fuzzysearch" aria-label={optsdata["fuzzysearch"][xlang]}
                          checked={fuzzy} onClick={toggleFuzzy} />{optsdata["fuzzysearch"][lang]}
                      </label></p>
                      <p><label for="sametaxon" style="margin-top:10px;">
                        <input type="checkbox" id="sametaxon" aria-label={optsdata["sametaxon"][xlang]}
                          checked={sameTaxon} onClick={toggleSameTaxon} />{optsdata["sametaxon"][lang]}
                      </label></p>
                      <p><label for="forcegenus" style="margin-top:10px;">
                        <input type="checkbox" id="forcegenus" aria-label={optsdata["forcegenus"][xlang]}
                          checked={forceGenus} onClick={toggleForceGenus} />{optsdata["forcegenus"][lang]}
                      </label></p>
                      <p><label for="forcespecies" style="margin-top:10px;">
                        <input type="checkbox" id="forcespecies" aria-label={optsdata["forcespecies"][xlang]}
                          checked={forceSpecies} onClick={toggleForceSpecies} />{optsdata["forcespecies"][lang]}
                      </label></p>
                      <p><label for="pagesize" style="margin-top:10px;">{optsdata["pagesize"][lang]}
                        <input type="text" id="pagesize" aria-label={optsdata["pagesize"][xlang]}
                          value={pageSize} onInput={setPageSize} />
                      </label></p>
                      </div>
                    </div>
                  </section>
              </div>
          </div>
        </div>
      </div>
    </Fragment>
  );
};
export default TabModal;
