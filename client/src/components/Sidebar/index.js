import { useState, useCallback } from 'preact/hooks'; //useEffect, useContext
import style from './style';

const Sidebar = () => {
  //props
  const [menuItem, setMenuItem] = useState({
      onSidebar: false,
  });
  const [hide, setHide] = useState(false);

  const toggleHidex = () => {
    let enable = true //user.init && loaded
    toolbarToggle(!hide, enable)
    setHide(!hide)
  };

  const toolbarToggle = useCallback((hided, enable) => {
    if (enable) {
      //document.getElementById("toolbar").style.display = hided? 'none': 'block';
      document.getElementById("toolToggle").style.display = hided? 'none': 'block';
      document.getElementById("rightarea").style.display = hided? 'none': 'block';
      document.getElementById("ctrl").style.display = hided? 'none': 'block';

      setMenuItem(itemState => ({
        ...itemState,
        onSidebar: hided? false: true,
      }));
    }
  },[]);

  let className;
  if (menuItem.onSidebar) {
    className=`${style.sideContainer} ${style.open_sidebar}`;
  } else {
    className=`${style.sideContainer}`;
  }
  let classToggle;
  if (hide) {
    classToggle=`${style.menuButnx}`;
  } else {
    classToggle=`${style.menuButn}`;
  }

  return (
    <div class = {style.sideblock}>
      <div id="swipex" class = {style.swipe_area}></div>
      <div class = {style.menuToggle}>
          <div class = {style.menuBtn_in_span}>
          <button id="menuButn" class = {classToggle} type="button"
            onClick={() => setMenuItem(itemState => ({
              ...itemState,
              onSidebar: itemState.onSidebar? false: true
            }))}>
            <i></i>
          </button>
          </div>
      </div>
      <div id="sideBar" class={className}>
          <div class = {style.sidemenu}>
            <ul>
              <li><a href="#">Test link</a></li>
              <li>
                <button style="padding:6px 8px;margin:12px" class="button" onClick={toggleHidex}>{hide? 'Show all': 'Hide all'}</button>
              </li>
              <li><a href="#">Setting</a>
                <ul>
                  <li><a href="#">Test Widget</a></li>
                  <li><a href="#">Look 2th</a>
                    <ul>
                      <li><a href="#">It 3rd</a></li>
                      <li class = {style.menu_item_divided}><a href="#">End</a>
                      </li>
                    </ul>
                  </li>
                  <li class = {style.menu_item_divided}><a href="#">Services</a>
                  </li>
                </ul>
              </li>
              <li><a href="#">Contact</a></li>
            </ul>
          </div>
      </div>
    </div>
  );
};

export default Sidebar;
