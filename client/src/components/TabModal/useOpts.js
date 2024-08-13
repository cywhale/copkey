import create from 'zustand';

const useOpts = create(set => ({
  pageLoaded: false,
  fuzzy: false,
  sameTaxon: false,
  forceGenus: false,
  forceSpecies: false,
  pageSize: 30,
  keyTree: false,
  setOpts: (opt) => set(opt)
/*setFuzzy: (opt) => set({fuzzy: opt}),
  setSameTaxon: (opt) => set({sameTaxon: opt}),
  setForceGenus: (opt) => set({forceGenus: opt}),
  setForceSpecies: (opt) => set({forceSpecies: opt}),
  setPageSize: (opt) => set({pageSize: opt})*/
}));
export default useOpts;
