import create from 'zustand';

const useHelp = create(set => ({
  iniHelp: true,
  toHelp: false,
  lang: 'EN',
  setLang: (sel) => set({ lang: sel }), //lang === 'EN'? 'TW': 'EN' }),
  closeHelp: () => set(state => ({ iniHelp: false, toHelp: false })),
  enableHelp: () => set({ toHelp: true })
}));
export default useHelp;
