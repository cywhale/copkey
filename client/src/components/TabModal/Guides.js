import { useState } from 'preact/hooks';
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       '../../style/style_guides.scss');

const Guides = () => {
  const [lang, setLang] = useState('EN');

  const change_langx = e => {
    let sel = 'EN';
    if (e.target.checked) {
      sel = 'TW'
    }
    if (sel !== lang) { setLang(sel) }
  };

  const guidex = lang === 'EN'? 'Test Language!' : '測試語言切換';

  return (
    <>
      <div>
        <span class='smgrey'>Language  </span>
        <label for="sw_lang" class="switch" aria-label="EN/TW 語言切換">
          <input type="checkbox" id="sw_lang" onChange={change_langx} />
          <span class="slider round"></span>
        </label>
      </div>
      <br/><hr/><br/>
      <div>
        <span>{guidex}</span>
      </div>
    </> 
  )
};
export default Guides;
