const schema = `
type Query {
     taxontree: [TreeNode]!
     infq(taxon: String, keystr: Boolean, mode: String, first: Int, last: Int, after: String, before: String, key: String): SpkeyConn
     keys(sp: String!): [Spkeyq]!
     keytree(sp: String!): [KeyTree]!
}

type KeyTree {
     unikey: ID!
     edges: KeyNode
}

type KeyNode {
  unikey: ID!
  ctxt: String
  node: KeyNode
}

type Spkeyq {
     unikey: String
     taxon: String
     fullname: String
     genus: String
     family: String
     keystr: String
     sex: String
     ctxt: String
     docn: Int
     type: Int
     kcnt: Int
}

type SpkeyConn {
  totalCount: Int
  pageInfo: PageInfo
  edges: SpkeyEdge
}

type PageInfo {
  num: Int
  hasNextPage: Boolean
  hasPreviousPage: Boolean
}

type SpkeyEdge {
  node: [Spkeyq]
  cursor: String
  endCursor: String
}

type TreeNode {
  label: String!
  value: String!
  children: [Treelevel]!
}

type Treelevel {
  label: String!
  value: String!
  children: [Treeleaf]
}

type Treeleaf {
  label: String!
  value: String!
}
`
export default schema
