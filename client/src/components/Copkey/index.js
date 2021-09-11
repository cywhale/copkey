// import React from "react";
import React from "preact/compat";
import (/* webpackMode: "lazy" */
        /* webpackPrefetch: true */
        "../../style/style_copkey.scss");

class Copkey extends React.Component {
/*constructor(props) {
    super(props);
  }
//https://stackoverflow.com/questions/51417291/this-props-history-push-not-re-rendering-react-component
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

