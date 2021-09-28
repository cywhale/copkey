const schema = `
type Query {
	key(sp: String!): [Spkeyq]!
        infq(sp: String!, first: Int, last: Int, after: String, before: String): SpkeyConn!
        init: [Spkeyq]!
        page(p: Int!): [Spkeyq]!
	keys(sp: String!): [Spkeyq]!
}

type Spkeyq {
	unikey: String
	taxon: String!
	fullname: String
	genus: String
        family: String
        keystr: String
        sex: String
        ctxt: String
        docn: Int
        page: Int
        kcnt: Int
}

type SpkeyConn {
  totalCount: Int!
  pageInfo: PageInfo!
  edges: SpkeyEdge!
}

type PageInfo {
  num: Int!
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
}

type SpkeyEdge {
  node: [Spkeyq]!
  cursor: String!
}
`

export default schema
