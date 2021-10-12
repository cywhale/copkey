import(/* webpackPrefetch: true */
       /* webpackPreload: true */'./style');
import App from './components/app';
import sw_register from './sw_register';

console.log("process.env.NODE_ENV: ", process.env.NODE_ENV);
sw_register();

export default App;
