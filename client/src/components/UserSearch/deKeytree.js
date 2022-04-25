export default function deKeytree (data, taxon, countMax = 200) {

let keys = {/*"female": [],
             "femalekey": [],
             "male": [],
             "malekey": [],*/
             "node":[],
             //"root": [],   //no need if b2t reversal
             "nchild": -1,   //[] if b2t reversal
             "spidx": -1,
             "level": 0,
             "sex": "",
             "tokey": "",
             //"ances": "",  //no need if b2t reversal
             //"presex": "", //no need if b2t reversal
             };
let count = 0;
let genus = taxon.split(/\s/)[0];

/* debug needed
const getStack = (node, skey="unikey") => {
  return node.map((elem) => {return elem[skey]})
};*/

const node_bot2top = (node, keyx) => {
  let { children, ...attr} = node;
  if (attr.taxon !== "") {
    //console.log("b2t taxon:", attr.taxon, " with sex: ", attr.sex);
    if (keyx.spidx<0 || (keyx.spidx>=0 && keyx.node.length && attr.taxon!==keyx.node[keyx.spidx].taxon)) {
      //console.log("Initialize node..")
      keyx.spidx = keyx.spidx + 1;
      keyx.node[keyx.spidx]={
          "taxon": attr.taxon,
          "female": [],
          "femalekey": [],
          "male": [],
          "malekey": [],
          "both":[],
          "bothkey":[],
          "uknown":[],
          "unknownkey":[]
      };
    }
    keyx.nodeflag = true;
    if (attr.sex==="") {
      keyx.sex="unknown";
    } else if (attr.sex.indexOf("/")>=0) {
      keyx.sex="both";
    } else {
      keyx.sex=attr.sex;
    }
  }
  if (keyx.nodeflag) {
    keyx.tokey = attr.pkey; //now is bottom2top
    keyx.node[keyx.spidx][keyx.sex].unshift(attr.ctxt);
    keyx.node[keyx.spidx][keyx.sex+'key'].unshift(attr.unikey);
    //console.log("Push node in level: ", keyx.level, " in current: ", keyx)
  }
  if (!!children && !!children.length && keyx.nodeflag) {
    count = count + 1;
    //keyx.root.push(node); //no need in b2t
    let rchildflag = false;
    for (let i = 0; i < children.length; i++) {
      //console.log("Check child: ", i, " with pkey: ", children[i].unikey, " and current tokey: ", keyx.tokey);
      if (children[i].unikey === keyx.tokey) {//b2t: find upper node
        //keyx.nchild.push(children.length-i-1); //no need comeback in b2t
        keyx.nchild = i // instead, in b2t, record this index
        rchildflag = true;
        break;
      }
    }
    if (!rchildflag) {
      console.log("Error: No correct path under taxon node, just return..") // in bottom2top reversal (b2t)
      keyx.nodeflag = false;
      return keyx;
    }
    keyx.level = keyx.level + 1;

    //console.log("Recursively child-0 to level: ", keyx.level, " node unikey: ", node.unikey, " and child0 unikey: ", children[keyx.nchild].unikey);
    return node_bot2top(children[keyx.nchild], keyx);
  } else {
    //console.log("After Reduce reaching leaf, in level: ", keyx.level, " Stack: ", getStack(keyx.root).join(", "));
    //console.log("Reaching leaf, return keyx: ", keyx);
    keyx.nodeflag = false;
    return keyx;
  }
};
// 20220420 add taxon figs in keytree graphql //https://jsfiddle.net/cywhale/u83vbj46/609/
// 20220421 testing taxon: "Lucicutia gemina", fix two sex info at outer node and states not reset bug: https://jsfiddle.net/cywhale/u83vbj46/775/
// 20220425 Big change to bottom2top mode (bottom: means from leaf = taxon node; top: means key_1a, 1b that has empty pkey: https://jsfiddle.net/cywhale/u83vbj46/960/
let figs = {};
data.forEach((node, index) => {
  if (node.unikey.indexOf('fig')>=0) {
    if (node.taxon !== "") {
      //console.log("Fig found for taxon!")
      figs[0] = []; //node.taxon, now only handle 1 taxon at a time
      figs[0].push(
        node.ctxt
        .replace(/(\\n)+/g,'\\n') //needed in Copimg.js, and some additional fig append to the same figs_xxx div need separate it with \\n
        .replace(/\<\/div\>(\<br\>){2,4}\<div class=\"blkfigure/g, '</div><br><br>\\n<div class="blkfigure')
      );
    }
  } else {
    //keys.last=""; //reset some states, otherwise cause error
    keys.level=0;
    keys.nodeflag=false //bottom2top: means in the same taxon(first node) to find its farest pkey(last node) recursive path
    //keys.ances="";  //no need in b2t mode
    //keys.presex=""; //no need in b2t mode
    //console.log("Before next node starting:", keys);
    keys = node_bot2top(node, keys);
    //console.log("Count this time: ", count)
    count = 0;
  }
});
//console.log("Debug fig: ", figs);

let ctxt = '';
keys.node.forEach((node) => {
  ctxt = '<div class="kblk"><p class="doc_title"><em>' + node.taxon + '</em>&nbsp;<a aria-label="back to the genus key" href="#taxon_' +
         genus +'">☚</a></p></div>'
  if (node.unknown && node.unknown.length) {
    ctxt = ctxt + '<div class="kblk"><p class="doc_epithets">Key (uncertain gender):</p></div>' +
    node.unknown.join("") + '<br><br>';
  }
  if (node.both && node.both.length) {
    ctxt = ctxt + '<div class="kblk"><p class="doc_epithets"><strong>Female/male</strong> key:</p></div>' +
    node.both.join("") + '<br><br>';
  }
  if (node.female && node.female.length) {
    ctxt = ctxt + '<div class="kblk"><p class="doc_epithets"><strong>Female</strong> key:</p></div>' +
    node.female.join("") + '<br><br>';
  }
  if (node.male && node.male.length) {
    ctxt = ctxt + '<div class="kblk"><p class="doc_epithets"><strong>Male</strong> key:</p></div>' +
    node.male.join("") + '<br><br>';
  }
}, "");
//console.log("Debug ctxt: ", ctxt);

return {"key": ctxt,
        "fig": figs[0].join('\\n') //figs[taxon]
       };
};
