export default function deKeytree (data, countMax = 10000) {

let keys = { "female": [],
             "femalekey": [],
             "male": [],
             "malekey": [],
             "root": [],
             "nchild": [],
             "level": 0,
             "sex": "",
             "tokey": "" };
let count = 0;

const node_reduce = (node, keyx) => {
  let { children, ...attr} = node;
  if (!!children && !!children.length) {
    count = count + 1;
    keyx.root.push(node);
    keyx.nchild.push(children.length-1);
    keyx.level = keyx.level + 1;
    return node_reduce(children[0], keyx);
  } else {
    //console.log("After Reduce reaching leaf, in level: ", keyx.level);
    if (attr.taxon == taxon) {
      //console.log("Reduce Leaf now: ", attr.taxon, " with sex: ", attr.sex, " in key: ", attr.unikey, " heading for: ", attr.pkey);
      keyx.sex = attr.sex;
      keyx.tokey = attr.pkey;
      keyx[attr.sex].push(attr.ctxt);
      keyx[attr.sex+'key'].push(attr.unikey);
    } else if (keyx.tokey == attr.unikey) {
      //console.log("Reduce Reach key: ", attr.unikey, " heading for: ", attr.pkey, " (sex):", keyx.sex);
      keyx.tokey = attr.pkey;
      keyx[keyx.sex].unshift(attr.ctxt);
      keyx[keyx.sex+'key'].unshift(attr.unikey);
    } /*else {
      console.log("Reduce Not handle: ", attr.unikey);
    }*/
    count = count + 1;
    if (count >= countMax) {
      console.log("Error: traversal key exceed max_limit, and break...")
      return keyx;
    }
    keyx.level = keyx.level-1;
    if (keyx.level < 0) {
      return keyx;
    }
    let root = keyx.root[keyx.level];
    let nchild = keyx.nchild[keyx.level];
    //console.log("Now in level: ", keyx.level, " with root: ", root.unikey, " with remaining child: ", nchild);
    if (nchild == 0) {
      keyx.root.pop();
      keyx.nchild.pop();
      //console.log("Delete children in root: ", root);
      delete root["children"];
      return node_reduce(root, keyx);
    }
    let idx = root.children.length - nchild;
    //console.log("Handle nth-child: ", idx, root);
    //Note: because jump to (i+1)th branch, this root will be only recorded in latest branch (when last branch finally ended and upward)
    //But then the 0th - ith branch lost this root connection, so must be recorded here
    if (keyx.sex!=="" && keyx[keyx.sex].length && keyx.tokey==root.unikey) { //means its a recorded path
      //console.log("Record root in pre-handled path for: ", keyx[keyx.sex+'key'][0]);
      keyx[keyx.sex].unshift(root.ctxt);
      keyx[keyx.sex+'key'].unshift(root.unikey);
    }
    keyx.nchild[keyx.level] = keyx.nchild[keyx.level] - 1;
    if (root.children[idx]) {
      keyx.level = keyx.level + 1;
      return node_reduce(root.children[idx], keyx);
    } else {
      console.log("Error: traversal tree downward to branch but no this child, and break...")
      return keyx;
    }
  }
};

return node_reduce(data, keys);
};
