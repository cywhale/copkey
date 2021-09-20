import { Fragment } from 'preact';
import { useState, useEffect, useRef } from 'preact/hooks';
import DDiv from 'async!../Compo/DDiv';
import draggable_element from './draggable_element';
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       '../../style/style_popup.scss');

const Popup = (props) => {
    const { ctxt, onClose } = props;
    const [state, setState] = useState(false);

    const ref = useRef(null);

    useEffect(() => {
      if (ref.current) {
        let drag_opts = { dom: ".popup", dragArea: '.popup' };
        draggable_element(drag_opts);
      }
    }, [ref.current])

    return (
      <Fragment>
        <div class="popup" ref={ref}>
          <div class="idivHeader">
            <a class="iclose" onClick={onClose}>&times;</a>
          </div>
          <DDiv ctxt={ctxt} class="popup_inner" />
        </div>
      </Fragment>
    );
};
export default Popup;
