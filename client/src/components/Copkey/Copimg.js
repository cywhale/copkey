//my codesandbox trial: https://codesandbox.io/s/fancybox-preact-demo-l4dli
import { Fragment } from "preact";
//import React from "preact/compat";
//import parse from "html-react-parser"; // if use Fancybox
import DDiv from "async!../Compo/DDiv";
//import Fancybox from "async!../Fancybox";
import Carousel from "async!../Fancybox/carousel";

const Copimg = (props) => {
  const { ftxt } = props

  const fboxs = ftxt.split(/\\n/).map((fx) => {
    let f1 = (fx.match(
      /\<div class=\"fig_title(.*)\/span\>\<\/div\>(\<br\>)*\<span class=\"n/g
    ) || [""])[0];
    let ftitle = f1.replace(
      /(^(\<div class=\"fig_title\">)|(\<\/div\>(\<br\>)*\<span class=\"n)$)/g,
      ""
    );
    let f2 = fx
      .split(/\<(\/)*span\>/)
      .map((txt) => {
        return (txt.match(/\<a data(.*)\>\<\/a\>/g) || [""])[0];
      })
      .filter((v) => v); //filter empty string

   //patterns are like:
   //</a><span id="fig_Acartia_bifilosa_001" class="spcap">Mazzocchi</span></span>
   //</a><span id="fig_Acartia_bifilosa_002" class="spcap">Original</span></span></div><br>

    let fsub = fx
      .split(/\<\/a\>/)
      .map((txt) => {
        return (txt.match(
          /\<span id=\"fig_(.*)(\<\/span\>){2}/g
        ) || [""])[0].replace(/(\<\/span\>){2}/, "</span>");
      })
      .filter((v) => v); //filter empty string

    let fcap = (fx.match(/\<div class=\"fig_cap(.*)\/div\>/g) || [""])[0];

    if (fsub.length == f2.length) {
      f2.forEach((el, idx, arr) => {
        arr[idx] = '<div style="display:table">' + //if use Carousel
          arr[idx].replace(
        // /a data-fancybox=(.*)class=\"fbox\"/g,
        //  "a data-fancybox='gallery' " + "data-caption='" + fsub[idx] + "'"
        //).replace(
           /img src=\"\/assets\/img\/species/g, 'img src="/assets/img/sp_thumb'
        ) + //if use Carousel
        '<br><br>' + fsub[idx] + '</div>'
      });
    }

    let fa = f2
    /*.reduce((acc, cur) => { //if use Fancybox
          return acc + cur;
      }, "") */
      //.replace(/(border=\"0\" |class=\"fbox\" )/g, '')
    /*  <Fancybox options={Hash: false, preventCaptionOverlap: true}>
          {parse(fa, { library: require("preact") })}
        </Fancybox>
    */ //use Carousel
    const copts = {
        infinite: false,
        slidesPerPage: 'auto',
        center: true,
        //fill: true,
        dragFree: true
    };
    return (
      <Fragment>
        <DDiv ctxt={ftitle} class="fig_title" />
        <Carousel items={fa} options={copts} />
        <DDiv ctxt={fcap} class="fig_capion" />
      </Fragment>
    );
  });

  return <Fragment>{fboxs}</Fragment>;
};
export default Copimg;
