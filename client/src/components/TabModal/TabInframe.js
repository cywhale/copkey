import React from "preact/compat";
/*import(// webpackMode: "lazy"
       // webpackPrefetch: true
       "../../style/style_overview.scss");*/

class TabInframe extends React.Component {
  render() {
    const idx= this.props.ifrid;
    const enable = this.props.enable
    let urlx = enable && this.props.srcurl !== "" ? this.props.srcurl: " ";
    const ctent =
      "<iframe id='" +
      idx +
      "' loading='lazy' width='100%' height='100%' src=" +
      urlx +
      " sandbox='allow-modals allow-forms allow-popups allow-scripts allow-same-origin'></iframe>";

    return (
      <div style="overflow-y:auto;-webkit-overflow-scrolling:touch;max-height:100%;">
        <div dangerouslySetInnerHTML={{ __html: ctent }} />
      </div>
    );
  }
}
export default TabInframe;

