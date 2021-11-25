import { useState, useCallback } from 'preact/hooks';
import useHelp from '../Helper/useHelp';
import(/* webpackMode: "lazy" */
       /* webpackPrefetch: true */
       '../../style/style_guides.scss');

const Guides = () => {
  //const [lang, setLang] = useState('EN');
  const lang= useHelp(useCallback(state => state.lang, []));
  const change_langx = e => {
    let sel = 'EN';
    if (e.target.checked) {
      sel = 'TW'
    }
    if (sel !== lang) { //setLang(sel) }
      useHelp.getState().setLang(sel);
    }
  };

  const langsel = '語言 Language ' //lang === 'EN'? 'Language ': '語言 ';
  const guidex = () => {
    return(
    lang === 'EN'?
      <span>
        Welcome to explore <span class='yellow'><strong>Calanoid copepods</strong></span> classification key!<br/><br/>
        This App integrates key to the genera/species of Calanoida and an overview about its morphology/taxonomy/distribution.<br/><br/>
        To find help, first, open the <span class='yellow'><strong>'?' icon</strong></span> at the upper-right corner.<br/>
        Read help/guides in English/Chinese by switching <span class='yellow'><strong>'Language'</strong></span><br/><br/>
        The copepods included here are species mainly in the marine of East Asia from the Yellow Sea to the South China Sea.<br/><br/>
        Query taxons by using search bar above, or checking the tree-list of the dropdown menu in the upper-right.<br/><br/>
        The copepods are small and similar. Track classification key in order and find how these copepods are classified.<br/>
        The classification key can be searched too. For example, input <span class='yellow'><strong>'Leg 5'</strong></span> in search bar, enable the right checkbox, search, and then get the results of keys about Leg 5.<br/><br/>
        There are hundreds of figures for the characteristics of copepod classification in this site, which were hand-drawn or collected from literatures by the author (see About). Just scroll-down and open these figures to help you to identify copepods.<br/>
      </span> :
      <span>
        歡迎使用<span class='yellow'><strong>橈足亞綱哲水蚤目</strong></span>浮游動物分類查詢！<br/><br/>
        這裡整合了哲水蚤目橈足類動物的屬、種分類查詢與其型態、分類、分佈等綜述<br/><br/>
        想知道怎麼使用？第一步，可先點選右上角<span class='yellow'><strong>'問號'</strong></span><br/>
        切換語言(英/中)可切換上方<span class='yellow'><strong>'語言'</strong></span><br/><br/>
        所涵蓋的橈足類，主要分佈在北起黃海南至南海的東亞海域中<br/>
        種類查詢可經由上方搜尋欄，以及右上方下拉樹狀選單中勾選<br/><br/>
        橈足類體型微小，外型相似，按網頁上分類索引的鍵值連結，便可依序掌握分類的關鍵<br/>
        分類特徵也可查詢。比如在搜尋欄中輸入<span class='yellow'><strong>'Leg 5'</strong></span>，並勾選右側核選方框後搜尋，便可迅速列出檢索中所有相關第五對足的索引<br/><br/>
        本站有數百張作者手繪或蒐集文獻的橈足類分類特徵圖，拉到網頁下方便可看到相關於本頁出現物種的科學繪圖，點選放大，將有助於橈足類物種辨識<br/>
      </span>
    )
  }
  return (
    <>
      <div style='margin-bottom:1rem'>
        <span class='smgrey'>{langsel}</span>
        <label for="sw_lang" class="switch" aria-label="EN/TW 語言切換">
          <input type="checkbox" id="sw_lang" onChange={change_langx} />
          <span class="slider round"></span>
        </label>
      </div>
      <div class='guideinfo'>
        { guidex() }
      </div>
    </> 
  )
};
export default Guides;
