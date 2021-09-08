import {h, Component} from 'preact';

export default class App extends Component {
    render (props) {
	const date = new Date();
	const message = typeof window === 'undefined' ? 'Server rendered at: ' + date : 'Hydrated at: ' + date;
	return (
            <div>
		<h1>Hello Preact</h1>
	        <div>{message}</div>
	    </div>
	);
    }
}
