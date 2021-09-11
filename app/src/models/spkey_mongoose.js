import mongoose from 'mongoose';
const { Schema } = mongoose;

const spkeyschema = new Schema({
	unikey: { //default:
		type: String,
		required: false
	},
	taxon: {
		type: String,
		required: false
	},
	fullname: {
		type: String,
		required: false
	},
        genus: {
                type: String,
                required: false
        },
        family: {
                type: String,
                required: false
        },
        keystr: {
                type: String,
                required: false
        },
        sex: {
                type: String,
                required: false
        },
	ctxt: {
		type: String,
		required: false
	},
        docn: {
                type: Number,
                required: false
        }
});

const Spkey = mongoose.model('spkey', spkeyschema, 'spkey');
export default Spkey;
