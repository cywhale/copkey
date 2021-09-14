// import React from "react";
import React from "preact/compat";

class DDiv extends React.Component {
  render() {
    let { ctxt, ...opts } = this.props;
    return <div {...opts} dangerouslySetInnerHTML={{ __html: ctxt }} />;
  }
}
export default DDiv;

