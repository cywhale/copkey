import { useRef, useEffect } from "preact/hooks";
//import React from "preact/compat";
import { Carousel as NativeCarousel } from "@fancyapps/ui/dist/carousel.esm.js";
// Note @fancyapps/ui/dist/carousel.css should load before style_fancy.scss, so make it load in Home
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       "../../style/style_fancy.scss");

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

