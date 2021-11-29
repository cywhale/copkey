import create from 'zustand';

const useHelp = create(set => ({
  iniHelp: true,
  toHelp: false,
  toStep: false,
  lang: 'EN',
  setLang: (sel) => set({ lang: sel }), //lang === 'EN'? 'TW': 'EN' }),
  setStep: (state) => set({ toStep: state }),
  closeHelp: () => set(state => ({ iniHelp: false, toHelp: false })),
  enableHelp: () => set({ toHelp: true })
}));
export default useHelp;
