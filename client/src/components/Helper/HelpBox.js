import { Fragment } from 'preact';
import { useEffect, useCallback } from "preact/hooks";
import Xarrow, { Xwrapper } from 'react-xarrows'; //useXarrow,
import useHelp from '../Helper/useHelp';
import (/* webpackMode: "lazy" */
        /* webpackPrefetch: true */
        "../../style/style_helpbox.scss");
const { helpdata } = require('./helpinfo.js');

const Xarr2 = (props) => {
  const { xarg1, xarg2 } = props;

  return(
    <Fragment>
        <Xarrow {...xarg1} />
        <Xarrow {...xarg2} />
    </Fragment>
  )
}

const HelpBox = (props) => {
  const { reload } = props;
  const toHelp = useHelp(useCallback(state => state.toHelp, []));
  const toStep = useHelp(useCallback(state => state.toStep, []));
  //const iniHelp= useHelp(useCallback(state => state.iniHelp, []));
  const lang= useHelp(useCallback(state => state.lang, []));

  const arrline2x = (s1,s2,e1,e2,biasx=0.5,biasy=0) => {
    const linex1 = {
      start: s1,
      end: e1,
      color:'rgba(6,57,112,0.7)', //"#063970",
      path: 'grid',
      strokeWidth: 6,
      gridBreak: '52%',
      headShape: 'circle',
      headSize: 5,
      dashness: false //{ animation: 1 }
    };
    const linex2 = {
      start: s2,
      end: e2,
      color:'rgba(37,150,190,0.7)', //"#2596be",
      path: 'grid',
      strokeWidth: 2,
      headShape: 'circle',
      headSize: 3,
      dashness: false,
      _cpx2Offset: biasx,
      _cpy2Offset: biasy,
      _cpx1Offset: biasx,
      _cpy1Offset: biasy
    };
    return({xarg1: linex1, xarg2: linex2});
  };

  const render_info = (props) => {
    const { id, info } = props; //use <p> to escape rules #helpContainer div
    return(                     //try iOS seems not accept using touch as hover //onClick={e=>e.preventDefault()}
      <p class="helpbox">
          <p id={id} class="column-right">{info}</p>
      </p>
    )
  };

  const find_closest = (el, attr='span') => (el? (el.closest(attr)? (el.closest(attr).firstChild??null) : null): null);
  const find_elemx = (id,self=true,nth='first') => {
    let el = document.querySelector(id);
    if (el) {
      if (self && nth === 'first') return el
      if (!self && nth ==='first') return find_closest(el)

      let els = document.querySelectorAll(id);
    //if (els) {
      if (els.length <= 2) {
        if (self) return els[1]
        return find_closest(els[1]);
      }
      let nx = parseInt(nth);
      if (!isNaN(nx)) {
        if (els.length >= nx) {
          if (self) return els[nx-1]
          return find_closest(els[nx-1])
        } else {
          if (self) return els[els.length-1]
          return find_closest(els[els.length-1])
        }
      } else if (nth=='last') {
        if (self) return els[els.length-1]
        return find_closest(els[els.length-1])
      }
      let mid = parseInt(els.length/3);
      if (self) return els[mid]
      return find_closest(els[mid])
    } else {
      return null
    }
  };

  const render_xarrows = (props) => {
    const hboxs = helpdata.map((hx, idx) => {
      if (!reload) {
        let el;
        let self= hx['to'].match(/href/g)? false: true;
        let nth = (idx < 3? 'first': (idx === 5? 'mid' : (idx < 6? (idx-1).toString(): 'first')));
/*      if (hx['to'].match(/href/g)) {
          el = document.querySelector(hx['to']).closest('span').firstChild;
        } else {
          el = document.querySelector(hx['to']);
        }*/
        el = find_elemx(hx['to'], self, nth);
        let hxid_e0 = '';
        if (el) {
          hxid_e0 = el.id; //iniHelp? "key_Acartia_35a": document.querySelector('[id^="key_"]').id;
        } else {
          console.log("Warning: check not found and dom with key id", hx['to'], idx);
        }
        let hxid_start = "help_" + (idx >= 10? idx: ('0' + idx));
        let helpx0 = {id: hxid_start, info: hx[lang]};
        let help_enable = toStep && hxid_e0 !== '';
        const linex = arrline2x(hxid_start, hxid_start, hxid_e0, hxid_e0, 0.5, 0); //repeat lines to make it more fancy?

        return(
          <div class="helpContainer" id="helpContainer">
            { help_enable &&
              <Xwrapper>
                { render_info(helpx0) }
                <Xarr2 {...linex} />
              </Xwrapper>
            }
          </div>
        )
      } else {
        if (toHelp) {
          useHelp.getState().closeHelp();
        }
        return null;
      }
    });

    return(
      //render(
        <Fragment>{hboxs}</Fragment>//,
      //document.getElementById('rightarea')
    ) //)
  };

  useEffect(() => {
    if (toStep) {
      //setIsOpen(true)
      let els = document.querySelectorAll("#helpContainer div")
      if (els.length>0) {
        for(let i=0; i < els.length; i++) {
          if (!els[i].classList.contains('myarrow')) {els[i].classList.add("myarrow");}
        /*if (i === 0) {
            els[i].style.display= 'block';
          } else {
            els[i].style.display= 'none'; //first, hide all, except the first help box
          }
          els[i].style.zIndex = 1005;*/
        }
      }
    }
  }, [toStep]);

  return(
    <Fragment>{ render_xarrows() }</Fragment>
  )
};
export default HelpBox;
