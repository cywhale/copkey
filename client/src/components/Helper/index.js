import { render, Fragment } from 'preact';
import { useEffect, useCallback } from "preact/hooks";
import Xarrow, { Xwrapper } from 'react-xarrows'; //useXarrow,
import useHelp from '../Helper/useHelp';
import style from '../style/style_helper.scss';
import (/* webpackMode: "lazy" */
        /* webpackPrefetch: true */
        "../../style/style_helpbox.scss");

const Xarr2 = (props) => {
  const { xarg1, xarg2 } = props;

  return(
    <Fragment>
        <Xarrow {...xarg1} />
        <Xarrow {...xarg2} />
    </Fragment>
  )
}

const Helper = (props) => {
  //const [ isOpen, setIsOpen ] = useState(false);
  const toHelp = useHelp(useCallback(state => state.toHelp, []));
  const iniHelp= useHelp(useCallback(state => state.iniHelp, []));

  const arrline2x = (s1,s2,e1,e2,biasx=0.5,biasy=0) => {
    const linex1 = {
      start: s1,
      end: e1,
      color: 'rgba(6,57,112,0.7)', //"#063970",
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
      color: 'rgba(37,150,190,0.7)', //"#2596be",
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

  const toggleBtnx = () => {
    if (toHelp) {
      //setIsOpen(true);
      useHelp.getState().closeHelp();
    } else {
      useHelp.getState().enableHelp();
    }
  };

  const render_keyhelper = (props) => {
    const { id, lang } = props;
    let langx = lang || "en";
    const info = {tw: "",
                  en: "Identification key with (previous key in parentheses)"}
    return(
      <div class="helpbox">
          <div id={id} class="column-right">{info[langx]}</div>
      </div>
    )
  };

  const render_xarrows = (props) => {
    const { helpclass } = props;

    let langsel = "en";
    let el = document.querySelector('[id^="key_"]');
    let hxid_e0 = '';
    if (el) {
      hxid_e0 = el.id; //iniHelp? "key_Acartia_35a": document.querySelector('[id^="key_"]').id;
    } else {
      console.log("Warning: check not found and dom with key id");
    }
    let hxid_start = ["keyblk_help"];
    let helpx0 = {id: hxid_start[0], lang: langsel};
    let help_enable = toHelp && hxid_e0 !== '';
    const linex = arrline2x("keyblk_help", "keyblk_help", hxid_e0, hxid_e0, 0.5, 0); //repead lines to make it more fancy?

    return(
      render(
        <div class={helpclass} id="helpContainer">
          { help_enable &&
            <Xwrapper>
              { render_keyhelper(helpx0) }
              <Xarr2 {...linex} />
            </Xwrapper>
          }
        </div>,
        document.getElementById('rightarea')
    ))
  };

  useEffect(() => {
    if (toHelp) {
      //setIsOpen(true)
      let el = document.getElementById("rightarea")
      el.style.zIndex = 2;
      let els = document.querySelectorAll("#helpContainer div")
      if (els.length>0) {
        for(let i=0; i < els.length; i++) {
          els[i].style.zIndex = 1005;
        }
      }
    } else {
      let el = document.getElementById("rightarea")
      el.style.zIndex = -1;
    }
  }, [toHelp]);

  let helpClass;
  if (!toHelp) {
    helpClass=`${style.helpContainer} ${style.notshown}`;
  } else {
    helpClass=`${style.helpContainer}`
  }

  let langsel = "en";
  let helpxid = ["keyblk_help"];
  let helpx0 = {id: helpxid[0], lang: langsel};
  return(
    <Fragment>
      <div id="helpToggle" class={style.helpToggle}>
         <a class={style.helpButn} id="helpButn" onClick={toggleBtnx}><i></i></a>
         {iniHelp && <p style="text-indent:0;" class="triangle-right top" id="help_tooltips">Open Helper<br/>使用小幫手</p>}
      </div>
      { render_xarrows({helpclass: helpClass}) }
    </Fragment>
  )
};
export default Helper;
