//import { createRef } from 'preact'; // h, Component, render
import { Router } from 'preact-router';
import Sidebar from 'async!./Sidebar';
import Home from 'async!./Home'
import style from './style/style_app';

const App = (props) => {
  //const ref = createRef();
  return (
  //const Main = () => { <Router history={createHashHistory()}>
    <div id="app">
      <Router>
        <div path='/' class={style.home}>
          <div class={style.right_area} id="rightarea" />
          <Sidebar />
          <Home />
        </div>
      </Router>
    </div>
  );
}
export default App;
