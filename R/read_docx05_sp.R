## Version 5: Specific version for species key for Shih new work 202107
library(officer)
library(odbapi)
library(data.table)
library(magrittr)
#library(stringr)
library(jsonlite)

key_src_dir <- "D:/ODB/Data/shih/shih_5_202107/Key"
web_dir <- "www_sp/"
web_img <- paste0(web_dir, "assets/img/species/")
doc_imgdir <- "doc/sp_key_zip/"
#skipLine <- 4L
page_length_def <- 30L
Traits <- c("(A|a)ppendages", "(H|h)abitus","(M|m)outh(\\spart(s)*)*", "(L|l)eg(s)*[0-9\\-\\/]*", #Euaugaptilus magnus #match Legs 4/5, Undinula vulgaris 
            "(A|a)ntenna(\\s(\\&|\\/)\\s(M|m)andible)*", "(M|m)axillule(\\,|\\/)*\\s*|(M|m)axilla((\\s)*(\\&|\\/)(\\s)*(M|m)axilliped)*", #,Legs 1-3 #Mesocalanus tenuicornis
            #Antenna/Mandible, Maxillule/Maxilla/Maxilliped, Legs 1-3, Legs 4/5 #Undinula vulgaris
            "(H|h)abitus(\\((F|f)emale|(M|male)\\))*") #Nullosetigera auctiseta #Centropages gracilis 
traitstr <- paste0("(",paste0(Traits, collapse="|"), ")")
Extra_epi <- C("malayensis", "pavlovskii", "norvegica", "hebes", "galacialis")  #Paraeuchaeta          
Fig_exclude_word <- "\\(F\\,\\s*M\\)|\\(1\\,f\\)" #exclude pattern in title/main: (F,M), (1/f)
Special_genus <- c("Euaetideus", "Euchirella", "Euchaeta", "Forma", "Pachyptilus",
                   "Euaugaptilus", "Pseudochirella", "Phyllopus", "Paracalanus",
                   "Acrocalanus", "Schmackeria", "Oothrix", "Paraeuchaeta", "Pontella", 
                   "Scolecithricella", "Amallothrix", "Amallophora", "Racovitzanus", 
                   "Oothrix", "Spinocalanus")
Species_groups<- c("malayensis", "pavlovskii", "norvegica", "hebes", "galacialis", #Paraeuchaetas spp.
                   "spinifrons", "papilliger", "fistulosus", "abyssalis", #Heterorhabdus spp. 
                   "Schmackera" #Pseudodiaptomus spp.
                  )
Sp_grps_str <- paste0("(",paste0(Species_groups,collapse="|"),")")
#webCite <- "from the website <a href='https://copepodes.obs-banyuls.fr/en/' target='_blank'>https://copepodes.obs-banyuls.fr/en/</a> managed by Razouls, C., F. de Bovée, J. Kouwenberg, & N. Desreumaux (2015-2017)"
#options(useFancyQuotes = FALSE)
# some unicode should be replaced: <U+00A0> by " ", dQuote() by "
# some special character should be replaced in docx, otherwise docx_summary lost it:
# 24 => ° 18 -> 'N (Need  22°59')

trimx <- function (x) {
  gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(x)))
}

padzerox <- function (x, nzero=3) {
  xt <- as.character(x)
  if (is.na(xt)) return(NA_character_)
  if (nzero <= 1 | nzero <= nchar(xt)) return(xt)
  #if (nzero > nchar(xt)) {
    return (paste0(paste0(rep(0, nzero-nchar(xt)), collapse=""), xt))
  #}
}

read_docx_row <- function (ctentxt, nocheck=FALSE) {
  x <- gsub("\\\t", "", gsub("\\’", "\'", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", gsub("\u00A0{1,}", " ", as.character(ctentxt))))))
  if (nocheck) return(x)
  
  tt <- which(is.na(x) | trimx(gsub("Last update(?:.*)|\\.+|\\,+", "", x))=="")
  if (any(tt)) return("")
  
  return(x)  
}

sp2namex <- function(spname, trim_subgen=TRUE) {
  chkver <- as.numeric(as.character(packageVersion("odbapi")))
  #print(paste0("check odbapi version: ", chkver))
  if (!is.na(chkver) & chkver >= 0.73) {
    #odbapi got bugs need modified(20210815) if "Aetideopsis armata (Boeck, 1872)" and use simplify_two = T, trim.subgen = trim_subgen
    #modified: odbapi 0.74 version is ok 20210906
    xsp2 <- odbapi::sciname_simplify(spname, simplify_two = T, trim.subgen = trim_subgen) #note that odbapi_v073 has trim.subgen
    #xsp2 <- odbapi::sciname_simplify(spname, simplify_two = T)
    #xsp2 <- odbapi::sciname_simplify(xsp2, trim.subgen = trim_subgen)
  } else {
    xsp2 <- odbapi::sciname_simplify(spname, simplify_two = T)
  }
  return(xsp2)
}

italics_wordx <- function (x, skip_word="", subto=nchar(x), append="", include="") {
  xs1 <- substr(x, 1, subto)
  xs2 <- ""
  if (skip_word==""|grepl(skip_word, xs1)) {
    xst <- trimx(gsub(skip_word, "", xs1))
    if (nchar(xst) < nchar(xs1)) {
      xs2 <- substr(xs1, nchar(xst)+1, nchar(xs1))
    } 
    if (xs2 !="" & include != "") {
      xs2 <- gsub(include, "<em>\\1</em>", xs2) #### Note include should be a string like "(aaa|bbb|ccc)"
      return (paste0("<em>", xst, "</em>", xs2, append))
    } else if (xs2 =="" & include != "") {
      xst <- gsub(include, "<em>\\1</em>", xst)
      return (paste0(xst, append))
    }
  } else {
    return (paste0("<em>", xs1, "</em>", append))
  }
}

italics_spname <- function(xstr, spname, genus="") {
  if (is.na(spname) | trimx(spname)=="") return (xstr)
  xsp2 <- sp2namex(spname)
  xspt <- sp2namex(spname, trim_subgen=FALSE)
  xsp1 <- odbapi::sciname_simplify(spname, simplify_one = T) #get a old alternative spname in caption
  spe_gen <- unique(c(xsp1, Special_genus))
  
  if (is.na(genus) | genus=="") {
    genus <- xsp1
  }
  only_genus_flag <- FALSE
  if (genus == xsp2) {
    only_genus_flag <- TRUE
  }
  
  if (only_genus_flag) {
    return ( #gsub(genus, paste0("<em>",genus,"</em>"),xstr))
      # for adding notation after titletxt #Pseudodiaptomus 
      italics_wordx(xstr, include= paste0("(",paste0(spe_gen, collapse="|"),")"))
    )
  }
  
  chk_sp1 <- regexpr(gsub("\\s","\\\\s",gsub("\\)","\\\\)",gsub("\\(","\\\\(",spname))),xstr)
  chk_sp2 <- regexpr(gsub("\\s","(\\\\s|\\\\s\\\\((?:.*)\\\\)\\\\s)",xsp2),xstr) #match e.g. Acartia (Acartiura/whatever) hongi
  chk_sp3 <- regexpr(gsub("\\s","\\\\s",gsub("\\)","\\\\)",gsub("\\(","\\\\(",xspt))),xstr)
  #chk_gsp <- regexpr(paste0("(A|a)s\\s",xsp1,"(\\s[a-z]{1,}(\\s|\\.))"),xstr) #if detect "As Acartia hongi" substr need +3
  #special genus pattern #"Euaetideus"
  chk_gsp <- gregexpr(paste0("(", paste(spe_gen, collapse="|"),")(\\s[a-z]{1,}(\\s|\\.))"),xstr)
  chk_abbrev <- gregexpr(paste0(substr(gen_name, 1, 1),"\\.\\s[a-z]{3,}(?!(\\s|\\.|\\(|\\)|\\,|\\:|$))"), xstr, perl = T)
   
  if (chk_sp1<0 & chk_sp2<0 & chk_sp3<0 & chk_gsp[[1]][1]<0 & chk_abbrev[[1]][1]<0) return(xstr)
  
  str1 <- xstr
  xspx <- c()
  if (chk_abbrev[[1]][1]>0) {
    for (i in seq_along(chk_abbrev[[1]])) {
      xspx <- c(xspx, substr(str1, chk_abbrev[[1]][i], chk_abbrev[[1]][i]+attributes(chk_abbrev[[1]])$match.length[i]))
    }
    for (x in unique(xspx)) {
      str1 <- gsub(paste0("(?!\\_)",gsub("\\)","\\\\)",gsub("\\(","\\\\(",x)),"(?!\\_)"), paste0("<em>",x,"</em>"), str1, perl = T)
    }
    chk_gsp <- gregexpr(paste0("(", paste(spe_gen, collapse="|"),")(\\s[a-z]{1,}(\\s|\\.))"), str1)
  }
  
  if (chk_gsp[[1]][1]>0) {
    xspx <- c()
    for (i in seq_along(chk_gsp[[1]])) {
      xspx <- c(xspx, substr(str1, chk_gsp[[1]][i], chk_gsp[[1]][i]+attributes(chk_gsp[[1]])$match.length[i]-2) %>% #if detect "As Acartia hongi" substr need +3
        tstrsplit("\\s") %>% unlist(use.names = F))
    }  
    for (x in unique(xspx)) {
      str1 <- gsub(paste0("(?!\\_)",gsub("\\)","\\\\)",gsub("\\(","\\\\(",x)),"(?!\\_)"), paste0("<em>",x,"</em>"), str1, perl = T)
    }
  }

  if (chk_sp2>0) { #Some text use different subgen in citation that make exactly match A (subgen) epi not work
    xspx2 <- substr(xstr, chk_sp2, chk_sp2+attributes(chk_sp2)$match.length-1) %>%
      tstrsplit("\\s") %>% unlist(use.names = F)
    if (length(xspx)==0 | !all(xspx2 %chin% unique(xspx))) {
      for (x in xspx2) {
        str1 <- gsub("<em><em>", "<em>", gsub("</em></em>", "</em>",
                                         gsub(paste0("(?!\\_)",gsub("\\)","\\\\)",gsub("\\(","\\\\(",x)),"(?!\\_)"), paste0("<em>",x,"</em>"), str1, perl = T)))
      }
    }
  } else {
    xspx2 <- unique(xspx)
  }

  xspx3 <- unlist(tstrsplit(xspt, "\\s"), use.names = F)
  if (!identical(xspx2, xspx3)) {
    if (chk_sp1>0 | chk_sp3>0) {
      for (x in xspx3) { #key_Acartia_40b cannot be inserted with <em>
        str1 <- gsub("<em><em>", "<em>", gsub("</em></em>", "</em>",
                     gsub(paste0("(?!\\_)",gsub("\\)","\\\\)",gsub("\\(","\\\\(",x)),"(?!\\_)"), paste0("<em>",x,"</em>"), str1, perl = T)))
      }
    }
  }
  str2 <- gsub("<\\/em>\\s<em>", " ", str1)
  return(str2)
}

check_sex_info <- function (x) {
  if (grepl("((?:(\\s|\\b|\\.|\\;|\\:|\\,)+)(M|m)ale)|(^(M|m)ale)", x)) {
    if (grepl("(F|f)emale", x)) {
      fsex <- "female/male"
    } else {
      fsex <- "male"
    }
  } else if (grepl("(F|f)emale", x)) {
    fsex <- "female"
  } else {
    fsex <- NA_character_
  }
  return(fsex)
}

bold_spsex <- function(xstr) { #only match Male or Female
  chk_male <- regexpr("(\\s|\\.)Male",xstr) #gregexpr #may have multiple Male/Female
  chk_female <- regexpr("(\\s|\\.)Female",xstr)
  if (chk_male<0 & chk_female<0) return(xstr)
  
  if (chk_male>0) {
    #str1 <- paste0(substr(xstr, 1, chk_male), "<strong>Male</strong>",
    #               substr(xstr, chk_male+attributes(chk_male)$match.length, nchar(xstr)))
    str1 <- gsub("\\sMale", " <strong>Male</strong>", gsub("\\.Male", ". <strong>Male</strong>", xstr))
  } else {
    str1 <- xstr
  }
  #chk_female <- regexpr("(\\s|\\.)Female",str1)
  if (chk_female>0) {
    str1 <- gsub("\\sFemale", " <strong>Female</strong>", gsub("\\.Female", ". <strong>Female</strong>", str1))
    
    #str1 <- paste0(substr(str1, 1, chk_female), "<strong>Female</strong>",
    #               substr(str1, chk_female+attributes(chk_female)$match.length, nchar(str1)))
  }
  return(str1)
}

# In figure info extraction, test twice for find_subfigx(), but
# in first time(during find fig_title, just test if have caption but no fig title provided), don't print warning that confuse debugging
find_subfigx <- function(xstr, subfig, idx, print_info=TRUE) {
  xsubf <- subfig[idx]
  subfx <- trimx(gsub("\\((?:.*)\\)", "", subfig[idx:length(subfig)]))
  chk_abc_flag <- FALSE
  chk_traits <- FALSE
  length_traits <- 0L
  xt <- NA
  #traitstr <- paste0("(",paste0(Traits, collapse="|"), ")")
  if (all(grepl(traitstr, subfx))) {
    chk_traits <- TRUE
    length_traits <- length(subfx)
  } else if (length(subfx)>=3 & all(grepl(traitstr, subfx[1:(length(subfx)-1)]))) { 
    #if only last subfig not trait, sometimes, e.g. Original, let it pass #Pseudodiaptomus serricaudatus
    chk_traits <- TRUE
    length_traits <- length(subfx)-1
  }
  if (chk_traits) {
  #if (all(grepl(traitstr, subfx))) { #| #Tried to modify it to match both Female/Male with Traits, But temporarily not do it #Centropages gracilis
      ################################ Because we may lost Female/Male info, which would only in 1st xseg ###     
      #(any(grepl(traitstr, subfx)) & all(grepl("^(F|f)emale|^(M|m)ale", subfx[!grepl(traitstr, subfx)])))) {
    #chk_traits <- TRUE
    xt <- sapply(subfx[1:length_traits], function(x) {
      #gsub("(\\s|\\\\s)*\\(((F|f)emale|(M|m)ale)\\)$", "", 
      gsub("\\s", "\\\\s", gsub("\\,", "\\\\,", gsub("\\-", "\\\\-", gsub("\\/", "\\\\/",
        gsub("(?:\\/)([a-zA-Z]{1})([a-zA-Z]+)", "/(\\U\\1|\\L\\1)\\2", #make "abc/att/Mtt" -> "abc/(A|a)tt/(M|m)tt"                                                                
        gsub("(?![a-zA-Z]+)(\\-|\\/)(?![a-zA-Z]+)", "", #to match Figs 113-116, 11/12 to integer, we don't match "-", "/", even in traits
        paste0("(", toupper(substr(x,1,1)), "|", tolower(substr(x,1,1)), ")",
             substr(x, 2, nchar(x))), perl=T), perl=T))))) #))
    }, simplify = T, USE.NAMES = F)
    #if (length_traits < length(subfx)) { #so that it can match both Traits/other attr, e.g. subfig = "Habitus (Female)" "Mouth parts" "Legs"  "Male"
    #  xt[length_traits+1] = subfx[length_traits+1] #But NOTE: it has risk that xseg may have wrong segments or wrong sex info that should check it.
    #}
    print(paste0("Note particularily: Use Traits as subfig: ", paste0(xt, collapse=",")))
  }
  
  if (grepl("^\\*", subfx[1])) {
    iprex <- "*"
    iprext <- "\\*"
    subx <- subfx
  } else {
    if (all(grepl("Taf\\.", subfx))) {
      iprex <- "Taf."
    } else if (grepl("(f|F)igs\\.", subfx[1])) {
      if (any(grepl("(f|F)ig\\.", subfx))) {
        iprex <- "Fig(s)*."
      } else {
        iprex <- "Figs."
      }
    } else {
      if (any(grepl("(f|F)igs\\.", subfx))) {
        iprex <- "Fig(s)*."
      } else {
        iprex <- "Fig."
      }
    }
    xstr <- gsub("\\sfig\\.", " Fig.", gsub("\\sfigs\\.", " Figs.", 
            gsub("\\spl\\.", " Pl.", gsub("\\splate", " Plate", xstr))))
    if (any(grepl("Plate|Pl\\.", subfx))) {
      if (grepl("\\sPlate", xstr)) {
        iprex <- "Plate"
      } else if (grepl("\\sPl.", xstr)) {
        iprex <- "Pl."
      } else {
        if (print_info) {
          # ##when just check a fig title is a caption or not, it cause error!! replace iprex to '' is dangerous!!  
          stop(paste0("Error: Check it!! Detect Plate as subfig but NO Plate, Pl. in xstr, use empty prex: ", xstr))
          #iprex <- ""
        }
      }
      if (any(!grepl("Plate|Pl\\.", subfx))) { subfx <- subfx[grepl("Plate|Pl\\.", subfx)]}
      subx <- gsub("Plate|Pl\\.", iprex, subfx)
      xsubf <- subx[1] #not idx, not subfx is subset of subfig
    } else {
      if (identical(subfx, LETTERS[1:length(subfx)])) {
        chk_abc_flag <- TRUE
        xt <- subfx
        iprex <- ""
      }
      subx <- subfx
    }
    iprext <- gsub("\\.", "\\\\.", iprex) #the following, also can match 20d (John, 1999. plate 24)
  }
  
  if (!chk_abc_flag & !chk_traits) {
    xt <- as.integer(trimx(gsub("(?![0-9]+)[a-z]*", "", 
                           gsub("\\s*\\((?:.*)\\)", "", 
                           gsub("\\-", "", #20211017 to handle Figs. 79-92 subfig, make it to match 7992
                           gsub(iprext, "", xsubf))), perl=T))) ## some subfig with: 1 (John, 1999. plate 24)
  }
  if (!is.na(xt[1]) | chk_abc_flag | chk_traits) {
    if (!chk_abc_flag & !chk_traits) {
      xt <- as.integer(trimx(gsub("(?![0-9]+)[a-z]*", "", 
                             gsub("\\s*\\((?:.*)\\)", "",
                             gsub("\\-|\\/", "", #20211017 to handle Figs. 79-92 or Figs. 12/14 subfig, make it to match 7992
                             gsub(iprext, "", subx))), perl=T)))
    }
    if (any(is.na(xt))) {
      xt <- xt[!is.na(xt)]
    }
    if (length(xt)>0 & all(!is.na(xt))) {
      if (print_info) print(paste0("Note: Detect muti-subfigures: ", xsubf,", use ", ifelse(chk_abc_flag | chk_traits, "", iprex), " ", paste(subx, collapse=",")))
      xc <- sapply(xt, function(x) {regexpr(
              ifelse(chk_traits, x,
                ifelse(chk_abc_flag, paste0(x, "\\."), #20211020 handle A, B, C subfig and check A., B., C. in xstr 
                  paste0(iprext,"*\\s*",x))),  #20211017 to handle Figs. 79-92 subfig, make it to match 7992
                   gsub('(?![a-zA-Z]+)(\\-|\\/)(?![a-zA-Z]+)', '', xstr, perl=T))},
                   simplify = T, USE.NAMES = F)
      if (!all(xc>0)) {
        if (print_info) { ### Note print_info is a special mode that actually exec find_subfig, not only check
          print(paste0("Warning: Detect multi subfigs but not all found: ", 
                       paste(subfx, collapse=","), " and founded: ", paste(xc, collapse=","), 
                       " Check this str: ", xstr))
          xc <- xc[xc>0]
        }
      }
      return (xc)
    } else {
      if (print_info) {
        stop(paste0("Error: Detect integer: ", xsubf,", But CANNOT use Fig. ", paste(subfx, collapse=","),
                     " Check this str: ", xstr)) #Use default (the following) matching, then
      }   
    }
  }
  
  if (grepl("\\&|\\/|\\(", xsubf)) { #20211020 modified to match Female (Original)
    if (print_info) print(paste0("Note: Detect multiple name in subfig: ", xsubf,", use first: ", gsub("\\s*(\\&|\\/){1}(?:.*)+$", "", xsubf)))
    xsubf <- gsub("\\s*(\\&|\\/|\\(){1}(?:.*)+$", "", xsubf)
  }
  if (grepl("^[A-Z]{1}[a-z]+(?:.*)\\.*\\,*\\s*[0-9]{4}$", xsubf)) { #match Zac et al, 1976 but caption may has T.Zac, A. ooxx, 1976
    xsubfx <- gsub("(?![A-Z]{1}[a-z]+)(\\s|\\.|\\,)(?:.*)\\.*\\,*\\s*(?=[0-9]{4}$)", "(?:.*)",gsub("\\s*\\,\\s*", ", ", xsubf), perl=T) 
  } else {
    xsubfx <- gsub("\\s*\\,\\s*", ", ", xsubf)
  }
  if (grepl("(\\s)*et\\sal(\\.)*(\\,)*(\\s)*", xsubf)) {
    xsubfx <- gsub("(\\s)*et\\sal(\\.)*(\\,)*(\\s)*", "((\\\\s)*et\\\\sal(\\\\.)*(\\\\,)*(\\\\s)*)*", xsubfx)
  }

  if (length(subfx)>1 & ##20211102 Fig. 4A-E/G/H Fig. 4I-L/N/O #Pseudodiaptomus inopinus
      all(grepl("^Fig(s)*\\.", subfx))) {
    xc <- sapply(subfx, function(x) {regexpr(x, xstr)}, simplify = T, USE.NAMES = F)
    if (!all(xc>0)) {
      if (print_info) { ### Note print_info is a special mode that actually exec find_subfig, not only check
        print(paste0("Warning: Detect multi subfigs with 'Fig.' but not all found: ", 
                     paste(subfx, collapse=","), " and founded: ", paste(xc, collapse=","), 
                     " Check this str: ", xstr))
        xc <- xc[xc>0]
      }
    }
    return (xc)
  } else if (length(subfx)>1 & ##20211020 modified: Female/Male subfig comes out in single caption
  #chk_sub <- regexpr(paste0("(?=([A-Z]{1,1}\\.*\\s*){0,1})", xsubf), xstr, perl = T)
       #((grepl("^(F|f)emale", xsubfx) & grepl("^(M|m)ale", subfx[2])) |
       #(grepl("^(M|m)ale", xsubfx) & grepl("^(F|f)emale", subfx[2])))){ 
       all(grepl("^(F|f)emale|^(M|m)ale", subfx))) {
    xt <- gsub("(F|f)emale", "(F|f)emale", subfx)
    xt <- gsub("^(M|m)ale", "(M|m)ale", xt) #((?:(\\s|\\b|\\.|\\;|\\:|\\,)+)|^)(M|m)ale
    xt <- gsub("\\:", "\\\\:", gsub("\\.", "\\\\.", gsub("\\,", "\\\\,", gsub("\\;", "\\\\;", gsub("\\s", "\\\\s", xt)))))
    return(sapply(xt, #c("(F|f)emale", "(?:(\\s|\\b|\\.|\\;|\\:|\\,)+)(M|m)ale"), 
                  function(x) {regexpr(x, xstr)}, simplify = T, USE.NAMES = F))
  } else if (grepl("^(F|f)emale", xsubfx)) {
    return(regexpr("(F|f)emale", xstr))
  } else if (grepl("^(M|m)ale", xsubfx)) { #for subfig like "Ohtsuka et al."
    return(regexpr("(?:(\\s|\\b|\\.|\\;|\\:|\\,)+)(M|m)ale", xstr))
  }
  if (substr(xstr, 1, 3) == substr(iprex, 1, 3) | substr(xstr, 1, nchar(xsubf)) == xsubf) {
    return(regexpr(paste0("^(([A-Z]\\.(\\-[a-z]\\.*)*\\s*){0,})",   #also can match Q.-c Chen or Q. C. Chen
             xsubfx), xstr)) #make Sewell,1914 -> Sewell, 1914
  }
  return(regexpr(#20211017 to match "Shih et al. 1981: figs. 79-92. 
           paste0("^((([A-Z]\\.(\\-[a-z]\\.*)*\\s*){0,})|([A-Za-z]+\\,*\\s*(et al)\\.*\\,*\\s*[0-9]+(\\:|\\.)\\s*)}{0,})",
             xsubfx), xstr)) 
}

###############################################################################################
#### Used to store figs <-> fig_file mapping
dfk <- data.table(fidx=integer(), 
                  fkey=character(), ckeyx=character(),
                  imgf=character(), fsex=character(), 
                  main=character(), title=character(),
                  subfig=character(), caption=character(), citation=character(),
                  flushed=character(), ## flushed means flush figs in a row
                  blkx=integer(), docn=integer(), rid=character(), ### blkx: counter of block of fig, docn: nth document
                  kcnt=integer(), tokcnt=integer(), page=integer(), ## tokcnt: correspond to kcnt in dtk
                  xdtk=character(), taxon=character(), subgen=character(),
                  genus=character(), family=character()) #rid link to dtk, xdtk link to key of dtk

#Note: figs is type=2 ## 20211109 try convert keystr to json
#20220412 modified for tree lookup: convert pkey to json {unikey: previous_unikey}

dtk <- data.table(rid=integer(), unikey=character(), ckey=character(), 
                  subkey=character(), pkey=toJSON(character()),
                  figs=character(), type=integer(), nkey=integer(), 
                  taxon=character(), abbrev_taxon=character(), fullname=character(),
                  subgen=character(), genus=character(), family=character(), 
                  epithets=character(), keystr=toJSON(character()), ctxt=character(), fkey=character(),
                  sex=character(), docn=integer(), kcnt=integer(), #counter of key+fig to split page
                  page=integer())
dtk <- dtk[-1]

doclst <- list.files(key_src_dir, pattern="^Key?(.*).docx$",full.names = T)
cntg <- 0L
cntg_fig<- 0L
blk_cnt <- 0L
page_cnt<- 1L
pre_kcnt<- 0L
keycnt <- 0L
handle_xx_fig <- c() ## Handled lost link xx_fig sp, which had been handled by replace ctxt by epitxt_new with figure link
#docfile <- doclst[1]

for (docfile in doclst) {
  dc0 <- read_docx(docfile) ######################## 20191014 modified
  ctent <- docx_summary(dc0)
  key_chk_flag <- TRUE ## FALSE: means no key, only figs in this doc by means of 
  key_chk_pat <- "Key to the species of " # setting correct start pattern in a docx
  Male_only_sp <- c() ### 20211102 add to force these sp to Male
  Female_only_sp <- c() # 20211102 add to force these sp to Female #Rhincalanus 
  
  fn <- tstrsplit(docfile, "/") %>% .[[length(.)]]
  lfn <- regexpr("^(Key to the species of\\s)(?:[a-zA-Z]{1,})\\s", fn)
  fam_name <- substr(fn, nchar('Key to the species of ')+1, lfn+attributes(lfn)$match.length-2L)
  fnt<- paste0('^(Key to the species of ', fam_name, '\\s)(?:[a-zA-Z]{1,})\\s')
  lfn <- regexpr(fnt, fn)                   
  gen_name <- substr(fn, nchar(paste0('Key to the species of ', fam_name, ' '))+1, 
                     lfn+attributes(lfn)$match.length-2L)
  
  lfn <- regexpr("^(Key to the species of\\s)(?:[a-zA-Z]{1,})\\s", ctent[1,]$text)
  if (lfn<0) {
    lfn <- regexpr("^(The species of\\s)(?:[a-zA-Z]{1,})\\s", ctent[1,]$text)
    if (lfn<0) {
      print(paste0("Error! We cannot get a correct start: ", gen_name))
      break
    }
    key_chk_flag <- FALSE
    key_chk_pat <- "The species of "
  }
  gen_chk <- substr(ctent[1,]$text, nchar(key_chk_pat)+1, lfn+attributes(lfn)$match.length-2L)
  
  if (gen_chk == gen_name) {
    print(paste0("Now we got genus: ", gen_name, " to start..."))
    cntg <- cntg+1L
    
  } else {
    print(paste0("Genus name not right check: ", gen_name, " before starting!"))
    break
  }

  i <- 2  
  xt <- read_docx_row(ctent$text[i])
  if (xt=="") {
    i <- i+1
    xt <- read_docx_row(ctent$text[i])
    if (xt=="") {
      stop(paste0("Error: cannot read epi_list, check format: ", docfile))
      break
    }
  }
  i <- i+1
  
  #20210903 modifed: New version after 0902 add epi_link after epithets i.e. (Acanthoarcartia) bifilosa(35a/40a/f)
  #  so need to detect (?=[^0-9]) not a epi_link
  #epithets list #insert spacing between (subgenus)epithets,epithets
  epi_list <- trimx(gsub("\\s\\.", ".", gsub("\\s\\,", "\\,", 
              gsub("(?![^\\,\\.])\\s*(?!^\\()(?![a-zA-Z]{1,})\\((?=[^0-9])", ", (",
              gsub("(?![a-zA-Z]{1,})\\)(?=[^\\,\\.])", ") ",     
              gsub("(?![a-zA-Z]{1,})\\,", ", ",xt, perl=T), perl=T), perl=T))))
  epithets <- unlist(tstrsplit(gsub("\\(\\*(?:.*)\\)|\\(f\\)|\\*", "", ##(trim remark by *)
                                    epi_list), "(\\,|\\.)\\s*"), use.names = F) %>%
    sapply(function(x) {trimx(gsub("\\,$","",gsub("\\([0-9]+(?:.*)\\)(\\.|\\,|\\s|$)", ",", 
                              gsub(paste0("(?!\\()", gen_name, "(?!\\))"), "", x, perl = T)))) 
    },simplify = T, USE.NAMES = F) %>% paste0(collapse=", ")#Some (Subgen) == gen_name cannot be filtered
  #for example: c("(Acartia) abc", "Acartia ddd") -> "(Acartia) abc" "ddd" 
  epithets <- trimx(gsub("\\,\\s*$", "", epithets))
  
  epistr <- paste0("(", gsub("\\(", "\\(\\\\(", 
                        gsub("\\)\\s", "\\\\)\\\\s\\)\\*",
                        gsub("\\,\\s", "|", epithets))), ")") #"(crassus|dentatus|longiceps....)"
  
  titletxt <- gsub(paste0(gen_name,"<\\/em>\\soccur"),
                   paste0(gen_name, '</em> ', '<a aria-label=', dQuote('back to the genus key'),
                          ' href=', dQuote(paste0('#taxon_',gen_name)),
                          '>&#9754;</a> occur'), ## add a posix 'occur' to ensure this paste-gsub only do once, (i.e don't do it twice) 
              paste0("<div id=", dQuote(paste0("genus_",gen_name))," class=", dQuote("kblk"), "><p class=", dQuote("doc_title"), ">", 
                italics_spname(gsub("(in\\sChina\\ssea(s)*|\\(China\\ssea(s)*\\))(\\:)*", "occurring in the China seas", ctent[1,]$text), gen_name, gen_name), "</p></div><br><br><br>")
              )
  if (grepl("\\(\\*(F|f)emale\\sonly\\)$", epi_list)) {
    Female_only_sp <- "all"
  } else if (grepl("\\(\\*(M|m)ale\\sonly\\)$", epi_list)) {
    Male_only_sp <- "all"
  }  
  #If no key in this doc(i.e. only figs, and only one species in this genus), we'll
  #let #span id="taxon_species_name" in this epithet span
  nota_wl <- regexpr("\\(\\*(?:.*)\\)\\s*$", epi_list)
  nota <- ""
  if (nota_wl>0) {
    nota <- substr(epi_list, nota_wl, nchar(epi_list))
    epi_list <- substr(epi_list, 1, nota_wl-1)
  } 
  epitxt <- paste0(titletxt, "<div id=", dQuote(paste0("species_",gen_name))," class=", dQuote("kblk"), "><p class=", dQuote("doc_epithets"), 
    ifelse(key_chk_flag,">", paste0(" id=", dQuote(paste0("taxon_",gen_name,"_", gsub("\\s*\\(.*\\)\\s*", "", epi_list))), ">")), 
    paste0(unlist(tstrsplit(epi_list, "(\\,|\\.)\\s*"), use.names = F) %>%
      sapply(function(x) {
        wl1 <- regexpr("\\([0-9](?:.*)\\)", x)
        xtx <- ""
        if (wl1>0) {
          xt1 <- substr(x, wl1, nchar(x))
          wl2 <- gregexpr("(?!(\\(|\\/))[0-9]+[a-z]{1}", xt1, perl=T)
          # 20210903 modified: "(38a/40b/f)" -> "(<a href="key_Acartia_38a">38a</a>/<a href="key_Acartia_40b">40b</a>/f)"
          if (wl2[[1]][1]>0) {
            xtx <- substr(xt1, 1, wl2[[1]][1]-1)
            for (y in seq_along(wl2[[1]])) {
              xtx <- gsub("\\s\\*", "*", ## sometimes has * to remark
                       paste0(xtx, paste0("<a href=",dQuote(paste0("#key_",gen_name,"_",substr(xt1, wl2[[1]][y], wl2[[1]][y]+attributes(wl2[[1]])$match.length[y]-1))),
                            ">",substr(xt1, wl2[[1]][y], wl2[[1]][y]+attributes(wl2[[1]])$match.length[y]-1),"</a>"),
                            ifelse(y<length(wl2[[1]]), 
                              substr(xt1, wl2[[1]][y]+attributes(wl2[[1]])$match.length[y], wl2[[1]][y+1]-1),
                              substr(xt1, wl2[[1]][y]+attributes(wl2[[1]])$match.length[y], nchar(xt1)))))
            }  
          } else { #if (!key_chk_flag) { #no key but may have (1/f) pattern
            xtx <- xt1
          }
          #paste0("<em>", substr(x, 1, wl1-1), "</em>", xtx) 
          italics_wordx(x, "\\((fe)*male\\sunknown\\)\\s*", wl1-1, xtx)
        } else {
          #paste0("<em>", x, "</em>")
          italics_wordx(x, "\\(\\*(?:.*)\\)(\\s|\\,|$)", nchar(x), "")
        }
      }, simplify = T, USE.NAMES = F) %>% paste(collapse=", "),
      italics_wordx(nota, "", nchar(nota), include=epistr)), 
    ifelse(!key_chk_flag, paste0(" (<a href=",dQuote(paste0("#fig_",gen_name,"_", gsub("\\s*\\(.*\\)\\s*", "", epi_list))), ">figure</a>)"),""),
    "</p></div><br><br><br>\n\n")
    
  keycnt <- keycnt + 1L
  
  dtk <- rbindlist(list(dtk,data.table(rid=0, unikey= paste0(gen_name, "_00a_genus"), #to make its order in the first, #paste0("genus_", gen_name), 
                              ckey= NA_character_, subkey= NA_character_, pkey=toJSON({}), #NA_character_,
                              figs=NA_character_, type=-1, nkey=NA_integer_, 
                              taxon=NA_character_, abbrev_taxon=NA_character_, fullname=NA_character_,
                              subgen=NA_character_, genus=gen_name, family=fam_name, epithets=epithets, 
                              #keystr=NA_character_,
                              keystr=toJSON({}),
                              ctxt=epitxt, fkey=NA_character_, 
                              sex=NA_character_, docn=cntg, kcnt=keycnt, page=page_cnt)))
  tstL <- nrow(ctent)

  epiall <- trimx(gsub("\\((?:.*)\\)", "", unlist(tstrsplit(dtk[rid==0 & genus==gen_name & family==fam_name,]$epithets, ","), use.names = F)))
  epiall <- epiall[epiall!="*"]
  if (any(grepl("[^[:alnum:][:space:]]+", epiall))) {
    stop(paste0("Syntax Error in genus: ", gen_name, " ", paste(epiall, collapse=", ")))
    break
  } else {
    print(paste0("We have these sp: ", gen_name, " ", paste(epiall, collapse=", ")))
  }

  #i = skipLine+1L
  st_conti_flag <- FALSE
  keyx <- ""; prekeyx <- ""; subkeyx <- ""
  pret <- ""
  subgenk <- ""
  keystr <- ""
  nxtk <- 0L; nxttype <- 0L; #0: integer key, 1: sp name 
  nsp <- ""; xsp <- ""; epithet <- ""
  withinCurrKey <- FALSE
  kflag <- FALSE
  ncflag <- 0L
  fig_mode <- FALSE
  #tstL=40 (key 9b) #181-> 194(sp list end, next is fig) #28 (first end sp.) #18 (next fist st_config_flag)
  female_start <- -1
  male_start <- -1
  xsex_flag <- FALSE #during sex decision key splitting, don't decide sex
  #init_flag <- TRUE #just a flag to initially <div> to replace skipLine+1
  doc_fign<- 0 ## cntg_fig is counter of all fig num in total docs (stored in fig_num), doc_fign just for one doc file
  docfn <- unlist(tstrsplit(docfile, "\\/"), use.names = F) %>% .[length(.)]
  imgdir <- paste0(doc_imgdir, 
                   gsub("\\s", "_", gsub("Key to the species of\\s|\\s\\(China sea([s]*)\\s*[2]*\\)\\.docx", "", docfn)),
                   "/word/media")
  imgfiles <- list.files(imgdir, pattern="jpeg$", full.names = TRUE, recursive = FALSE)
  imgfileL <- length(imgfiles) #modified 2022/4/2 for checking if fig_num == imgfileL, to check if any one lost
  if (imgfileL==0) {stop(paste0("Error: No img files existed for this genus: ", gen_name))} 
  cur_key_cnt <- 0 ## current key number counter (not include epitext, so less 1 than actual total key)
  
  while (i<=tstL) {
    x <- read_docx_row(ctent$text[i], nocheck = TRUE)

    tt <- which(is.na(x) | x=="")
    if (any(tt)) {
      ncflag <- ncflag + 1
      if (ncflag >=31 ) { # exceed one page of docx
        print(paste0("Warning: Too many NuLL rows, check it at i: ", i))
        fig_mode <- TRUE
        ncflag <- 0L
        break
      }
      if (i<tstL) {
        i <- i+1
        next
      } 
    } else {
      wl0 <- regexpr("^[A-Z][a-z]{1,}",x)
      if (wl0==1 & nrow(dtk)>0) { #& ncflag>=1) {
        print(paste0("Note: Now handle Figures at i: ", i))
        fig_mode <- TRUE
        ncflag <- 0L
        break
      }
      ncflag <- 0L;
      if (!st_conti_flag) {
        #stcnt <- 1L; wcnt <- 0L #word count, #stcnt: pointer where to start to catch key in a statement 
        #figx <- NA_integer_; fidx_dup <- NA_integer_ ## some duplicated fig_ling but link to the same fig file
        #pret_case <- 0L # 1L: fig. xx-yy and display in block of main-column
        #xf <- NA_character_
        #xsex<- NA_character_; body <- NA_character_; keyword <- NA_character_
        #cnt_rst_flag <- FALSE; ###### counter reset flag if the page had only few figs so idx1=0 idx2=0 not exhaust pgRemain
      
        ## detect primary key, such as "1a" or "1a/1b"
        x1 <- x; x2<-x
        
        wl <- regexpr("^[0-9]{1,}[0-9a-z\\/]{1,}(?=\\s|[A-Z])",x, perl=T)
      
        if (attributes(wl)$match.length>0) {
          keyx <- substr(x,wl,wl+attributes(wl)$match.length-1)
          stopifnot(!any(is.na(keyx))) ## because HTML no more support <a name...> for anchor, we use font id to be catched
          
          cur_key_cnt <- cur_key_cnt + 1L
          if (grepl("\\/", keyx)) {
            prekeyx <- tstrsplit(keyx, "/")[[2]]
            keyx <- tstrsplit(keyx, "/")[[1]]
          } else {
            prekeyx <- ""
          }   
        
        ## 202109 New version need not </div> because img would not flushed between <div></div>  
          #if (init_flag) { #i== skipLine+1L) { #key 1a will repeat in New Version for different genus, must prevent duplication
            pret <- paste0('<div class=', dQuote('kblk'), '><p class=', dQuote('leader'), 
                           '><span class=',dQuote('keycol'),'>',
                           '<mark id=', dQuote(paste0('key_', gen_name, "_", keyx)), '>', keyx, '</mark>')
          #  init_flag <- FALSE
          #} else {
            ### 20191015 modified to put </div> in previous dtk, so I can flush image earilier because <div>...</div> cannot be broken
            ### dtk[nrow(dtk), ctxt:=paste0(ctxt,'</div>')] ## previous change is wrong because maginnote should be inside <div>..</div>
          #  pret <- paste0(pret,'</div><div class=', dQuote('kblk'), '><p class=', dQuote('leader'), 
          #                 '><span class=',dQuote('keycol'),'>',
          #                 '<mark id=', dQuote(paste0('key_', gen_name, "_", keyx)), '>', keyx, '</mark>')
          #}
          # Use below markdown version??
          if (prekeyx!="") {
          # pret <- paste0(pret, '/<mark id=', dQuote(paste0('key_', prekeyx)), '>', prekeyx, '</mark> ')
            pret <- paste0(pret, '&nbsp;(')
          } else {
            pret <- paste0(pret, "&nbsp;")
          }
          
          stcnt<- nchar(pret)+1L #move pointer to next start in a statment
          x1<- trimx(substr(x,wl+attributes(wl)$match.length, nchar(x)))
          xc<- paste0(pret,x1) #HTML results
          kflag <- TRUE #primary key found
          
          if (prekeyx!="") {
            #using markdown 
            #pret0s <- paste0('[', prekeyx, '](#key_',  gen_name, "_", prekeyx, '))&nbsp;') #note it's a md anchor
            pret0s <- paste0('<a href=', dQuote(paste0('#key_', gen_name, "_", prekeyx)), '>', prekeyx, '</a>)&nbsp;') 
            xc<- paste0(pret, pret0s, x1)
            stcnt <- nchar(pret)+nchar(pret0s) +1L
            pret <- paste0(pret, pret0s)
          }
        } else {
          epix <- trimx(unlist(tstrsplit(x1, ","), use.names = F))
          if (any(epix[!epix %chin% epiall])) {
            print(paste0("Warning! Epithets not match! check it: ", 
                  paste(epix[!epix %chin% epiall], collapse=", "), " in i & key: ", i, " & ", dtk[nrow(dtk),]$unikey))
          } else {
            print(paste0("Find some epithets: ", paste(epix, collapse=", "), " in i & key: ", i, " & ", dtk[nrow(dtk),]$unikey))
            dtk[nrow(dtk), epithets:= paste(epix, collapse=", ")]
          }
          #xc <- paste0('</div>', x1)
          if (gsub("\\s","", paste(epix, collapse=",")) != gsub("\\s", "", x1)) {
            print(paste0("Warning! Epithets not all of the contents. check it: ", 
                         paste(epix, collapse=", "), " in i & key: ", i, " & ", dtk[nrow(dtk),]$unikey))
          }
          withinCurrKey <- TRUE
        }
        x2 <- x1
        
      # detect too-long dots start and subgenus (Acartiura)l, or …Acartia…14,  or …......
      } else { #st_conti_flag
        x2 <- paste0(x1, x) ## a cutted line due to word with too-long dots
      }
        
      if (!withinCurrKey) {
        #mat_subgen1 = paste0("(?:…*\\.*\\s*)((\\()(?:[A-Z][a-z]{1,}(.*)\\))|", 
        #                       "([A-Z])(?:[a-z]{1,}(?:…+|\\.+)))") #20211103 modified for ............Tortanus (Tortanus) barbatus
        mat_subgen1 = paste0("(?:…*\\.*\\s*)(?<!",gen_name,"\\s)\\((?:[A-Z][a-z]{1,}(.*)\\))|",
                             "(?:…+\\.*\\s*)([A-Z])(?:[a-z]{1,}(?:…+|\\.+))")
        # cannot match spacing because may a species name, not subgenus (only one word)
        # i.e. cannot match (but can match ...(Subgenus Euacartia))...)
        # regexpr(mat_subgenus, "of urosomites smooth…………....……………………Euacartia …..28", perl=T)
        # use ?= to get only start position, but here we need length to get whole subgenus
        wl2 <- regexpr(mat_subgen1, x2, perl=T)
      
        if (wl2>0) {
          subgenk <- gsub("\\(Subgenus |\\(Subgen |\\(|\\)|…|\\.|\\s", "", substr(x2, wl2+1, wl2+attributes(wl2)$match.length-1))
          print(paste0("Find Subgenus: ", subgenk, " in i, keyx: ", i, ", ", keyx))
        
          keystr <- trimx(gsub("\\.\\s*$", "", gsub("…|\\.{2,}", "", substr(x2, 1, wl2))))
          pret <- paste0(pret, keystr)
          #pret <- paste0(pret, keystr, '<mark id=',dQuote(paste0('subgen_', subgen)),
          #               '>(*', subgen, '*)</mark>') # star * here make italic in markdown
        
          x2<- paste0("…",substr(x2,wl2+attributes(wl2)$match.length, nchar(x2))) #at least one "…" for the following regex
          xc<- paste0(pret,x2) #HTML results
        }  
      }  
      
      if (!withinCurrKey) {
        #try to find species 
        mat_sp1 = paste0("(?:(…+\\.*\\s*…*|\\.{2,}…*\\s*))(([A-Z])\\.\\s*|", gen_name, "\\s)(\\([A-Z][a-z]{1,}\\)\\s)*[a-z]{1,}$")
        wl3 <- regexpr(mat_sp1, x2, perl=T)
        if (wl3>0) {
          nsp <- gsub("\\.", "\\. ", gsub("^\\.", "", gsub("…|\\.{2,}|\\s(?![\\(\\)a-z]+)", "", substr(x2, wl3+1, nchar(x2)), perl=T))) #equal wl2s+attributes(wl2s)$match.length-1)   
          print(paste0("Find end SP: ", nsp, " in i, keyx: ", i, ", ", keyx, " with equal end: ", nchar(x2)==wl3+attributes(wl3)$match.length-1))
          nxttype <- 1L
          if (substr(nsp,1,2)==paste0(substr(gen_name, 1, 1), ".")) {
            xsp <- gsub("\\s{1,}", " ", gsub(substr(nsp,1,2), paste0(gen_name, " "), nsp))
          } else {
            xt <- odbapi::sciname_simplify(nsp, simplify_one=T)
            if (xt != gen_name) {
              print(paste0("Warning and Check it: Not equal genus name when get end species: ", nsp, " for genus: ", gen_name, " at i: ", i))
              xsp <- gsub(xt, gen_name, nsp)
            } else {
              xsp <- odbapi::sciname_simplify(nsp, simplify_two=T, trim.subgen = T)
            }
          }
          epithet <- gsub(paste0(gen_name, " "), "", xsp)
          if (!is.na(subgenk) & subgenk!=""){
            print(paste0("Note particularily: Both subgen & species exist in one key: ", subgenk, " and sp: ", nsp, " at i: ", i))
            keystr <- paste0(keystr, " (Subgenus ", subgenk, ")")
            pret <- paste0(pret, " (Subgenus ", subgenk, ")")
            Species_groups <- unique(c(Species_groups, subgenk)) #for italic styling of subgenu
            Sp_grps_str <- paste0("(",paste0(Species_groups,collapse="|"),")")
          } else { #Normal situation
            subgenk <- trimx(gsub(paste0(paste0("(?!\\()(",gsub("\\s","|", xsp),")(?!\\))"),"|\\(|\\)"), "",
                                  odbapi::sciname_simplify(nsp, trim.subgen = F, simplify_two = T), perl = T))
            keystr <- gsub("\\.$", "", trimx(gsub("…|\\.{2,}", "", substr(x2, 1, wl3))))
            pret <- paste0(pret, keystr)
          }
        } else {
          wl3 <- regexpr("(?:(…+\\.*\\s*|\\.{2,}…*\\s*))([0-9]+|\\?)$",x2) #genus Paraeuchaeta has uncertain male key #20211031
          
          if (wl3<0) {
            if (!st_conti_flag) {
              st_conti_flag <- TRUE
              i <- i+1
              next
            } else {
              stop("Error: Too many cutted-line! check it!")
              #break
            } 
          }
          nxtstr <- gsub("…|\\.","",substr(x2,wl3+1,nchar(x2)))
          if (nxtstr == "?") {
            nxtk <- NA_integer_
            print(paste0("Warning: Nxtk is ? at i: ", i, " when key: ", keyx, " for genus: ", gen_name))
          } else {
            nxtk <- as.integer(nxtstr)
            stopifnot(!any(is.na(nxtk)))
          }
          nxttype <- 0L
          nxtlink<-ifelse(is.na(nxtk), #if is.na(nxtk), stop at current key
                          paste0('<a href=', dQuote(paste0('#key_', gen_name, "_", keyx)), '>', '?','</a>'),
                          paste0('<a href=', dQuote(paste0('#key_', gen_name, "_", nxtk,'a')), '>', nxtk,'</a>'))
          if (keystr=="") { #no subgen, so no keystr fetched
            keystr <- trimx(gsub("\\.\\s*$", "", gsub("…|\\.{2,}", "", substr(x2, 1, wl3))))
            pret <- paste0(pret, keystr)
          }
        }
        #20211031 add a function to italic species groups
        pret <- italics_wordx(pret, include=Sp_grps_str) 
        
        if (nxttype==1L) {
          if (!is.na(xsex) & xsex %chin% c("female", "male")) {
            marksp <- paste0('taxon_', gsub("\\s","_",xsp),"_",xsex)
          } else {
            marksp <- paste0('taxon_', gsub("\\s","_",xsp))
          }
          xc <- paste0(pret,
                       '</span><span class=',dQuote('keycol'),'>',
                       paste0('<mark id=',  dQuote(marksp), 
                              '><em><a href=', dQuote(paste0('#figs_', gsub("\\s","_", xsp))), '>', nsp, '</a></em></mark></span></p>'))
          
        } else if (subgenk!="" | is.na(nxtk) | nxtk!=0L) { #20211031 add nxtk_str=? #Paraeuchaeta
          if (grepl("\\,", subgenk)) { #with multiple subgenus
            subgx <- trimx(unlist(tstrsplit(subgenk, ","), use.names = F))
            subgenk<- paste(subgx, collapse=", ") #to make format consistently
            
            xc0 <- do.call(function(x) {paste0('<mark id=',dQuote(paste0('subgen_', x)),'><em>', x, '</em></mark>')}, list(subgx)) %>%
              paste(collapse=",&nbsp;")
            
            xc <- paste0(pret, '</span>&nbsp;<span class=',dQuote('keycol'),'>', 
              paste0('(', xc0, ')'),
              #using markdown
              #paste0('[', nxtk, '](#key_', gen_name, "_", nxtk,'a)'), 
              #paste0('<a href=', dQuote(paste0('#key_', gen_name, "_", nxtk,'a')), '>', nxtk, '</a>'), 
              nxtlink, #20211031 modified for nxtk can be ?
              '</span></p>')
          } else {
            xc <- paste0(#gsub("…|\\.{2,}|…\\.{1,}|\\.{1,}…","",
              #ifelse(st_conti_flag, xc, substr(xc,1,nchar(xc)-stt))),
              pret, '</span>&nbsp;<span class=',dQuote('keycol'),'>', 
              ifelse(subgenk=="", "", paste0('<mark id=',dQuote(paste0('subgen_', subgenk)),'>(<em>', subgenk, '</em>)</mark>')),
              #using markdown
              #paste0('[', nxtk, '](#key_', gen_name, "_", nxtk,'a)'),
              #paste0('<a href=', dQuote(paste0('#key_', gen_name, "_", nxtk,'a')), '>', nxtk,'</a>'), 
              nxtlink, #20211031 modified for nxtk can be ?
              '</span></p>')
          }
        } else {
          print("Not found any recognized patterns or key! check it in i: ", i)
          break;
        }
      } else { #use previous key when withinCurrKey
        keyx <- dtk[nrow(dtk),]$ckey
        prekeyx <- dtk[nrow(dtk),]$pkey
      }
      
      keyn <- as.integer(gsub("[a-z]", "", keyx)) 
      subkeyx <- gsub(as.character(keyn), "", keyx)
      if (subkeyx=="") {
        stop(paste0("Error: No Subkey found for keyx: ", keyx, " of genus: ", gen_name, " at i: ", i))
      }
      prekeyn <- as.integer(gsub("[a-z]", "", prekeyx))
      if (is.na(prekeyn)) {
        prekeyn <- 0L
      }

      if (substr(keystr,1,6)=="Female") {
        female_start <- ifelse(is.na(nxtk), 999, nxtk) #for a very large nxtk, so that it never achieve
        xsex_flag <- TRUE
        print(paste0("Note: Female key after: ", nxtk, " of genus: ", gen_name, " at i: ", i))
      }
      if (substr(keystr,1,4)=="Male") {
        male_start <- ifelse(is.na(nxtk), 999, nxtk) #for a very large nxtk, so that it never achieve
        xsex_flag <- TRUE
        print(paste0("Note: Male key after: ", nxtk, " of genus: ", gen_name, " at i: ", i))
      }

      both_sexflag <- substr(keystr, 1, 13) == "In both sexes" 
      xsex <- NA_character_
      if (!xsex_flag & nxttype==1L & both_sexflag) {
        xsex = "female/male"
      } else if (!xsex_flag & nxttype==1L & female_start > 0 & male_start >0) {
        if (female_start > male_start) {
          if (keyn >= male_start & keyn < female_start) {
            xsex = "male"
          } else if (keyn >= female_start) {
            xsex = "female"
          }
        } else if (female_start < male_start) {
          if (keyn >= female_start & keyn < male_start) {
            xsex = "female"
          } else if (keyn >= male_start) {
            xsex = "male"
          }
        }  
      }
      
      #Note that key now is 2a, 10b (but < 100) ..., so need more pad than before        
      #if (keyn>=100 & prekeyn>=100) {
      #  padx = "pad8"
      #  indentx = "indent4"
      #} else if ((keyn>=100 & prekeyn>=10) | prekeyn>=100) {
      #  padx = "pad7"
      #  indentx = "indent3"
      #} else 
      if ((keyn>=100 & prekeyn>0) | (keyn>=10 & prekeyn>=10)) {
        padx = "pad8"
        indentx = "indent4"
      } else if ((keyn>=10 & prekeyn>0) | prekeyn>=10) {
        padx = "pad7"
        indentx = "indent3"
      } else if (prekeyn > 0) {
        padx = "pad6"
        indentx = "indent3"
      #}else if (keyn>=100 & prekeyn==0) {
        #padx = "pad4"
        #indentx = "indent2"
      } else if (keyn>=10 & prekeyn==0) {
        padx = "pad3"
        indentx = "indent2"
      } else {
        padx = "pad2"
        indentx = "indent2"
      }
      
      prekeyx <- ifelse(prekeyx=="", NA_character_, prekeyx)
      nxtk <- ifelse(nxtk==0L, NA_integer_, nxtk) 
      nsp <- ifelse(nsp=="", NA_character_, nsp)
      xsp <- ifelse(xsp=="", NA_character_, xsp)
      subgenk <- ifelse(subgenk=="", NA_character_, subgenk)

      if (!withinCurrKey) {
        if (!kflag) {
          xc <- paste0('<p class=',dQuote(paste0('leader ', indentx)),'><span class=',
                       dQuote(paste0('keycol ', padx)), '>', xc)
        } else {
          xc <- gsub("<p class(.*?)><span", paste0('<p class=',dQuote(paste0('leader ', indentx)),'><span'), xc)
        }
        
        if (is.na(xsex)) {
          if (grepl("(I|i)n female|(F|f)emale\\:\\,", keystr)) {
            xsex <- "female"
          }
          if (grepl("(I|i)n male|(\\s|\\.|^)(M|m)ale(\\:|\\,)", keystr)) {
            xsex <- ifelse(is.na(xsex), "male", "female/male")
          }
        }
        xc <- paste0(xc,'</div>') #202109 no need for delaying output </div> 
        keycnt <- keycnt + 1L
        keyt <- as.integer(gsub('[a-z]','', keyx))
        ukey <- paste0(gen_name, "_", padzerox(keyt, 2), subkeyx)
        ataxon <- ifelse(nxttype==1L & xsp!=gen_name & !any(grepl("\\.", nsp)), 
                         trimx(paste0(substr(gen_name, 1,1), ".",
                                ifelse(!is.na(subgenk) & subgenk!="", paste0(" (",substr(subgenk, 1, 1),".) "), ""),
                                gsub(gen_name, "", xsp))), nsp) #nsp, 
        #20220412 modified for tree lookup
        if (is.na(prekeyx) | prekeyx=="") {
          pkeyt <- toJSON({})
        } else {
          pkeyn <- as.integer(gsub("[a-z]", "", prekeyx))
          pkeys <- gsub("[0-9]", "", prekeyx)
          pkeyt <- toJSON(list(unikey=paste0(gen_name, "_", padzerox(pkeyn, 2), pkeys)))
        }
        dtk <- rbindlist(list(dtk,data.table(rid=i, unikey=ukey, #paste0(gen_name, "_", keyx),
                                             ckey= keyx, subkey= subkeyx, pkey= pkeyt, #prekeyx,
                                             figs=NA_character_, type=nxttype, nkey=nxtk, 
                                             taxon=xsp, 
                                             abbrev_taxon=ataxon,
                                             fullname=NA_character_,
                                             subgen=subgenk, genus=gen_name, family=fam_name,
                                             epithets=NA_character_, 
                                             keystr=toJSON(keystr), #keystr=keystr, 
                                             ctxt=xc, fkey=NA_character_, 
                                             sex=xsex, docn=cntg, kcnt=keycnt, page=page_cnt)))
      } else {
        #202109 no need for delaying output </div>
        xc <- paste0('<div><p class=',dQuote(paste0(indentx, ' lxbot')), '><span class=', 
                     dQuote(padx), '><em>', paste(epix, collapse="</em>, <em>"), '</em></span></p></div>')
        xc0 <- gsub("<p class(.*?)><span", 
                    paste0('<p class=',dQuote(paste0('leader ', indentx, ' lxtop')), '><span'), 
                    dtk[nrow(dtk),]$ctxt)
        dtk[nrow(dtk), ctxt:=paste0(xc0, xc)]
      }
    
      #if (nxttype==1L | subgenk != "" | nxtk != 0L) {
      st_conti_flag <- FALSE
      keyx <- ""; prekeyx <- ""; subkeyx <- ""
      pret <- ""
      subgenk <- ""
      keystr <- ""
      nxttype <- 0L; nxtk <- 0L
      nsp <- ""; xsp <- ""; epithet <- ""
      kflag <- FALSE
      #}
      i = i + 1L
      xsex_flag <- FALSE
      withinCurrKey <- FALSE
    } 
  }
  
  if (key_chk_flag & cur_key_cnt>0) {
    #20211102 added a female/male only flag
    if (length(Female_only_sp) & female_start < 0 & !both_sexflag) {
      print(paste0("Warning! Sex info will be changed. Check it: We find Female_only comment for genus: ", gen_name))
      dtk[genus==gen_name & !is.na(taxon) & type==1L, sex:="female"]
    }
    if (length(Male_only_sp) & male_start < 0 & !both_sexflag) {
      print(paste0("Warning! Sex info will be changed. Check it: We find Male_only comment for genus: ", gen_name))
      dtk[genus==gen_name & !is.na(taxon) & type==1L, sex:="male"]
    }
    
    dtk[nrow(dtk), ctxt:=paste0(dtk[nrow(dtk),]$ctxt, '<br><br>\n\n')] #202109 no need for delaying output </div>
    print(paste0("Checking fig_mode: ", fig_mode))
    chkt <- dtk[!is.na(taxon) & type==1L, .(taxon, sex, type)]
    if (any(duplicated(chkt))) {
      print(paste0("!!Warning!! Check may be Error: Duplicated taxon, sex. Check it: ", 
                   paste0(chkt[duplicated(chkt),]$taxon, collapse=", "),
                   " after importing genus: ", gen_name))
    }
  } else {
    print(paste0("No key mode, and check cur_key_cnt & fig_mode: ", cur_key_cnt, " & ", fig_mode))
    #fig_num <- c()    
  }
  with_thesame_sp <- FALSE #some sp will have two different block for title, subfig, img, may due to too many figs that cannot be within a single row.
  Blk_condi <- 0 #"Normal" condition, #block(blk) belong to differnet species
  pre_imgj <- 0L 
  cur_fig_cnt <- 0L
  
  #i <- 195L #just when test first doc file #i<=232L before p.12 #i<=tstL #245L p13 #292L before p19 #351L p25
  while (fig_mode & nrow(dtk)>0 & i<=tstL) { #doclst[1:35], tstL<=140L to test subfig error for 2nd Version 202204
    x <- read_docx_row(ctent$text[i], nocheck = TRUE)
    wa <- regexpr("\\((S|s)ize",x)
    if (wa>0) {
      spname<- trimx(gsub(Fig_exclude_word, "", substr(x, 1, wa-1)))
      sattr <- gsub("\\(Size", "(size", substr(x, wa, nchar(x)))
    } else {
      spname<- trimx(gsub(Fig_exclude_word, "", x))
      sattr <- ""
    }
    
    fig_main <- trimx(gsub(Fig_exclude_word, "", x)) #changed to full_name + sattr with link to ckey when stored in dtk ctxt
    xsp2 <- sp2namex(spname)
    x_dtk<- which(dtk$taxon==xsp2 & dtk$type==1L)
    
    #if (key_chk_flag & !any(x_dtk)) {
    #  print(paste0("Error: Check fig_mode got ?? sp: ", xsp2, " at i: ", i))
    #  break
    #} else {
    if (TRUE) {
      within_xsp_flag <- TRUE
      i <- i + 1L
      ncflag <- 0L
      #fig_info <- c("subfig", "title", "caption")
      fig_title <- ""
      subfig <- c()
      fsex <- c()
      fig_num <- c()
      fig_caption <- c()
      fig_citation <- c()
      imgf <- c()
      imgj <- 0L
      fig_xx_flag <- FALSE #202204 added, xx_flag for sp only have figs, no keys, and now add a link in epitxt to connect to xx_fig
      if (!with_thesame_sp) pre_imgj <- 0L #20211019 modified fix the same sp but index of fig not added up
      while (within_xsp_flag) {
        x <- read_docx_row(ctent$text[i])
        #tt <- which(is.na(x) | gsub("Last update(?:.*)|\\.+|\\,+", "", x)=="") #ignore Last update:...
        if (i<tstL & x=="") { #any(tt)) {
          ncflag <- ncflag + 1
          if (ncflag >=31 ) { # excced one page of docx
            print(paste0("Warning: Too many NuLL rows, check it at i: ", i))
            fig_mode <- TRUE
            ncflag <- 0L
            break
          }
          if (i<tstL) {
            i <- i+1
            next
          } 
        } else {
          ncflag <- 0L
          #xt <- x #trimx(gsub("\\\t", "", gsub("\\’", "\'", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", gsub("\u00A0{1,}", " ", as.character(ctent$text[i])))))))
          if (length(subfig)==0 & fig_title=="" & trimx(gsub(Fig_exclude_word,"",x)) != spname) { #!is.na(xt) &  #(any(subfig=="")) {
            ### NOT the same read_doc_row ## ONLY trim leading spacing or \\t
            xss <- gsub("^\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\u00A0{1,}", " ", as.character(ctent$text[i])))) 
            subfig <- gsub("\\s*\\,\\s*", ", ", #make Sewell,1914 -> Sewell, 1914 with the same format
                        trimx(unlist(tstrsplit(xss, '\\s{2,}|\\t'), use.names = F))) %>% #note that sometimes pattern has: "a1   b2 & c3", split to "a1" "b2 & c3" 
                      sapply(function(x) {paste0(toupper(substr(x,1,1)), substr(x,2,nchar(x)))}, simplify = T, USE.NAMES = F)
            i <- i + 1L
            next
          } else if (length(subfig)>0 & fig_title=="" & substr(x,1,4) %chin% c("Fig.", "Figs")) {
            ################################### 20211022 modified, for one-more row to input subfig ###
            print(paste0("Note particularily: One-more row to input subfig for sp: ", xsp2, " at i: ", i))
            xss <- gsub("^\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\u00A0{1,}", " ", as.character(ctent$text[i])))) 
            subft <- gsub("\\s*\\,\\s*", ", ", #make Sewell,1914 -> Sewell, 1914 with the same format
                           trimx(unlist(tstrsplit(xss, '\\s{2,}|\\t'), use.names = F))) %>% #note that sometimes pattern has: "a1   b2 & c3", split to "a1" "b2 & c3" 
              sapply(function(x) {paste0(toupper(substr(x,1,1)), substr(x,2,nchar(x)))}, simplify = T, USE.NAMES = F)
            subfig <- c(subfig, subft)
            i <- i + 1L
            next
          } else if (fig_title=="") { #!is.na(x) &
            #DONT change x in subfig, or elsewhere, then NO need to read it again! #20211024 modified
            #x <- trimx(gsub("\\\t", "", gsub("\\’", "\'", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", gsub("\u00A0{1,}", " ", as.character(ctent$text[i])))))))
            xt <- gsub(Fig_exclude_word, "", x) ##DONT change x in subfig, or elsewhere
            if (xt!=spname & length(subfig)>0) {
              xc <- find_subfigx(x, subfig, 1L, print_info = FALSE)
              if (length(xc)>0 & xc[1]>0) {
                print(paste0("Note particularily: No fig title provided but detect subfig, use default spname in sp: ", spname))
                fig_title <- spname
                next #Note i cannot add 1 and let it go to fig_caption detection
              }
            }
            if (xt!=spname) {
              print(paste0("Warning: Not equal fig title with spname: ", spname, " check it fig_titile: ", xt, "  at i:",  i))
              tt <- sp2namex(xt)
              if (tt!=xsp2) {
                stop(paste0("Error: Not equal short fig title with taxon, check it fig_title: ", xt, "  at i:",  i))
                break
              } else {
                fig_title <- xt
              }
            } else {
              fig_title <- xt
            }
            i <- i + 1L
            next
          } else { ##DONT change x in subfig, or elsewhere
            #x <- read_docx_row(ctent$text[i], nocheck = T)  #trimx(gsub("\\\t", "", gsub("\\’", "\'", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", gsub("\u00A0{1,}", " ", as.character(ctent$text[i])))))))
            wa <- regexpr("\\((S|s)ize",x)
            xsp1 <- trimx(odbapi::sciname_simplify(x, simplify_one = T))
            if (i>=tstL | (!is.na(x) & (wa>0 | (xsp1==gen_name & imgj>0 & imgj>=length(subfig))))) { #trimx(sp2namex(x)) != xsp2)) {
              if (!is.na(wa) & wa<0) {
                spt <- trimx(gsub(Fig_exclude_word, "", x))
              } else {
                spt<- trimx(substr(x, 1, wa-1))
              }
              with_thesame_sp_flag <- FALSE
              if (i>=tstL | (spt != spname | (spt == spname & imgj>0 & imgj>=length(subfig)))) { #!is.na(x) &
                if (i>=tstL) {
                  print(paste0("End of doc: ", docfile))
                } else if (spt != spname) {
                  print(paste0("Start next sp: ", spt, "  at i:",  i)) #cannot add i, repeated this step though..
                } else {
                  with_thesame_sp_flag <- TRUE
                  print(paste0("Note particularily! Start a the-same sp: ", spt, "  at i:",  i)) 
                }
                
                if (imgj < length(subfig)) { ##No caption and this species is ended, cause no fig copied
                  print(paste0("Note particularily: Now Handle Not-normally-ended Figure Copyed: ", xsp2, " at i: ", i, 
                               " for subfig: ", paste0(subfig[(imgj+1):length(subfig)], collapse=",")))
                  if (imgj == length(subfig)-1 & subfig[imgj+1] == "Original") {
                    cntg_fig <- cntg_fig + 1L
                    doc_fign <- doc_fign + 1L
                    fig_num[imgj+1] <- cntg_fig
                    #docfn <- unlist(tstrsplit(docfile, "\\/"), use.names = F) %>% .[length(.)]
                    imgsrc <- paste0(#doc_imgdir, 
                                     #gsub("\\s", "_", gsub("Key to the species of\\s|\\s\\(China sea([s]*)\\s*[2]*\\)\\.docx", "", docfn)),
                                     #"/word/media/image",
                                     imgdir, "/image", doc_fign, ".jpeg")
                    if (!file.exists(imgsrc)) {
                      stop("Error: Cannot get the the image file: ", imgsrc, "  Check it at i:",  i)
                    }
                    imgf[imgj+1L] <- paste0(web_img, #padzerox(cntg_fig, 4), "_", ## modified 20210920 that no longer need numbers
                                            gsub("\\s", "_", xsp2),
                                            "_", padzerox(imgj+1+pre_imgj, 2), #padzerox(doc_fign), ## modified 20210920
                                            ".jpg") #0001_Sp_name_000x.jpg changed to -> Sp_name_01.jpg
                    if (!file.exists(imgf[imgj+1L])) {
                      system(enc2utf8(paste0("cmd.exe /c copy ", gsub("/","\\\\", imgsrc), 
                                             " ",gsub("/","\\\\",imgf[imgj+1L]))))
                    }
                    if (substr(x,1,8)=='Original') {
                      fig_caption[imgj+1L] <- trimx(gsub("°", "&deg;", gsub("(\\.|\\:)\\s*(M|m)ale","\\1 Male",
                                                        gsub("(\\.|\\:)\\s*(F|f)emale","\\1 Female",
                                                        gsub("(\\.|\\:)\\s*{1,}(F|f)igs\\.", "\\1 Figs.",
                                                        gsub("((\\.|\\:)\\s*){1,}(F|f)ig\\.", "\\1 Fig.", x))))))
                      print(paste0("Note: Not normally-ended just because i==tstL? ", i==tstL, " and now use x: ",x))
                      fsex[imgj+1L] <- check_sex_info(x)
                    } else {
                      fig_caption[imgj+1L] <- "Original"
                      fsex[imgj+1L] <- NA_character_                      
                    }
                  } else {
                    stop("Error!! Check sp: ", xsp2, " have less fig copied than subfig in i: ", i)
                  }
                }
                
                if (!with_thesame_sp & !with_thesame_sp_flag) {
                  ## It's a normal condition, curr blk and next blk are different species
                  Blk_condi <- 0 #"Normal" condition
                } else if (!with_thesame_sp & with_thesame_sp_flag) {
                  ## Next blk will have the same species as curr blk (by reading fig_main and get the same sp info)
                  ## Still write the same info, but need to keep some info?? to make ctxt is appendable
                  Blk_condi <- 1 #"Prepare" condition
                } else if (with_thesame_sp & !with_thesame_sp_flag) {
                  ## Curr blk belong to the same species as previous blk
                  ## Need to append ctxt, and use some previous info like <div id="fig_species">
                  Blk_condi <- 2 #"Append_blk" condition
                } else { #Both with_thesame_sp & with_thesame_sp_flag
                  ########Have this condition when three or more continuous the same species
                  Blk_condi <- 3 # So current data should append to dtk, as Blk_condi = 2 and next prepare as 1
                }
                
                within_xsp_flag <- FALSE #A species is completed its record, and go into next sp! 
                
                if (Blk_condi<2) { blk_cnt <- blk_cnt + 1 } # if Blk_condi==2 should be in the same blk to render
                #flink <- sapply(fig_num, function(x) {
                #  paste0("fig_", gsub("\\s", "_", xsp2), "_", padzerox(x))
                #}, simplify = T)
                fkeyx<- gsub("www_sp\\/assets\\/img\\/species\\/|\\.jpg", "", imgf)
                fnum <- gsub("_", "", gsub(gsub("\\s", "_", xsp2), "", fkeyx))
                
                if (length(fig_caption)==0) {
                  cap_cite <- data.table(cap=NA_character_, cite=NA_character_)
                } else {
                  cap_cite <- data.table(cap=fig_caption, 
                                         cite=c(fig_citation, rep(NA_character_, length(fig_num)-length(fig_citation))))
                  cap_cite[,caprow:=ifelse(is.na(cap), NA_integer_, .I)]
                  setnafill(cap_cite, "locf", cols="caprow")
                  cap_cite[is.na(cap),cap:=fig_caption[caprow]]
                  citex <- cap_cite[!is.na(cite),]$cite[1]
                  cap_cite[is.na(cite), cite:=ifelse(grepl("Original", cap), "Original", citex)]
                }
                
                if (any(x_dtk)) {
                  if (!any("female/male" %chin% dtk[x_dtk,]$sex) &&
                      "female" %chin% dtk[x_dtk,]$sex &&
                      "male" %chin% dtk[x_dtk,]$sex) {
                    key_sex <- rbindlist(list(dtk[x_dtk, .(ckey, sex, kcnt)],
                                              data.table(ckey=paste(dtk[x_dtk,]$ckey, collapse = ","),
                                                         sex="female/male",
                                                         kcnt=min(dtk[x_dtk,]$kcnt))))
                  } else {
                    key_sex <- dtk[x_dtk, .(ckey, sex, kcnt)]
                  }
                } else {
                  key_sex <- data.table()
                }
                malekey <- ""; femalekey <- ""; keymat <- c()
                if (nrow(key_sex)) {
                  if (key_chk_flag) {
                    malekey <- ifelse("male" %chin% key_sex$sex, key_sex[sex=="male",]$ckey[1], key_sex[sex=="female/male",]$ckey[1])
                    femalekey <- ifelse("female" %chin% key_sex$sex, key_sex[sex=="female",]$ckey[1], key_sex[sex=="female/male",]$ckey[1])
                  } 
                  ktt <- chmatch(fsex, key_sex$sex)
                  if (all(is.na(ktt))) {
                    keymat <- chmatch("female/male", key_sex$sex)
                  } else {
                    keymat <- ktt #cannot just use key_sex[chmatch(fsex, sex),]$ckey because may lost match
                    keymat[is.na(keymat)] <- chmatch("female/male", key_sex$sex)
                  }
                  ckeyx <- key_sex[keymat,]$ckey
                  tokeyx<- key_sex[keymat,]$kcnt
                } else {
                  ckeyx <- rep(NA_character_, length(fig_num))
                  tokeyx <- rep(NA_character_, length(fig_num))
                }
                fdlink <- paste0("figs_", gsub("\\s", "_", xsp2)) #, "_", paste(fnum, collapse="-"))

                if (any(x_dtk)) {
                  keyt <- as.integer(gsub('[a-z]','', dtk[x_dtk,]$ckey))
                  korder <- order(keyt)
                  keyt <- keyt[korder]
                  skey <- dtk[x_dtk[korder],]$subkey
                  fukey<- ""
                  for (tti in seq_along(keyt)) {
                    fukey <- paste0(fukey, 
                                    paste0(ifelse(tti==1, paste0(gen_name, "_"), "_"), 
                                           padzerox(keyt[tti], 2), skey[tti]))
                  }
                  fukey <- paste0(fukey, "_", trimx(gsub(gen_name, "", xsp2)), "_fig") # make unikey in order
                } else {
                  fukey <- paste0(gsub("\\s", "_", xsp2), "_xx_fig")
                  fig_xx_flag <- TRUE
                }

                if (length(fig_num)>=4) {
                  spanx <- 'nnar' ### narrow span
                } else if (length(fig_num) ==3 ) {
                  spanx <- 'ntrd' 
                } else if (length(fig_num) == 2) {
                  spanx <- 'ntwo'
                } else { 
                  spanx <- 'nfig'
                }
                #break #only for test
                if (length(fig_caption)==0) {
                  fig_caption <- NA_character_
                  fig_citation<- NA_character_
                } else if (any(is.na(fig_caption)) | 'Original' %chin% fig_caption) {
                  fig_caption <- fig_caption[!is.na(fig_caption) & fig_caption != 'Original'] #for ouput html of caption section
                }
                if(length(subfig)==0) {
                  xsubf <- ""
                } else {
                  xsubf <- subfig
                }
                
                #"Acartia (Acanthacartia) bilobata Braham, 1970" ->
                # Acartia (Acanthacartia) bilobata (Braham, 1970)
                if (Blk_condi <= 1) { # if Blk_condi ==2 the same sp info as previous blk, not overwrite
                  xsp3 <- odbapi::sciname_simplify(spname, trim.subgen = F, simplify_two = T)
                  xaut <- trimx(gsub(gsub("\\(","\\\\(",gsub("\\)","\\\\)",xsp3)),"",spname))
                  if (xaut=="") {
                    full_name <- xsp3
                  } else {
                    full_name <- gsub("\\(\\(", "(", gsub("\\)\\)", ")", paste0(xsp3," (",xaut,")")))
                  }
                  #Note that if Subgenus == Genus, i.e. Acartia (Acartia) negligens, without ?!\\( ?!\\), cannot get correct subgenx
                  subgenx <- trimx(gsub(paste0(paste0("(?!\\()(",gsub("\\s","|", xsp2),")(?!\\))"),"|\\(|\\)"), "",
                                        odbapi::sciname_simplify(spname, trim.subgen = F, simplify_two = T), perl = T))
                  epit <- trimx(gsub(gen_name, "", xsp2)) #epithets
                  
                  if (sattr!="") { #has Size: female ; male:..)
                    fig_main = paste0(full_name, " ", sattr)
                    fig_mtxt = paste0(full_name, " ",
                                      gsub("(\\.*\\,*\\;\\s*|\\s)(M|m)ale\\:*\\,*\\s*", 
                                        ifelse(is.na(malekey) || malekey=="", "; male, ", paste0("; <a href=", dQuote(paste0("#key_",gen_name,"_",malekey)), ">male</a>, ")), 
                                        gsub("\\s*(F|f)emale\\:*\\,*\\s*", 
                                          ifelse(is.na(femalekey) || femalekey=="", " female, ", paste0(" <a href=", dQuote(paste0("#key_",gen_name,"_",femalekey)), ">female</a>, ")), sattr)))
                  } else {
                    fig_main = full_name
                    fig_mtxt = paste0(full_name,
                                      ifelse(is.na(femalekey) || femalekey=="", "", paste0(" (<a href=", dQuote(paste0("#key_",gen_name,"_",femalekey)), ">female</a>", ifelse(is.na(malekey) || malekey=="", ")", "; "))),
                                      ifelse(is.na(malekey) || malekey=="", "", paste0(ifelse(is.na(femalekey) || femalekey==""," (", ""), "<a href=", dQuote(paste0("#key_",gen_name,"_",malekey)), ">male</a>)"))) 
                  }
                }
                
                if (Blk_condi<2) { keycnt <- keycnt + 1L } #when Blk_condi>=2 write to the same ctxt, so not add counter
                dfkt <- data.table(fidx=fig_num, fkey=fkeyx,
                                   ckeyx=ckeyx, #rep(paste(dtk[x_dtk,]$ckey, collapse = ","), length(fig_num)),
                                   imgf=gsub("www_sp\\/", "", imgf), 
                                   fsex=fsex, #rep(NA_character_, length(fig_num)),
                                   main= ifelse(Blk_condi<=1, fig_main, NA_character_),  #c(fig_main, rep(NA_character_, length(fig_num)-1L)),
                                   title=full_name, #c(full_name,rep(NA_character_, length(fig_num)-1L)),
                                   subfig= subfig, caption= cap_cite$cap, 
                                   citation= cap_cite$cite, #may be null, so use fill=NA
                                   flushed=rep(paste(fig_num, collapse = ","), length(fig_num)), ## flushed means flush figs in a row
                                   blkx=blk_cnt, docn=cntg, rid=i, 
                                   kcnt=keycnt, tokcnt=tokeyx, page=page_cnt,
                                   xdtk=ifelse(any(x_dtk), paste(x_dtk, collapse=","), NA_character_),
                                   taxon=xsp2, subgen=ifelse(subgenx=="", NA_character_, subgenx),
                                   genus=gen_name, family=fam_name) ### blkx: counter of block of fig, docn: nth document
                
                dfk <- rbindlist(list(dfk, dfkt), fill = TRUE) 
                
                # 20210903 modified: write dtk only when with_thesame_sp is false (wait all blocks of the same sp)
                # Blk_condi <=1 write normal ctxt; Blk_condi == 2 appends to previous ctxt
                if (Blk_condi<2) {
                  #ctxt0 need append new fig into <div id="fig_species_name"> when Blk_condi==2
                  #20210903 modified extend this <div id="fig_species_name"></div> contains not only figs, but also caps, citations
                  #         and change <span class='blkfigure'> to <div>
                  ctxt0 <- paste0(paste0('\n\n<div id=', dQuote(fdlink),'><div class=', dQuote('blkfigure'),'>'), 
                             paste0('<div class=', dQuote("fig_title"),'><span class=', dQuote('spmain'), '>', italics_spname(fig_mtxt, spname),'</span></div>'),
                             mapply(function(outf,flink,cfigx,spanx) {
                                  paste0('<span class=', dQuote(spanx), '><a data-fancybox=',
                                         dQuote("gallery"), ' class=', dQuote("fbox"), 
                                         ' href=', dQuote(paste0("#fig_", flink)), ## 20210920 modified use only hash, not link 
                                         #' data-alt=', dQuote(paste0(capx)),
                                         '><img src=',
                                         dQuote(outf), ' border=', dQuote('0'),
                                         ' alt=', dQuote(full_name),
                                         ' /></a><span id=', dQuote(paste0("fig_",flink)), ' class=', dQuote('spcap'),
                                         '>',cfigx, #' *',sp,'* ',sex,
                                         #' [&#9754;](#key_',ckeyx,') &nbsp;', fdupx,
                                         '</span></span>') ############ Only MARK duplicated imgf
                             },#outf=gsub("species\\/", "sp_thumb/", gsub("www_sp\\/", "", imgf)), # use thumbnail in imgsrc
                               outf=gsub("assets\\/img\\/species\\/", "https://bio.odb.ntu.edu.tw/pub/copkey/sp_thumb/", gsub("www_sp\\/", "", imgf)),
                               flink=fkeyx, cfigx=xsubf, #fgcnt=fig_num,
                               MoreArgs = list(spanx=spanx), SIMPLIFY = TRUE, USE.NAMES = FALSE) %>% 
                               paste(collapse=" "),
                             '</div><br><br>') #it's ends of <div class='blkfigure'>

                  #ctxt1 need not change
                  ctxt1 <- paste0(paste0('<div class=', dQuote("fig_title"),'><span class=', dQuote('spcap'), '>', italics_spname(full_name, spname),'</span></div>'),
                               sapply(seq_along(fig_caption), function(k) { #citex, capx, 
                                   citex=fig_citation; capx=fig_caption
                                   cx <- ifelse(is.na(citex[k]) | citex[k]=="", "", 
                                                paste0('<div class=', dQuote('fig_cite'), '><span class=', dQuote('spcap'), '>', italics_spname(citex[k], spname),'</span></div>'))
                                   out <-paste0('<div class=', dQuote('fig_cap'), '><span class=', dQuote('spcap'), '>',
                                                bold_spsex(italics_spname(capx[k], spname)), '</span></div>', cx)
                                      return(out)
                               },#citex=fig_citation, capx=fig_caption, 
                                 #MoreArgs = list(k=seq_along(fig_caption)), SIMPLIFY = TRUE, 
                                 simplify = TRUE, USE.NAMES = FALSE) %>% paste(collapse="<br>"))
                  
                  if (Blk_condi==0) {
                    #ctxt0<- paste0(ctxt0, '</div><br>')  # This </div> ends with <div id="fig_species_name">
                    ctxtt <- paste0(ctxt0, ctxt1, '</div><br><br>',  ifelse(i==tstL, "<br><br>\n\n", ""))
                  } else {
                    ctxtt <- paste0(ctxt0, ctxt1)
                  }
                  
                  dtk <- rbindlist(list(dtk, 
                      data.table(rid=i, unikey=fukey, #fdlink,
                        ckey= NA_character_, subkey= NA_character_, pkey= toJSON({}), #NA_character_,
                        figs=paste(fig_num, collapse = ","), type=2L, nkey=NA_integer_, 
                        taxon=xsp2, 
                        abbrev_taxon=ifelse(any(x_dtk),dtk[x_dtk[1],]$abbrev_taxon, paste0(substr(gen_name, 1,1), ".", gsub(gen_name, "", xsp2))), 
                        fullname=full_name,
                        subgen=ifelse(subgenx=="", NA_character_, subgenx), 
                        genus=gen_name, family=fam_name,
                        epithets=epit, 
                        keystr=toJSON(fig_caption), #keystr=keystr, 
                        ctxt=ctxtt,
                        fkey=paste(fkeyx, collapse=","), 
                        sex=NA_character_, docn=cntg,
                        kcnt=keycnt, page=page_cnt))) #, keyword="figs"))) #figs is type =2
                  
                } else { #Blk_condi>=2
                  dfkt <- dfk[taxon==xsp2,] #extend to all blks belong to the same species
                  ctxtt<- paste0(ctxtt, 
                            paste0('\n<br><br><div class=', dQuote('blkfigure'),'>'), 
                            #paste0('<div class=', dQuote("fig_title"),'><span class=', dQuote('spmain'), '>', italics_spname(fig_mtxt, spname),'</span></div>'),
                            mapply(function(outf,flink,cfigx,spanx) {
                                paste0('<span class=', dQuote(spanx), '><a data-fancybox=',
                                       dQuote("gallery"), ' class=', dQuote("fbox"), 
                                       ' href=', dQuote(paste0("#fig_", flink)), ## 20210920 modified use only hash, not link ,
                                       #' data-alt=', dQuote(paste0(capx)),
                                       '><img src=',
                                       dQuote(outf), ' border=', dQuote('0'),
                                       ' alt=', dQuote(full_name),
                                       ' /></a><span id=', dQuote(paste0("fig_",flink)), ' class=', dQuote('spcap'),
                                       '>',cfigx, #' *',sp,'* ',sex,
                                       #' [&#9754;](#key_',ckeyx,') &nbsp;', fdupx,
                                       '</span></span>') ############ Only MARK duplicated imgf
                            },#outf=gsub("species\\/", "sp_thumb/", gsub("www_sp\\/", "", imgf)), # No need www_sp/ in html link
                              outf=gsub("assets\\/img\\/species\\/", "https://bio.odb.ntu.edu.tw/pub/copkey/sp_thumb/", gsub("www_sp\\/", "", imgf)),
                              flink=fkeyx, cfigx=xsubf, #fgcnt=fig_num,
                              MoreArgs = list(spanx=spanx), SIMPLIFY = TRUE, USE.NAMES = FALSE) %>% 
                            paste(collapse=" "), '</div><br><br>', #it's ends of <div class='blkfigure'>
                            
                            paste0('<div class=', dQuote("fig_title"),'><span class=', dQuote('spcap'), '>', italics_spname(full_name, spname),'</span></div>'),
                            sapply(seq_along(fig_caption), function(k) { #citex, capx, 
                              citex=fig_citation; capx=fig_caption
                              cx <- ifelse(is.na(citex[k]) | citex[k]=="", "", 
                                           paste0('<div class=', dQuote('fig_cite'), '><span class=', dQuote('spcap'), '>', italics_spname(citex[k], spname),'</span></div>'))
                              out <-paste0('<div class=', dQuote('fig_cap'), '><span class=', dQuote('spcap'), '>',
                                           bold_spsex(italics_spname(capx[k], spname)), '</span></div>', cx)
                              return(out)
                            },simplify = TRUE, USE.NAMES = FALSE) %>% paste(collapse="<br>"),
                            '</div><br><br>',  ifelse(i==tstL, "<br><br>\n\n", "")) # This </div> ends with <div id="fig_species_name">
                  
                  fig_capx <- unique(na.omit(c(dfk[blkx==blk_cnt,]$caption, fig_caption)))
                  dtk[nrow(dtk), `:=`(
                    ctxt = ctxtt,
                    fkey = paste(fkey, paste0(fkeyx, collapse=",")),
                    keystr=ifelse(length(fig_capx)>0, toJSON(fig_capx), toJSON({}))
                  )]
                } 
                if (key_chk_flag & any(x_dtk) & (Blk_condi==0 | Blk_condi>=2)) { #if next blk is the same sp (Blk_condi==1), just wait until next blk come in
                  dtk[x_dtk, `:=`(
                    fullname = full_name,
                    subgen = ifelse(is.na(subgen) & !is.na(subgenx) & subgenx != "", subgenx, subgen),
                    epithets = epit, 
                    figs = sapply(sex, function(x) {
                      if (!is.na(x) && x=="male") {
                        fk <- dfkt[fsex=="male" | fsex=="female/male",]$fidx
                      } else if (!is.na(x) && x=="female") {
                        fk <- dfkt[fsex=="female" | fsex=="female/male",]$fidx
                      } else {
                        fk <- dfkt$fidx
                      }
                      return(paste(fk, collapse=","))
                    }, simplify = TRUE, USE.NAMES = FALSE),
                    fkey = sapply(sex, function(x) { #cannot just use grepl because "female" contains "male"
                      if (!is.na(x) && x=="male") {
                        fk <- dfkt[fsex=="male" | fsex=="female/male",]$fkey
                      } else if (!is.na(x) && x=="female") {
                        fk <- dfkt[fsex=="female" | fsex=="female/male",]$fkey
                      } else {
                        fk <- dfkt$fkey
                      }
                      return(paste(fk, collapse=","))
                    }, simplify = TRUE, USE.NAMES = FALSE)
                  )]
                }

                #202204 added, xx_flag for sp only have figs, no keys, and 
                #       now add a link in epitxt to connect to xx_fig
                if (fig_xx_flag & !xsp2 %chin% handle_xx_fig) { #Cannot handle it twice
                  print(paste0("Handle xx_fig lost link for: ", xsp2, " at i: ", i))
                  epit <- trimx(gsub(gen_name, "", xsp2)) #epithets
                  #wepit<-regexpr(paste0("<em>", paste0(gen_name,"\\s",epit), "\\s*<\\/em>"), epitxt)
                  wepit<- regexpr(paste0(gen_name,"\\s",epit), epitxt)
                  xt <- xsp2
                  if (all(wepit<0)) {
                    #wepit<-regexpr(paste0("<em>\\s*", epit, "\\s*<\\/em>"), epitxt)
                    wepit<- regexpr(epit, epitxt)
                    if (all(wepit<0)) {
                      fig_xx_flag <- FALSE   
                      stop(paste0("Error: But its link cannot recover, check it:", epitxt))
                    }
                    xt <- epit
                  }
                  epitxt_new <- paste0(substr(epitxt,1,wepit[1]-1),
                                       '<a href=', dQuote(paste0("#figs_",gen_name,"_",epit)), '>', xt, '</a>',
                                       substr(epitxt, wepit[1]+attributes(wepit)$match.length[1], nchar(epitxt)))
                  
                  dtk[unikey == paste0(gen_name, "_00a_genus"), 
                      ctxt:=epitxt_new]
                  handle_xx_fig <- c(handle_xx_fig, xsp2)
                }
                fig_xx_flag <- FALSE   
                                
                if (!with_thesame_sp & with_thesame_sp_flag) {
                  with_thesame_sp <- TRUE  #Next turn will be Append_Blk condition
                  with_thesame_sp_flag <- FALSE
                  pre_imgj <- length(fnum)
                } else if (with_thesame_sp & with_thesame_sp_flag) {
                  with_thesame_sp <- TRUE  #Next turn will still in Append_Blk condition
                  with_thesame_sp_flag <- FALSE
                  pre_imgj <- pre_imgj + length(fnum)
                  print(paste0("Nest turn will in Blk_condition 3, check it: ", xsp2, " at i: ", i,
                               " and this sp already has figs: ", pre_imgj))
                } else { #Return to nomal condition
                  with_thesame_sp <- FALSE
                  with_thesame_sp_flag <- FALSE
                }
                if (i>=tstL) {
                  within_xsp_flag <- FALSE
                  fig_mode <- FALSE
                  print(paste("End dtk loop in i for genus: ", i, gen_name, within_xsp_flag, fig_mode, sep=", "))
                  break
                }
                print(paste("End dtk loop in i with sp: ", i, spname, within_xsp_flag, fig_mode, sep=", "))
                next
              } else {
                print(paste0("Warning: Format not consistent to get the same sp: ", spt, "  Check it at i:",  i))
                break 
              }
            } else {
              #if (length(fig_caption)==0) {
                flag_getcap <- FALSE
                xc <- c(-1)
                subfx <- trimx(gsub("\\((?:.*)\\)", "", subfig[(imgj+1):length(subfig)]))
                if (length(subfig)>0 & imgj < length(subfig)) {
                  xc <- find_subfigx(x, subfig, imgj+1)
                }
                if (length(subfig)==0 & length(fig_caption)==0) { #only one fig in this row and not read any fig_caption yet
                  flag_getcap <- TRUE
                } else if (imgj >= length(subfig)) { #End of fetch subfig
                  flag_getcap <- FALSE
                } else if (#(xc[1]>0) | #(subfig[imgj+1] == substr(x, 1, nchar(subfig[imgj+1]))) | 
                           (any(grepl("^Female",subfig)) & grepl("(F|f)emale", x)) |
                           (any(grepl("^Male", subfig)) & grepl("(?:(\\s|\\b|\\.|\\;|\\:|\\,)+)(M|m)ale", x))) {
                  flag_getcap <- TRUE
                } else if (length(xc)>0 & xc[1]>0 & imgj<length(subfig)) {
                  flag_getcap <- TRUE
                }
                if (flag_getcap) {    
                  k <- 1
                  xseg0 <- "" #sometimes Female/Male sex info written in xseg[1] and might be removed, and thus cannot find sex info
                  if (length(subfig)>0 & imgj<length(subfig)) {
                    #if (xc[1]<0) { #subfig[imgj+1] != substr(x, 1, nchar(subfig[imgj+1]))) {
                    if (all(grepl("^(Female|Male)",subfx)) & grepl("(F|f)emale|(?:(\\s|\\b|\\.|\\;|\\:|\\,)+)(M|m)ale", x)) {
                        #(all(grepl("^Male", subfx)) & grepl("(?:(\\s|\\b|\\.|\\;|\\:|\\,)+)(M|m)ale", x))) {
                        k <- imgj + length(subfx) # one description (x) contains two subfigs
                    } else if (length(xc)>0 & xc[1]>0) {
                      #if (length(xc)>1) {
                      k <- imgj + length(xc)
                      #} else if (imgj<length(subfig)) { #subfig[imgj+1] == substr(x, 1, nchar(subfig[imgj+1]))) {
                      #  k <- imgj+1 # 2nd run for subfig[2], every time just run 1 turn because wait i+1 description in next turn
                      #}
                    }
                  }
                  if (length(xc)>1 & k>(imgj+1)) {
                    #traitstr <- paste0("(",paste0(Traits, collapse="|"), ")")
                    chk_traits <- FALSE
                    length_traits <- 0L
                    if (all(grepl(traitstr, subfx))) {
                      chk_traits <- TRUE
                      length_traits <- length(subfx)
                    } else if (length(subfx)>=3 & all(grepl(traitstr, subfx[1:(length(subfx)-1)]))) { 
                      #if only last subfig not trait, sometimes, e.g. Original, let it pass #Pseudodiaptomus serricaudatus
                      chk_traits <- TRUE
                      length_traits <- length(subfx)-1
                    }
                    if (chk_traits) { #all(grepl(traitstr, subfx))) {
                      print(paste0("Note particularily: Use Traits in taxon: ", xsp2, " at i: ", i))
                      #xt <- sapply(subfx, function(x) {
                      #  gsub("\\s", "\\\\s",
                      #       paste0("(", toupper(substr(x,1,1)), "|", tolower(substr(x,1,1)), ")",
                      #              substr(x, 2, nchar(x))))
                      #}, simplify = T, USE.NAMES = F)
                      xt <- sapply(subfx[1:length_traits], function(x) {
                        #gsub("\\(M\\|m\\)ale", "(?:(\\\\s|\\\\b|\\\\.|\\\\;|\\\\:|\\\\,)+)(M|m)ale",
                        gsub("(\\s|\\\\s)*\\(((F|f)emale|(M|m)ale)\\)$", "", 
                        gsub("\\s", "\\\\s", gsub("\\,", "\\\\,", gsub("\\-", "\\\\-", gsub("\\/", "\\\\/",
                        gsub("(?:\\/)([a-zA-Z]{1})([a-zA-Z]+)", "/(\\U\\1|\\L\\1)\\2", #make "abc/att/Mtt" -> "abc/(A|a)tt/(M|m)tt"                                                                
                        #gsub("(?![a-zA-Z]+)(\\-|\\/)(?![a-zA-Z]+)", "", #to match Figs 113-116, 11/12 to integer, we don't match "-", "/", even in traits
                          paste0("(", toupper(substr(x,1,1)), "|", tolower(substr(x,1,1)), ")",
                                 substr(x, 2, nchar(x))), perl=T), perl=T)))))
                      }, simplify = T, USE.NAMES = F)
                      #if (length_traits < length(subfx)) {
                      #  xt[length_traits+1] = subfx[length_traits+1] #so that it can match both Traits/other attr, e.g. subfig = "Habitus (Female)" "Mouth parts" "Legs"  "Male"
                      #}
                      xseg <- trimx(unlist(tstrsplit(x, 
                                             paste0("(", paste0(xt, collapse="|"), ")")), 
                                           use.names = F))
                      if (!any(grepl(xt[1], substr(x,1,nchar(xseg[1]))))) {
                        xseg0 <- xseg[1]
                        xseg <- xseg[-1] 
                      }
                      if (#length_traits < length(subfx) & 
                          length(xseg) == length(xt)) {
                        gsext <- grep("\\(((F|f)emale|(M|m)ale)\\)", subfx)
                        #if (grepl("^(Female|Male)", xt[length_traits+1])) { #tstrsplit would cause sex info lost, paste it again.
                        if (any(gsext)) {
                          #xseg[length_traits+1] <- paste0(xt[length_traits+1], xseg[length_traits+1])
                          xseg[gsext] <- paste0(gsub("^(?:.*)*\\(|\\)", "", subfx[gsext]), xseg[gsext])
                        }
                      }
                      #xseg <- mapply(function(xs,subx) {
                      #  paste0(subx, xs)
                      #},xs=xseg, subx=subfx,
                      #SIMPLIFY = TRUE, USE.NAMES = FALSE) #NO sex info, so cannot skip this
                    } else if (identical(subfx, LETTERS[1:length(subfx)])) {
                      xseg <- trimx(unlist(tstrsplit(x, 
                                             paste0("(", paste0(subfx,"\\.", collapse="|"), ")")), 
                                           use.names = F))
                      if (substr(x,1,2) != "A.") {
                        xseg0 <- xseg[1]
                        xseg <- xseg[-1]
                      }
                    } else if (all(grepl("^(Female|Male)",subfx))) {
                      xseg <- trimx(unlist(tstrsplit(x, #20211102 not match female/male at end of sentence: e.g. Scales: same as for female. #Labidocera detruncata
                                                     paste0("(", paste0(c("(F|f)emale(?!\\.*$)", "(?:(\\s|\\b|\\.|\\;|\\:|\\,)+)(M|m)ale(?!\\.*$)"), collapse="|"), ")"),
                                                     perl=T), 
                                           use.names = F))
                      if (substr(x,1,6) != "Female" & substr(x,1,4) != "Male") {
                        xseg0 <- xseg[1]
                        xseg <- xseg[-1] 
                      }
                      ## tstrsplit will lost Female/Male info, that cause fsex detect error
                      xseg <- mapply(function(xs,subx) {
                        paste0(subx, xs)
                      },xs=xseg, subx=gsub("\\s*(\\&|\\/|\\(){1}(?:.*)+$", "", subfx),
                        #MoreArgs = list(subx=subfx), 
                        SIMPLIFY = TRUE, USE.NAMES = FALSE)
                    } else {
                      if (grepl("^\\*", subfx[1])) {
                        #iprex <- "*"
                        iprext <- paste0("(", paste0(gsub("\\*", "\\\\*", gsub("\\-", "\\\\-",subfx)), collapse="|"), ")")
                        xseg <- trimx(unlist(tstrsplit(x, iprext), use.names = F))
                        if (substr(x,1,nchar(subfx[1])) != substr(subfx[1],1,nchar(subfx[1]))) {
                          xseg0 <- xseg[1]
                          xseg <- xseg[-1] 
                        }
                      } else {
                        if (all(grepl("Taf\\.", subfx))) {
                          iprex <- "Taf."
                        } else if (grepl("(f|F)igs\\.", subfx[1])) {
                          if (any(grepl("(f|F)ig\\.", subfx))) {
                            iprex <- "Fig(s)*."
                          } else {
                            iprex <- "Figs."
                          }
                        } else {
                          if (any(grepl("(f|F)igs\\.", subfx))) {
                            iprex <- "Fig(s)*."
                          } else {
                            iprex <- "Fig."
                          }
                        }
                        xstr <- gsub("\\sfig\\.", " Fig.", gsub("\\sfigs\\.", " Figs.", 
                                gsub("\\spl\\.", " Pl.", gsub("\\splate", " Plate", x))))
                        
                        if (any(grepl("Plate|Pl\\.", subfx))) {
                          if (grepl("\\sPlate", xstr)) {
                            iprex <- "Plate"
                          } else if (grepl("\\sPl.", xstr)) {
                            iprex <- "Pl."
                          } else {
                            print(paste0("Error: Detect Plate as subfig but NO Plate, Pl. in xstr, use empty prex: ", xstr))
                            iprex <- ""
                          }
                        } 
                        iprext <- gsub("\\.", "\\\\.", iprex)
                        xseg <- trimx(unlist(tstrsplit(xstr, paste0("(\\s|\\.|\\/)", iprext)), use.names = F))
                        #### 20211022 modified that Fig.2/Fig.4 caption cause segment of Fig.2 has nothing, that should be copied from segment of Fig.4
                        xts1 <- sapply(subfx, function(x) {
                          grepl(paste0(gsub("\\s","(\\\\s)*", x),"\\/"), xstr)
                        }, simplify = T, USE.NAMES = F)
                        xtc1 <- sapply(subfx, function(x) {
                          grepl(paste0("\\/", gsub("\\s","(\\\\s)*", x)), xstr)
                        }, simplify = T, USE.NAMES = F)
                        if (iprex!="" & substr(xstr,1,3) != substr(iprex,1,3)) {
                          xseg0 <- xseg[1]
                          xseg <- xseg[-1] 
                        }
                        if (any(xts1) & any(xtc1) & length(xseg[xts1]) == length(xseg[xtc1])) {
                          xseg[xts1] <- paste0(xseg[xts1], rep('/',length(xseg[xts1])), xseg[xtc1])
                        } else if (any(xts1) & any(xtc1) & length(xseg[xts1]) != length(xseg[xtc1])) {
                          stop(paste0("Error: Replace alternative segment content got trouble: ", xsp2, " at i: ", i))
                        }
                      }
                    }
                    if (length(xseg) != length(xc)) {
                      if (length(xseg) > length(xc)) {
                        stop(paste0("Error: Detect subfig is integer but NOT equal segemnt! For sp: ", xsp2,
                                    " with subfx: ", paste0(subfx, collapse=","), " and Check this str: ", x))
                        break
                      } else {
                        print(paste0("Warning: Detect subfig is integer but NOT equal segemnt! For sp: ", xsp2,
                                     " with subfx: ", paste0(subfx, collapse=","), " and Check this str: ", x))
                      }
                    }
                  } #else {
                    #xseg <- x
                  #}
                  
                  eachj = 0
                  while (imgj<k) {
                  #if (subfig[imgj+1] != "Original") {
                    cntg_fig <- cntg_fig + 1L
                    doc_fign <- doc_fign + 1L
                    fig_num[imgj+1] <- cntg_fig
                    cur_fig_cnt <- cur_fig_cnt + 1L
                    docfn <- unlist(tstrsplit(docfile, "\\/"), use.names = F) %>% .[length(.)]
                    imgsrc <- paste0(doc_imgdir, 
                                     gsub("\\s", "_", gsub("Key to the species of\\s|\\s\\(China sea([s]*)\\s*[2]*\\)\\.docx", "", docfn)),
                                     "/word/media/image", doc_fign, ".jpeg")
                    if (!file.exists(imgsrc)) {
                      stop(paste0("Error: Cannot get the the image file: ", imgsrc, "  Check it at i:",  i))
                      break 
                    }
                    imgf[imgj+1L] <- paste0(web_img, #padzerox(cntg_fig, 4), "_", ## modified 20210920 that no longer need numbers
                                            gsub("\\s", "_", xsp2),
                                            "_", padzerox(imgj+1+pre_imgj, 2), #padzerox(doc_fign), ## modified 20210920
                                            ".jpg") #0001_Sp_name_000x.jpg changed to -> Sp_name_01.jpg
                    if (!file.exists(imgf[imgj+1L])) {
                      system(enc2utf8(paste0("cmd.exe /c copy ", gsub("/","\\\\", imgsrc), 
                                             " ",gsub("/","\\\\",imgf[imgj+1L]))))
                    }
                    if (k>1 & imgj>=1 & eachj>0) {#& (length(xc)>1 & length(xc)==k)) { #subfig[imgj+1] != substr(x, 1, nchar(subfig[imgj+1]))) {
                      fig_caption[imgj+1L] <- NA_character_ #only one description but contains two subfigs
                    } else {
                      fig_caption[imgj+1L] <- trimx(gsub("°", "&deg;", gsub("(\\.|\\:)\\s*(M|m)ale","\\1 Male",
                                                                       gsub("(\\.|\\:)\\s*(F|f)emale","\\1 Female",
                                                                       gsub("(\\.|\\:)\\s*{1,}(F|f)igs\\.", "\\1 Figs.",
                                                                       gsub("(\\.|\\:)\\s*{1,}(F|f)ig\\.", "\\1 Fig.", x))))))
                    }
                    
                    need_fetch_fsex <- FALSE
                    if (length(subfig)==0) {
                      need_fetch_fsex <- TRUE
                    } else {
                      if (subfig[imgj+1L]!="Female" & subfig[imgj+1L]!="Male") {
                        need_fetch_fsex <- TRUE
                      }
                    }
                    if (need_fetch_fsex) {
                      if (length(xc)>1 & k>1) {
                        xt <- xseg[eachj+1] # not imgj+1, xseg is only valid once for each i
                      } else {
                        xt <- x
                      }
                      fsext <- check_sex_info(xt)
                      if (is.na(fsext)) {
                        fsext <- check_sex_info(xseg0)
                      }
                      fsex[imgj+1L] <- fsext
                    } else {
                      fsex[imgj+1L] <- tolower(subfig[imgj+1L])
                    }
                    imgj <- imgj + 1L
                    eachj <-eachj+ 1L
                  } 
                  ## only for debug ##############
                  #if (length(subfig)>0) {
                  #  if (xsp2 == "Euaugaptilus magnus" & subfig[1]=="Habitus") {stop("Debug Break!")}
                  #}
                  i <- i + 1L
                  next
                  
                } else { #Not another subfig, can be citation of subfig
                  if (length(subfig)>0 & imgj <= length(subfig)) {
                    if (subfig[imgj] == "Original" | !substr(x,1,7) %chin% c("Adapted", 'Razouls')) {
                      print(paste0("Warning: Get a not-citation remark: ", x, "  Check it at i:",  i))
                    }
                  }
                  if (length(subfig)>0 & imgj >= length(subfig)) {
                    fig_citation[length(na.omit(fig_caption))] <- x
                  } else {
                    fig_citation[imgj] <- trimx(x)
                  }
                  i <- i+1
                  next
                }
              #}
            } # end of fig_caption
          }
        }    
      } #end of while within_xsp_flag
    } 
  } #end of while fig_mode
  ## modified 20220402, check fig_num
  if (cur_fig_cnt!=imgfileL) {
    stop(paste0("Error: Fetch Figs Number not correct! fetched: ", cur_fig_cnt,
                "; and total this genus: ", gen_name, " have images: ", imgfileL))
  } else {
    print(paste0("Correct fetch image number: ", cur_fig_cnt, " in genus: ", gen_name))
  }
  ######### Start Pagination #####
  ################################
  page_length_def <- 30
  kinc <- seq(pre_kcnt+1, keycnt) ##keycnt increment this time
  if (length(kinc)>=page_length_def) {
    start_taxon <- which(dtk$kcnt>pre_kcnt & !is.na(dtk$figs))[1]
    start_fig <- which(dtk$kcnt>pre_kcnt & dtk$type==2)[1]
    key_num <- start_fig-1-pre_kcnt
    key_start_num <- start_taxon-1-pre_kcnt
    if (key_start_num<10 & (key_num - key_start_num)<=page_length_def) {
      print(paste0("Genus: ", gen_name, " split 1 page: ", page_cnt, " with key_num: ", key_num))
      page_cnt <- page_cnt + 1
    } else if (key_start_num >= 0.5*key_num) {
      fig_topgx <- as.integer(unlist(tstrsplit(dtk[start_taxon,]$figs, ","), use.names = F))
      dtk[kcnt>start_taxon, page:=page_cnt+1]
      dfk[kcnt>start_taxon & !fidx %in% fig_topgx, page:=page_cnt+1]
      print(paste0("Genus: ", gen_name, " split 2 page: ", page_cnt, page_cnt+1, " with key_num: ", key_num))
      page_cnt <- page_cnt + 2
    } else {
      pg_len <- page_length_def - 5 ## Assume normally 30 keys have at least 5 figs appended
      #res_kinc <- length(kinc) - start_taxon
      pgx <- as.integer(key_num/pg_len)
      modx<- key_num %% pg_len
      if (modx>10) {
        pgx <- pgx + 1 # let add one more page
        pg_len <- as.integer(key_num/pgx)
      }
      pre_start <- pre_kcnt + 1
      for (p in seq_len(pgx)) {
        k_topgx <- seq(pre_start, ifelse(p==pgx, start_fig-1, pre_start+pg_len-1))
        fig_topgx <- unique(as.integer(na.omit(unlist(tstrsplit(dtk[k_topgx,]$figs, ","), use.names = F))))
        figk <- unique(dfk[fidx %in% fig_topgx,]$kcnt)
        #check: dfk[fidx %in% fig_topgx, .(fidx,kcnt,tokcnt,rid,taxon)]
        #check/BUT it may not equal because sex not equal
        #if (!identical(sort(unique(na.omit(dtk[kcnt %in% k_topgx,]$taxon))), sort(unique(dtk[kcnt %in% figk,]$taxon)))) {
        #  print(paste0("Error!! check genus: ", gen_name," Not equal taxon_list when split key/figs in pagnation: ", paste0(k_topgx, collapse=",")))  
        #  print(paste0(sort(unique(na.omit(dtk[kcnt %in% k_topgx,]$taxon))), collapse=","))
        #  print(paste0(sort(unique(dtk[kcnt %in% figk,]$taxon)), collapse=","))
        #  stop("check it!")
        #}
        kt <- unique(c(k_topgx, figk))
        kt <- kt[kt %in% kinc] #may overlap previous kt that been deleted, due to key/figs not 1-to-1
        #if (any(!kt %in% kinc)) {
        #  stop("Check pagination when k not in kinc!!")
        #}
        kinc <- kinc[!kinc %in% kt]
        if (p==pgx & length(kinc)!=0) {
          kt1 <- which(dtk$kcnt %in% kinc & grepl("\\_xx\\_", dtk$unikey)) #& dtk$genus==gen_name
          #kt1 <- kt1[kt1 %in% kinc]
          if (any(kt1)) {
            kt <- c(kt, kt1)
            kinc <- kinc[!kinc %in% kt1]
          }
        }
        if (p>1) { #when p==1 no need to change dtk, dfk because they already set-up to this page
          dtk[kcnt>=pre_start & kcnt %in% kt, page:=page_cnt+p-1]
          dfk[kcnt>=pre_start & kcnt %in% kt, page:=page_cnt+p-1]
        }
        if (p<pgx) { pre_start <- pre_start+pg_len }
      }
      if (length(kinc)!=0) {
        print(paste0("Error!! check genus: ", gen_name," Not totally use all keys in pages"))
        stop("check it!!")
      }
      print(paste0("Genus: ", gen_name, " split ", pgx," pages: ", page_cnt,":", page_cnt+p-1, 
                   " with key_num: ", key_num, " and pages in each group: ",
                   paste0(dtk[genus==gen_name, .N, by=.(page)]$N, collapse=",")))
      page_cnt <- page_cnt + pgx
    }
  } else { #only one page
    print(paste0("Genus: ", gen_name, " split only 1 page: ", page_cnt, " with key_cnt: ", length(kinc)))
    page_cnt <- page_cnt + 1
  }
  pre_kcnt <- keycnt
  print(paste0("Pagination for genus: ", gen_name, " is ok! Current key_cnt is: ", pre_kcnt,
               " and Next doc, Page will start at: ", page_cnt))
}  

#just check
dtk[,.N, by=.(page, docn)]
which(duplicated(dtk$unikey) | duplicated(dtk$unikey, fromLast = T))

which(duplicated(dfk$fidx) | duplicated(dfk$fidx, fromLast = T))

# check caption
tt <- dfk[,.(taxon, fidx, subfig, fsex, caption)][, cap:=substr(dfk$caption,1,20)][, caption:=NULL]
# tt[(nrow(tt)-50):nrow(tt),]
tt1 <- unique(dtk$unikey)
tt2 <- gsub("_", " ", gsub("_xx_fig", "", tt1[grepl("xx",tt1)]))
tt2[which(!tt2 %chin% handle_xx_fig)]

cat(na.omit(dtk$ctxt), file=paste0(web_dir, "web_tmp.txt"))

## output source html_txt, fig file
dtk1 <- copy(dtk)
dtk1[,ctxt:=#gsub("\\.jpg", ".png",  #try just use jpg #20211024
            gsub("\\\n", "", gsub("\\“|\\”",'\\"', ctxt))]
dtk1[,kcnt:=kcnt+1000L] #### 2021114 let genus key in front of species key
fwrite(dtk1,file="doc/newsp_htm_extract.csv")
fwrite(dfk, file="doc/newsp_fig_extract.csv")

length(unique(na.omit(dtk$ckey))) #187
#which(!1:187 %in% unique(na.omit(dtk$ckey)))
nrow(unique(dtk[!is.na(ckey)|!is.na(subkey),])) #391
