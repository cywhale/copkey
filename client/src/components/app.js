//import { createRef } from 'preact'; // h, Component, render
import { Router } from 'preact-router';
import { QueryClient, QueryClientProvider } from 'react-query';
import { ReactQueryDevtools } from 'react-query/devtools'
import TabModal from 'async!./TabModal';
import Home from 'async!./Home';
import style from './style/style_app';

const queryClient = new QueryClient();

const App = (props) => {
  //const ref = createRef();
  return (
  //const Main = () => { <Router history={createHashHistory()}>
    <div id="app">
      <Router>
        <div path='/' class={style.home}>
          <div style="display:flex;">
            <div class={style.right_area} id="rightarea" />
            <TabModal />
            <h1 style="font-family: Georgia, serif;font-weight:600;">KEY TO THE CALANOID COPEPODS</h1>
          </div>
          <QueryClientProvider client={queryClient}>
            <Home />
            <ReactQueryDevtools initialIsOpen={true} />
          </QueryClientProvider>
        </div>
      </Router>
    </div>
  );
}
export default App;
