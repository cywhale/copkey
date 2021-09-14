import { useRef, useEffect } from "preact/hooks";
//import React from "preact/compat";
import { Carousel as NativeCarousel } from "@fancyapps/ui/dist/carousel.esm.js";

import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       "@fancyapps/ui/dist/carousel.css");

const Carousel = (props) => {
  const wrapper = useRef(null);

  useEffect(() => {
    const items = props.items || [];
    const opts = props.options || {};

    opts.slides = [...items].map((val) => {
      return { html: val };
    });

    const instance = new NativeCarousel(wrapper.current, opts);

    return () => {
      instance.destroy();
    };
  }, []);

  return <div class={`carousel ${props.class || ""}`} ref={wrapper}></div>;
};

export default Carousel;

