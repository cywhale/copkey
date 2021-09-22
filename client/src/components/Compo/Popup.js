import { Fragment } from 'preact';
//import { useState, useEffect, useRef } from 'preact/hooks';
import Draggable from 'react-draggable';
//import draggable_element from './draggable_element';
import DDiv from 'async!../Compo/DDiv';
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       '../../style/style_popup.scss');

const Popup = (props) => {
    const { ctxt, onClose } = props;
/*  const [state, setState] = useState(false);
    const ref = useRef(null);
    useEffect(() => {
      if (ref.current) {
        let drag_opts = { dom: ".popup", dragArea: '.popup'};
        draggable_element(drag_opts);
      }
    }, [ref.current])
*/ //<div class="popup" ref={ref}>
    return (
      <Draggable cancel=".not-draggable">
        <div class="popup">
          <div class="idivHeader">
            <a class="not-draggable iclose" onClick={onClose}>&times;</a>
          </div>
          <DDiv ctxt={ctxt} class="not-draggable popup_inner" />
        </div>
      </Draggable>
    );
};
export default Popup;
