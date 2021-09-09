// import React from "react";
import React from "preact/compat";
import (/* webpackMode: "lazy" */
        /* webpackPrefetch: true */
        "../../style/style_copkey.scss");

class Copkey extends React.Component {
/*constructor() {
    super();
  }
  componentDidMount() {
    let dom = document.getElementById("resultxdiv");
    //...
  }
*/
  render() {
    let ctxt = this.props.ctxt;

    return (
      <div className="container" id="easySearch">
        <div id="easyPaginate" dangerouslySetInnerHTML={{ __html: ctxt }} />
      </div>
    );
  }
}
export default Copkey;

