import { Fragment } from 'preact';
import { useEffect, useState, useCallback } from 'preact/hooks';
import TabInframe from 'async!./TabInframe';
import useHelp from '../Helper/useHelp';
//import Draggable from 'react-draggable';
import draggable_element from '../Compo/draggable_element';
import style from '../style/style_modal.scss';
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       '../../style/style_modal_tab.scss');

const TabModal = (props) => {
  const [ isOpen, setIsOpen ] = useState(false);
  const [ loaded, setLoaded ] = useState(false);

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
            let width = window.innerWidth;
            let height = window.innerHeight;
            width = width - 100;
            height= height - 180;
            elo.style.maxWidth = "66em";
            elo.style.width = width + "px";
            elo.style.height= height+ "px";
            el.style.width  = width + "px";
            el.style.height = height+ "px";
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
      tabCheckListenx('tab-3', false);
      tabCheckListenx('tab-4', false);
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
/*const startDrag= { x: 40, y: 30 };
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
            <h2 data-toggle="tab">Guides</h2>
              <div class={style.ctrlwrapper}>
                  <section class={style.ctrlsect}>
                    <div class={colClass}>
                      <div id="regionsectdiv">Test 1-1
                      </div>
                      <div id="ctrlsectdiv2">Test 1-2
                      </div>
                    </div>
                  </section>
              </div>
            <label class={tabClass} for="tab-2" tabindex="1" />
            <input id="tab-2" type="radio" name="tabs" aria-hidden="true" />
            <h2 data-toggle="tab">Overview</h2>
              <div class={style.ctrlwrapper}>
                  <section class={style.ctrlsect}>
                    <div class={colClass}>
                      {loaded && <TabInframe ifrid="tab2ifr" enable={loaded} srcurl="https://bio.odb.ntu.edu.tw/copbook"/>}
                    </div>
                  </section>
              </div>
            <label class={tabClass} for="tab-3" tabindex="2" />
            <input id="tab-3" type="radio" name="tabs" aria-hidden="true" />
            <h2 data-toggle="tab">Others</h2>
              <div class={style.ctrlwrapper}>
                  <section class={style.ctrlsect}>
                    <div class={colClass}>
                      <div id="resultxdiv"> Test 3-1</div>
                    </div>
                  </section>
              </div>
            <label class={tabClass} for="tab-4" tabindex="3" />
            <input id="tab-4" type="radio" name="tabs" aria-hidden="true" />
            <h2 data-toggle="tab">About</h2>
              <div class={style.ctrlwrapper}>
                  <section class={style.ctrlsect}>
                    <div class={colClass}>
                      <div> Author page (to be conti.)</div>
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
