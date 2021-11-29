import { memo } from "preact/compat"; //React
import { render, Fragment } from "preact";
import { useState, useCallback } from "preact/hooks";
import DDiv from '../Compo/DDiv';
import useHelp from '../Helper/useHelp';
import (/* webpackMode: "lazy" */
        /* webpackPrefetch: true */
        "../../style/style_helpcompo.scss");
const { tipdata } = require('./tipinfo.js');

const TipInfo = memo((props) => { //if not use memo, switch lang will cause Tips re-render to tips=0
  return <DDiv {...props} />;
});

const Tips = (props) => {
  const toStep= useHelp(useCallback(state => state.toStep, []));
  const lang= useHelp(useCallback(state => state.lang, []));
  const [tips, setTips] = useState(0);

  const goPrevTip = () => {
    let cnt = (tips === 0? (tipdata.length-1): (tips-1));
    setTips(cnt);
  };

  const goNextTip = () => {
    let cnt = (tips === tipdata.length-1? 0: (tips+1));
    setTips(cnt);
  };

  const toggleTips = () => {
    let state = !toStep;
    useHelp.getState().setStep(state);
  };

  const tipx = (toStep? (lang === 'EN'? 'Hover/touch help box': '移至小幫手方塊上方或輕觸'):
                        (lang === 'EN'? ('☼ Try tips ' + (tips+1).toString()): ('☼ 試試小訣竅 ' + (tips+1).toString())));
  const tipstate = (toStep? (lang === 'EN'? 'Go to tips': '切換小訣竅'):
                            (lang === 'EN'? 'Go to helper': '切換至小幫手'));
  const render_helpctrl = () => {
    return(
      render(
        <div class='helpctrl'>
          <span class='smyellow'>{tipx}</span>
          <button class='helpctrlbutn' id='step_go' onClick={toggleTips} aria-label={tipstate}>&#9757;</button>
          <button class='helpctrlbutn' id='tip_prev' onClick={goPrevTip} aria-label='上個 Previous tip'>&#60;</button>
          <button class='helpctrlbutn' id='tip_next' onClick={goNextTip} aria-label='下個 Next tip'>&#62;</button>
        </div>,
        document.getElementById('helpctrldiv')
      )
    )
  };

  return(
    <Fragment>
      { render_helpctrl() }
      { !toStep &&
        <TipInfo ctxt={tipdata[tips][lang]} class='bluebox' />
      }
    </Fragment>
  )
};
export default Tips;
