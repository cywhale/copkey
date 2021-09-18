//import { Fragment } from "preact";
import React from 'preact/compat';
import { useCallback } from "preact/hooks";
import useHelp from '../Helper/useHelp';
import Copimg from 'async!./Copimg';
import (/* webpackMode: "lazy" */
        /* webpackPrefetch: true */
        "../../style/style_copkey.scss");
import style from "../style/style_init.scss";

class Taxonkey extends React.Component {
/*constructor(props) {
    super(props);
    //this.state = {isInit: true};
  }*/
  render() {
    return (
      <div id="easyPaginate" dangerouslySetInnerHTML={{ __html: this.props.ctxt }} />
    );
  }
}

const Copkey = (props) => {
  const { ctxt } = props;
  const toHelp = useHelp(useCallback(state => state.toHelp, []));

  let helpClass;
  if (toHelp) {
    helpClass=`${style.fade} ${style.gohelp}`;
  } else {
    helpClass=`${style.container}`
  }

  return (
      <div className={helpClass} id="easySearch">
        <Taxonkey ctxt={ctxt.key} />
        <Copimg ftxt={ctxt.fig} />
      </div>
  );
};
export default Copkey;

