export default function deKeytree (data, taxon, countMax = 300) {

let keys = { "node":[],
           /*"female": [],
             "femalekey": [],
             "male": [],
             "malekey": [],*/
             "root": [],
             "nchild": [],
             "spidx": -1,
             "level": 0,
             "sex": "",
             "tokey": "",
             "ances": "",
             "presex": "" };
let count = 0;
let genus = taxon.split(/\s/)[0];

/* debug needed
const getStack = (node, skey="unikey") => {
  return node.map((elem) => {return elem[skey]})
};*/

const node_reduce = (node, keyx) => {
  let { children, ...attr} = node;
  if (!!children && !!children.length) {
    count = count + 1;
    keyx.root.push(node);
    keyx.nchild.push(children.length-1);
    keyx.level = keyx.level + 1;
    //console.log("Recursively child-0 to level: ", keyx.level, " root inside length: ", keyx.root.length, " and at this level still had child-1: ", children.length-1, " node unikey: ", node.unikey, " and child0 unikey: ", children[0].unikey);
    return node_reduce(children[0], keyx);
  } else {
    //console.log("After Reduce reaching leaf, in level: ", keyx.level, " Stack: ", getStack(keyx.root).join(", "));
    if (attr.taxon == taxon) {
      //console.log("Reduce Leaf now: ", attr.taxon, " with sex: ", attr.sex, " in key: ", attr.unikey, " heading for: ", attr.pkey);
      if (keyx.spidx<0 || (keyx.spidx>=0 && attr.taxon!==keyx.node[keyx.spidx].taxon)) {
        keyx.spidx = keyx.spidx + 1;
        keyx.node[keyx.spidx]={
          "taxon": attr.taxon,
          "female": [],
          "femalekey": [],
          "male": [],
          "malekey": []
        };
      } else if (keyx.sex!=="" && keyx.sex!==attr.sex) {
        //console.log("2nd sex found when previous sex not resolved: ", keyx.sex, " will be coverd by: ", attr.sex)
        //console.log("!!Note: Now if find ancestor: ", keyx.ances, " will record in both sexes");
        keyx.presex = keyx.sex //will have common ancestors
      }
      keyx.sex = attr.sex;
      keyx.tokey = attr.pkey;
      keyx.node[keyx.spidx][attr.sex].push(attr.ctxt);
      keyx.node[keyx.spidx][attr.sex+'key'].push(attr.unikey);
    } else if (keyx.tokey == attr.unikey) {
      //console.log("Reduce Reach key: ", attr.unikey, " heading for: ", attr.pkey, " (sex):", keyx.sex);
      if (keyx.last != (attr.unikey + keyx.sex)) {
        keyx.tokey = attr.pkey;
        keyx.node[keyx.spidx][keyx.sex].unshift(attr.ctxt);
        keyx.node[keyx.spidx][keyx.sex+'key'].unshift(attr.unikey);
      }
      if (keyx.presex!=="" && attr.unikey===keyx.ances) {
        //console.log("!!Note: Must record common ancestor at: ", attr.unikey)
        keyx.node[keyx.spidx][keyx.presex].unshift(attr.ctxt);
        keyx.node[keyx.spidx][keyx.presex+'key'].unshift(attr.unikey);
        keyx.ances = attr.pkey;
      }
    } /*else {
      console.log("Reduce Not handle: ", attr.unikey);
      console.log("want to key: ", keyx.tokey, ", and now recorded sex: ", keyx.sex)
    }*/
    count = count + 1;
    if (count >= countMax) {
      console.log("Error! Traversal exceeds max_limit, and break...")
      return keyx;
    }
    keyx.level = keyx.level-1;
    if (keyx.level < 0) {
      return keyx;
    }
    let root = keyx.root[keyx.level];
    let nchild = keyx.nchild[keyx.level];
    //console.log("Now in level: ", keyx.level, " with root: ", root.unikey, " with remaining child: ", nchild, " and tokey: ", keyx.tokey);
    if (nchild == 0) {
      keyx.root.pop();
      keyx.nchild.pop();
      //console.log("Delete children in root: ", root.unikey);
      delete root["children"];
// cannot further backword because cause the upper keyx.root[keyx.level] be push twice
/*      if (keyx.tokey == root.unikey && keyx.level>=1) {
        console.log("Current root just the key: ", root.unikey, " heading for: ", root.pkey, " (sex):", keyx.sex);
        keyx.tokey = root.pkey;
        keyx.node[keyx.spidx][keyx.sex].unshift(root.ctxt);
        keyx.node[keyx.spidx][keyx.sex+'key'].unshift(root.unikey);
        keyx.level = keyx.level-1;
        console.log("Back further to level: ", keyx.level, " Stack: ", getStack(keyx.root).join(", "), " go to root: ", keyx.root[keyx.level]);
        return node_reduce(keyx.root[keyx.level], keyx)
      }
      else {*/
      //console.log("and now in level: ", keyx.level, " Stack: ", getStack(keyx.root).join(", "), " go to root: ", root.unikey);
      return node_reduce(root, keyx);
      //}
    }
    let idx = root.children.length - nchild;
    //console.log("Handle nth-child: ", idx, root);
    //Note: because jump to (i+1)th branch, this root will be only recorded in latest branch (when last branch finally ended and upward)
    //But then the 0th - ith branch lost this root connection, so must be recorded here
    if (keyx.sex!=="" && keyx.node[keyx.spidx][keyx.sex].length && keyx.tokey==root.unikey &&
        keyx.last !== (root.unikey + keyx.sex)) { //means its a recorded path
      //console.log("Record root in pre-handled path for: ", keyx.node[keyx.spidx][keyx.sex+'key'][0], " and may have common ancestor: ", root.pkey);
      keyx.node[keyx.spidx][keyx.sex].unshift(root.ctxt);
      keyx.node[keyx.spidx][keyx.sex+'key'].unshift(root.unikey);
      keyx.last = root.unikey + keyx.sex;
      keyx.ances = root.pkey; //if sexes have common ancestor, from this tokey to start
    } else if (keyx.last === (root.unikey + keyx.sex)) {
      keyx.last = "";
      keyx.ances = root.pkey;
    }
    if (keyx.level==0 && keyx.sex!=="") {
      //console.log("Had back to level-0, clear sex and tokey info: ", keyx.sex);
      keyx.sex="";
      keyx.tokey="";
    }
    keyx.nchild[keyx.level] = keyx.nchild[keyx.level] - 1;
    if (root.children[idx]) {
      keyx.level = keyx.level + 1;
      return node_reduce(root.children[idx], keyx);
    } else {
      console.log("Error: Jump to next branch but no this child, and break...")
      return keyx;
    }
  }
};
// 20220420 add taxon figs in keytree graphql //https://jsfiddle.net/cywhale/u83vbj46/609/
// 20200421 testing taxon: "Lucicutia gemina", fix two sex infor at outer node and states not reset bug: https://jsfiddle.net/cywhale/u83vbj46/775/
let figs = {};
data.forEach((node, index) => {
  if (node.unikey.indexOf('fig') !== -1) {
    if (node.taxon === taxon) {
      console.log("Fig found for taxon!")
      figs[node.taxon] = [];
      figs[node.taxon].push(
        node.ctxt
        .replace(/(\\n)+/g,'\\n') //needed in Copimg.js, and some additional fig append to the same figs_xxx div need separate it with \\n
        .replace(/\<\/div\>(\<br\>){2,4}\<div class=\"blkfigure/g, '</div><br><br>\\n<div class="blkfigure')
      );
    }
  } else {
    keys.last=""; //reset some states, otherwise cause error
    keys.level=0;
    keys.ances="";
    keys.presex="";
    //console.log("Before next node starting:", keys);
    keys = node_reduce(node, keys);
    //console.log("Count this time: ", count)
    count = 0;
  }
});
//console.log("Debug fig: ", figs);

let ctxt = '';
keys.node.forEach((node) => {
  ctxt = '<div class="kblk"><p class="doc_title"><em>' + node.taxon + '</em>&nbsp;<a aria-label="back to the genus key" href="#taxon_' +
         genus +'">☚</a></p></div>'
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
        "fig": figs[taxon].join('\\n')
       };
};
