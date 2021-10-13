const schema = `
type Query {
	key(sp: String!): [Spkeyq]!
        infq(taxon: String!, first: Int, last: Int, after: String, before: String, key: String): SpkeyConn!
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
        type: Int
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
  endCursor: String!
}
`

export default schema
