import React from 'preact/compat';
import { useState, useEffect, useCallback } from 'preact/hooks';
import useHelp from '../Helper/useHelp';
import Copimg from './Copimg'; //cannot be async cause react cannot call "this.setState" on an unmounted component
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
  const { ctxt, load} = props;
  const [childKey, setChildKey] = useState(0);
  const toHelp = useHelp(useCallback(state => state.toHelp, []));
  const iniHelp= useHelp(useCallback(state => state.iniHelp, []));

  useEffect(() => { //Carousel cannot rebuild with new img if not destroy old, ref:
      //https://stackoverflow.com/questions/52260258/reactjs-destroy-old-component-instance-and-create-new
      if (!load) {setChildKey(prev => prev + 1)};
  }, [load]);

  let helpClass;
  if (iniHelp) {
    helpClass=`${style.fade}`;
  } else if (toHelp) {
    helpClass=`${style.gohelp}`;
  } else {
    helpClass=`${style.container}`
  }

  return (
      <div class={helpClass} id='easySearch'>
        <Taxonkey ctxt={ctxt.key} />
        { props.children }
        <Copimg ftxt={ctxt.fig} key={childKey} />
      </div>
  );
};
export default Copkey;

