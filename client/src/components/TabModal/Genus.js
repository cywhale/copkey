import React from "preact/compat";
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       "../../style/style_overview.scss");

//<div className="oviewifr_outer" id="oviewifrdiv">

class Overview extends React.Component {
  render() {
    let urlx = this.props.srcurl === "" ? " " : this.props.srcurl;
    const ctent =
      "<iframe id='oviewifr' width='100%' height='100%' scrolling='auto' src=" +
      urlx +
      " sandbox='allow-modals allow-forms allow-popups allow-scripts allow-same-origin'></iframe>";

    return (
        <div id="oviewifrdiv" className="oviewifr_inner" dangerouslySetInnerHTML={{ __html: ctent }} />
    );
  }
}
export default Overview;

