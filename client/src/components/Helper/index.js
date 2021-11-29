import { render, Fragment } from 'preact';
import { useState, useEffect, useCallback} from "preact/hooks";
import Tips from 'async!./Tips';
import HelpBox from 'async!./HelpBox';
import useHelp from '../Helper/useHelp';
import style from '../style/style_helper.scss';

const Helper = (props) => {
  const { enable, reload } = props;
  const toHelp = useHelp(useCallback(state => state.toHelp, []));
  const iniHelp= useHelp(useCallback(state => state.iniHelp, []));
  const toStep= useHelp(useCallback(state => state.toStep, []));
  const lang= useHelp(useCallback(state => state.lang, []));

  const toggleBtnx = () => {
    if (toHelp) {
      useHelp.getState().closeHelp();
    } else {
      useHelp.getState().enableHelp();
    }
  };

  const render_helper = (props) => {
    const { helpclass } = props;
    return(
      render(
        <div class={helpClass}>
          <div id='helpctrldiv' />
          { <Tips />}
          { toStep && enable && <HelpBox reload={reload} />}
        </div>,
        document.getElementById('rightarea')
    ) )
  };

  useEffect(() => {
    if (toHelp) {
      let el = document.getElementById("rightarea")
      el.style.zIndex = 2;
    } else {
      let el = document.getElementById("rightarea")
      el.style.zIndex = -1;
    }
  }, [toHelp]);

  let helpClass;
  if (!toHelp) {
    helpClass=`${style.helper} ${style.notshown}`;
  } else {
    helpClass=`${style.helper}`
  }
  return(
    <Fragment>
      <div id="helpToggle" class={style.helpToggle}>
         <a class={style.helpButn} id="helpButn" onClick={toggleBtnx}><i></i></a>
         {iniHelp && <p style="text-indent:0;" class="triangle-right top" id="help_tooltips">Open Helper<br/>使用小幫手</p>}
      </div>
      { render_helper({helpClass: helpClass}) }
    </Fragment>
  )
};
export default Helper;
