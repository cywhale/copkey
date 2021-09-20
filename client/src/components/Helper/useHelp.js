import create from 'zustand';

const useHelp = create(set => ({
  iniHelp: true,
  toHelp: false,
  closeHelp: () => set(state => ({ iniHelp: false, toHelp: false })),
  enableHelp: () => set({ toHelp: true })
}));
export default useHelp;
