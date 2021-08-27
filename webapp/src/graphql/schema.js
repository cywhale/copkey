const schema = `
type Query {
	key(sp: String!): [Spkeyq]!
        getsp(sp: String!): [Spkeyq]!
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
}
`

export default schema
