import Spkey from '../models/spkey_mongoose.js';
// Basicaly follow keytree.js, but output keystr, not ctxt; and do not output figs
// But change "children", which originally used in top2bottom(t2b), to "parent" as in b2t
// Playground add replaceAll to convert JSON [\" into normal string: https://mongoplayground.net/p/v_lKWR9bcOb
export default async function keystrx(taxon) {

let genus = taxon.split(/\s/)[0];
let result = await Spkey.aggregate([
  {
    $match: {
      $and: [
        {
          //$or: [
          //  {
              "type": {"$eq": 1}
          /*},//$"nin": [-1, 2] if t2b in older version
            {
              "type": 2,
              "taxon": taxon
            } // no need when b2t because initial point is certain with specific taxon
          ]*/
        }, // 20220420 modified with figure(2)
        //Not figures (2), and not genus (-1)
        /*{
          "pkey": {
            "$in": [
              null,
              ""
            ]
          }
        },
        //genus for testing: "Acartia"
        {
          "genus": genus
        }*/ //t2b needs initial point is pkey==null, and restrict possibility to specific genus
        {
          "taxon": taxon
        }
      ]
    }
  },
  {
    $project: {
      "unikey": 1,
      "pkey": 1,
      "taxon": 1,
      "type": 1,
      "keystr": { $replaceAll: { input: {$substr: ["$keystr",2,-1]}, find: '\"]', replacement: "" } },
      "sex": 1
    }
  },
  {
    $graphLookup: {
      from: "spkey",
      startWith: "$pkey", //"$unikey", //old t2b
      connectFromField: "pkey", //"unikey",
      connectToField: "unikey", //"pkey",
      depthField: "level",
      as: "parent"
    }
  },
  {
    $unwind: {
      path: "$parent",
      preserveNullAndEmptyArrays: false
    }
  }, //to keep figure(type=2) must preserveNullAndEmptyArrays: true (otherwise can be false)
  {
    $sort: {
      "parent.level": -1
    }
  },
  {
    $group: {
      _id: "$unikey",
      pkey: {
        $first: "$pkey"
      },
      taxon: {
        $first: "$taxon"
      },
      type: {
        $first: "$type"
      },
      keystr: {
        $first: "$keystr"
      },
      sex: {
        $first: "$sex"
      },
      parent: {
        $push: "$parent"
      }/*, //old t2b, no need in b2t
      taxonarr: {
        $push: {
          $convert: {
            input: {
              $or: [
                {
                  $eq: [
                    "$children.taxon",
                    taxon
                  ]
                },
                {
                  $eq: [
                    "$taxon",
                    taxon
                  ]
                } //20220420 modified: for figures of taxon
              ]
            }, //previous $ne: ["$children.taxon", ""]
            to: "bool"
          }
          //if taxon=="" get false (to filter all "" of taxon in children/tree-branch
        }
      }*/
    }
  },
  {
    $project: {
      "_id": 1,
      "unikey": "$_id",
      "pkey": 1,
      "taxon": 1,
      "keystr": 1, //{ $replaceAll: { input: {$substr: ["$keystr",2,-1]}, find: '\"]', replacement: "" } },
      "sex": 1,
/*      isAnyTaxon: {
        $anyElementTrue: [
          "$taxonarr"
        ]
      },*/ // old t2b
      "parent": {
        $filter: {
          input: "$parent",
          as: "prenode",
          cond: {
            $or: [
              {
                $eq: [
                  "$$prenode.taxon",
                  taxon
                ]
              },
              //taxon for testing: "Acartia hongi"
              {
                $and: [
                  {
                    $eq: [
                      "$$prenode.type",
                      0
                    ]
                  },
                  {
                    $eq: [
                      "$$prenode.taxon",
                      ""
                    ]
                  }
                ]
              }
            ]
          }
        }
      }
    }
  },
/*{
    $match: {
      "isAnyTaxon": true
    }
  },*/ //old t2b
 //to filter all "" of taxon in children/tree-branch
  {
    $addFields: {
      parent: {
        $reduce: {
          input: "$parent",
          initialValue: {
            level: -1,
            presentChild: [],
            prevChild: []
          },
          in: {
            $let: {
              vars: {
                prev: {
                  $cond: [
                    {
                      $eq: [
                        "$$value.level",
                        "$$this.level"
                      ]
                    },
                    "$$value.prevChild",
                    "$$value.presentChild"
                  ]
                },
                current: {
                  $cond: [
                    {
                      $eq: [
                        "$$value.level",
                        "$$this.level"
                      ]
                    },
                    "$$value.presentChild",
                    []
                  ]
                }
              },
              in: {
                level: "$$this.level",
                prevChild: "$$prev",
                presentChild: {
                  $concatArrays: [
                    "$$current",
                    [
                      {
                        $mergeObjects: [
                          "$$this",
                          {
                            parent: {
                              $filter: {
                                input: "$$prev",
                                as: "e",
                                cond: {
                                  $eq: [
                                    "$$e.unikey", //"$$e.pkey", //old t2b
                                    "$$this.pkey" //"$$this.unikey"
                                  ]
                                }
                              }
                            },
                            keystr: {
                              $replaceAll: { input: {$substr: ["$$this.keystr",2,-1]}, find: '\"]', replacement: "" }
                            }
                          }
                        ]
                      }
                    ]
                  ]
                }
              }
            }
          }
        }
      }
    }
  },
  {
    $addFields: {
      parent: "$parent.presentChild"
    }
  } /*,
  {
    $project: {
      "_id": 1,
      "unikey": "$_id",
      "pkey": 1,
      "taxon": 1,
      "keystr": 1,
      "sex": 1,
      "children": {
        $filter: {
          input: "$children",
          as: "child",
          cond: {
            $or: [
              {
                $eq: [
                  "$$child.taxon",
                  taxon
                ]
              },
              {
                $and: [
                  {
                    $ne: [
                      "$$child.children",
                      []
                    ]
                  },
                  // empty leaf will be removed
                  {
                    $eq: [
                      "$$child.type",
                      0
                    ]
                  },
                  {
                    $eq: [
                      "$$child.taxon",
                      ""
                    ]
                  }
                ]
              }
            ]
          }
        }
      }
    }
  } */ //old t2b
]).exec()

return result
}
