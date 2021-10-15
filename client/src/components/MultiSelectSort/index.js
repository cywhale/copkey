import { options } from 'preact';
import { useEffect, useState, useMemo } from 'preact/hooks';
import { MultiSelectContainer } from './MultiSelectContainer';
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       'react-dropdown-tree-select/dist/styles.css');
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       '../../style/style_dropdown.scss');

import data from './data.json';

const MultiSelectSort = () => {
  const [ selected, setSelected ] = useState({
    val: [],
    //type: [],
    query: ''
  });
  const rdata = [...data];

  const dispatcher = () => {
    history.pushState(null, null, '#' + selected.query);
    window.dispatchEvent(new HashChangeEvent('hashchange'));
  };
  options.debounceRendering = dispatcher => setTimeout(dispatcher, 150);

  const onChange = useMemo(() => (_, selectedNodes) => {
    let valx = [];
    //let typex = [];
/*  const getCurrDataFormat = (item) => {
      if (item.hasOwnProperty('type')) {
          typex.push(item.type);
      }
    };*/
// old function is to select leaf node, but for this case, we only need to know top level of selected node
/*  selectedNodes.map((item) => {
      if (item.hasOwnProperty('_children')) {
        item._children.map((child) => {
          let nodex = child.substring(6).split("-").reduce(
            (prev, curr) => {
              let leaf = prev[parseInt(curr)];

              if (leaf.hasOwnProperty('children')) {
                return leaf.children;
              } else {
                //getCurrDataFormat(leaf); //get leaf property
                return leaf.value;
              }
            },
            rdata
          ); //rdts1-0-0-0
          if (typeof nodex !== 'string' && nodex.length>1) {
            nodex.map((item) => {
              //getCurrDataFormat(item);
              valx.push(item.value);
            });
          } else {
            valx.push(nodex);
          }
        });
      } else {
        //getCurrDataFormat(item);
        valx.push(item.value);
      }
    });*/
    selectedNodes.map((item) => {
        valx.push(item.value);
    });
    console.log('Get node value: ', valx);

    setSelected((preState) => ({
      ...preState,
      val: [...valx],
      //type: [...typex],
      query: 'search=' + valx.join('|')
    }));
  }, []);

  useEffect(() => {
    if (selected.query !== '') {
      dispatcher()
    }
  }, [selected.query])

  return(
    <div class="flex-right-div">
      <MultiSelectContainer data={data} onChange={onChange} inlineSearchInput={true} />
    </div>
  );
};
export default MultiSelectSort;
