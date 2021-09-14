import { useEffect } from "preact/hooks";
import { Fragment } from "preact";
//import React from "preact/compat";
import { Fancybox as NativeFancybox } from "@fancyapps/ui/dist/fancybox.esm.js";
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       "@fancyapps/ui/dist/fancybox.css");

const Fancybox = (props) => {
  const delegate = props.delegate || "[data-fancybox]";

  useEffect(() => {
    const opts = props.options || {};
    NativeFancybox.bind(delegate, opts);

    return () => {
      NativeFancybox.destroy();
    };
  }, []);

  return <Fragment>{props.children}</Fragment>;
};
export default Fancybox;
