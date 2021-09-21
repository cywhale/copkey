const schema = `
type Query {
	key(sp: String!): [Spkeyq]!
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
`

export default schema
