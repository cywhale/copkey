## Version 5: Specific version for species key for Shih new work 202107
library(officer)
library(odbapi)
library(data.table)
library(magrittr)
#library(stringr)

key_src_dir <- "D:/ODB/Data/shih/shih_5_202107/Key"
web_dir <- "www_sp/"
web_img <- paste0(web_dir, "img/")
doc_imgdir <- "doc/sp_key_zip/"

skipLine <- 4L
#webCite <- "from the website <a href='https://copepodes.obs-banyuls.fr/en/' target='_blank'>https://copepodes.obs-banyuls.fr/en/</a> managed by Razouls, C., F. de Bovée, J. Kouwenberg, & N. Desreumaux (2015-2017)"
#options(useFancyQuotes = FALSE)
# some unicode should be replaced: <U+00A0> by " ", dQuote() by "
# some special character should be replaced in docx, otherwise docx_summary lost it:
# 24 => ° 18 -> 'N

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

sp2namex <- function(spname, trim_subgen=TRUE) {
  chkver <- as.numeric(as.character(packageVersion("odbapi")))
  #print(paste0("check odbapi version: ", chkver))
  if (!is.na(chkver) & chkver >= 0.73) {
    #odbapi got bugs need modified(20210815) if "Aetideopsis armata (Boeck, 1872)" and use simplify_two = T, trim.subgen = trim_subgen
    #xsp2 <- odbapi::sciname_simplify(spname, simplify_two = T, trim.subgen = trim_subgen) #note that odbapi_v073 has trim.subgen
    xsp2 <- odbapi::sciname_simplify(spname, simplify_two = T)
    xsp2 <- odbapi::sciname_simplify(xsp2, trim.subgen = trim_subgen)
  } else {
    xsp2 <- odbapi::sciname_simplify(spname, simplify_two = T)
  }
  return(xsp2)
}

italics_spname <- function(xstr, spname) {
  if (is.na(spname) | trimx(spname)=="") return (xstr)
  xsp2 <- sp2namex(spname)
  xspt <- sp2namex(spname, trim_subgen=FALSE)
  xsp1 <- odbapi::sciname_simplify(spname, simplify_one = T) #get a old alternative spname in caption
  chk_sp1 <- regexpr(gsub("\\s","\\\\s",gsub("\\)","\\\\)",gsub("\\(","\\\\(",spname))),xstr)
  chk_sp2 <- regexpr(gsub("\\s","(\\\\s|\\\\s\\\\((?:.*)\\\\)\\\\s)",xsp2),xstr) #match e.g. Acartia (Acartiura/whatever) hongi
  chk_sp3 <- regexpr(gsub("\\s","\\\\s",gsub("\\)","\\\\)",gsub("\\(","\\\\(",xspt))),xstr)
  #chk_gsp <- regexpr(paste0("(A|a)s\\s",xsp1,"(\\s[a-z]{1,}(\\s|\\.))"),xstr) #if detect "As Acartia hongi" substr need +3
  #special genus pattern #"Euaetideus"
  spe_gen <- c(xsp1, "Euaetideus")
  chk_gsp <- gregexpr(paste0("(", paste(spe_gen, collapse="|"),")(\\s[a-z]{1,}(\\s|\\.))"),xstr)
  chk_abbrev <- gregexpr(paste0(substr(gen_name, 1, 1),"\\.\\s[a-z]{3,}(?!(\\s|\\.|\\(|\\)|\\,|\\:|$))"), xstr, perl = T)
   
  if (chk_sp1<0 & chk_sp2<0 & chk_sp3<0 & chk_gsp[[1]][1]<0 & chk_abbrev[[1]][1]<0) return(xstr)
  
  str1 <- xstr
  if (chk_abbrev[[1]][1]>0) {
    xspx <- c()
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
    if (!all(xspx2 %chin% unique(xspx))) {
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
  iprex <- "Fig."
  xstr <- gsub("\\sfig\\.", " Fig.", gsub("\\splate", " Plate", xstr))
  if (all(grepl("Plate|Pl\\.", subfig))) {
    if (grepl("\\sPlate", xstr)) {
      iprex <- "Plate"
    } else if (grepl("\\sPl.", xstr)) {
      iprex <- "Pl."
    } else {
      if (print_info) print(paste0("Warning: Detect Plate as subfig but NO Plate, Pl. in xstr, use empty prex: ", xstr))
      iprex <- ""
    }
    subx <- gsub("Plate|Pl\\.", iprex, subfig)
    xsubf <- subx[idx]
  } else {
    subx <- subfig
  }
  iprext <- gsub("\\.", "\\\\.", iprex) #the following, also can match 20d (John, 1999. plate 24)
  xt <- as.integer(trimx(gsub("(?![0-9]+)[a-z]*", "", gsub("\\s*\\((?:.*)\\)", "", gsub(iprext, "", xsubf)), perl=T))) ## some subfig with: 1 (John, 1999. plate 24)
  if (!is.na(xt)) {
    xt <- as.integer(trimx(gsub("(?![0-9]+)[a-z]*", "", gsub("\\s*\\((?:.*)\\)", "", gsub(iprext, "", subx)), perl=T)))
    if (all(!is.na(xt))) {
      if (print_info) print(paste0("Warning: Detect integer: ", xsubf,", use ", iprex, ": ", paste(subx, collapse=",")))
      xc <- sapply(xt, function(x) {regexpr(paste0(iprext,"*\\s*",x), xstr)}, simplify = T, USE.NAMES = F)
      if (!all(xc>0)) {
        if (print_info) {
          print(paste0("Warning: Detect subfig is integer but not all found: ", 
                       paste(subfig, collapse=","), " and founded: ", paste(xc, collapse=","), 
                       " Check this str: ", xstr))
        }
      }
      return (xc)
    } else {
      if (print_info) {
        print(paste0("Warning: Detect integer: ", xsubf,", But CANNOT use Fig. ", paste(subfig, collapse=","),
                   " Check this str: ", xstr)) #Use default (the following) matching, then
      }   
    }
  }
  
  if (grepl("\\&|\\/", xsubf)) {
    if (print_info) print(paste0("Warning: Detect multiple name in subfig: ", xsubf,", use first: ", gsub("\\s*(\\&|\\/){1}(?:.*)+$", "", xsubf)))
    xsubf <- gsub("\\s*(\\&|\\/){1}(?:.*)+$", "", xsubf)
  }
  #chk_sub <- regexpr(paste0("(?=([A-Z]{1,1}\\.*\\s*){0,1})", xsubf), xstr, perl = T)
  return(regexpr(paste0("^(([A-Z]\\.(\\-[a-z]\\.*)*\\s*){0,})",   #also can match Q.-c Chen or Q. C. Chen
                        gsub("\\s*\\,\\s*", ", ", xsubf)), xstr)) #make Sewell,1914 -> Sewell, 1914
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
                  xdtk=character(), taxon=character(), subgen=character(),
                  genus=character(), family=character()) #rid link to dtk, xdtk link to key of dtk

#Note: figs is type=2
dtk <- data.table(rid=integer(), unikey=character(), ckey=character(), 
                  subkey=character(), pkey=character(),
                  figs=character(), type=integer(), nkey=integer(), 
                  taxon=character(), abbrev_taxon=character(), fullname=character(),
                  subgen=character(), genus=character(), family=character(), 
                  epithets=character(), keystr=character(), ctxt=character(), fkey=character(),
                  sex=character()) #, keyword=character()) #, page=integer())

doclst <- list.files(key_src_dir, pattern="^Key?(.*).docx$",full.names = T)
cntg <- 0L
cntg_fig <- 0L
blk_cnt <- 0L
#docfile <- doclst[1]


for (docfile in doclst[1:3]) {
  dc0 <- read_docx(docfile) ######################## 20191014 modified
  ctent <- docx_summary(dc0)

  fn <- tstrsplit(docfile, "/") %>% .[[length(.)]]
  lfn <- regexpr("^(Key to the species of\\s)(?:[a-zA-Z]{1,})\\s", fn)
  fam_name <- substr(fn, nchar('Key to the species of ')+1, lfn+attributes(lfn)$match.length-2L)
  fnt<- paste0('^(Key to the species of ', fam_name, '\\s)(?:[a-zA-Z]{1,})\\s')
  lfn <- regexpr(fnt, fn)                   
  gen_name <- substr(fn, nchar(paste0('Key to the species of ', fam_name, ' '))+1, 
                     lfn+attributes(lfn)$match.length-2L)
  
  lfn <- regexpr("^(Key to the species of\\s)(?:[a-zA-Z]{1,})\\s", ctent[1,]$text)
  gen_chk <- substr(ctent[1,]$text, nchar('Key to the species of ')+1, lfn+attributes(lfn)$match.length-2L)
  
  if (gen_chk == gen_name) {
    print(paste0("Now we got genus: ", gen_name, " to start..."))
    cntg <- cntg+1L
    
  } else {
    print(paste0("Genus name not right check: ", gen_name, " before starting!"))
    break
  }
  
  #epithets list #insert spacing between (subgenus)epithets,epithets
  epi_list <- trimx(gsub("\\s\\,", "\\,", gsub("(?!^\\()(?![a-zA-Z]{1,})\\(", ", (",
              gsub("(?![a-zA-Z]{1,})\\)", ") ",     
              gsub("(?![a-zA-Z]{1,})\\,", ", ",ctent[3,]$text, perl=T), perl=T), perl=T)))
  titletxt <- paste0("<div class=", dQuote("kblk"), "><span class=", dQuote("doc_title"), ">", italics_spname(ctent[1,]$text, gen_name), "</span></div><br><br>")
  epitxt <- paste0(titletxt, "<div class=", dQuote("kblk"), "><span class=", dQuote("doc_epithets"), ">", 
    unlist(tstrsplit(epi_list, "\\,\\s*"), use.names = F) %>%
      sapply(function(x) {
        paste0("<em>", x, "</em>")
      }, simplify = T, USE.NAMES = F) %>% paste(collapse=", "), "</span></div><br>\n\n")
    
  epi_list <- trimx(gsub(paste0("(?!\\()", gen_name, "(?!\\))"), "", epi_list, perl = T)) #Some (Subgen) == gen_name cannot be filtered
  #for example: c("(Acartia) abc", "Acartia ddd") -> "(Acartia) abc" "ddd" 
  
  dtk <- rbindlist(list(dtk,data.table(rid=0, unikey= paste0("gen_", cntg), 
                                       ckey= NA_character_, subkey= NA_character_, pkey= NA_character_,
                                       figs=NA_character_, type=NA_integer_, nkey=NA_integer_, 
                                       taxon=NA_character_, abbrev_taxon=NA_character_, fullname=NA_character_,
                                       subgen=NA_character_, genus=gen_name, family=fam_name, epithets=epi_list, 
                                       keystr=NA_character_, ctxt=epitxt, fkey=NA_character_, 
                                       sex=NA_character_))) #, keyword=NA_character_)))
  tstL <- nrow(ctent)

  epiall <- trimx(gsub("\\((?:.*)\\)", "", unlist(tstrsplit(dtk[rid==0 & genus==gen_name & family==fam_name,]$epithets, ","), use.names = F)))
  print(paste0("We have these sp: ", gen_name, " ", paste(epiall, collapse=", ")))

  i = skipLine+1L
  st_conti_flag <- FALSE
  keyx <- ""; prekeyx <- ""; subkeyx <- ""
  pret <- ""
  subgen <- ""
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
  doc_fign<- 0 ## cntg_fig is counter of all fig num in total docs (stored in fig_num), doc_fign just for one doc file
  fig_exclude <- "\\(F\\,\\s*M\\)" #exclude pattern in title/main: (F,M)
  
  while (i<=tstL) {
    x <- gsub("\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i]))))

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
        print(paste0("Warning: Now handle Figures at i: ", i))
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
        
          if (grepl("\\/", keyx)) {
            prekeyx <- tstrsplit(keyx, "/")[[2]]
            keyx <- tstrsplit(keyx, "/")[[1]]
          } else {
            prekeyx <- ""
          }   
        
          if (i== skipLine+1L) { #key 1a will repeat in New Version for different genus, must prevent duplication
            pret <- paste0('<div class=', dQuote('kblk'), '><p class=', dQuote('leader'), 
                           '><span class=',dQuote('keycol'),'>',
                           '<mark id=', dQuote(paste0('key_', gen_name, "_", keyx)), '>', keyx, '</mark>')
          } else {
            ### 20191015 modified to put </div> in previous dtk, so I can flush image earilier because <div>...</div> cannot be broken
            ### dtk[nrow(dtk), ctxt:=paste0(ctxt,'</div>')] ## previous change is wrong because maginnote should be inside <div>..</div>
            pret <- paste0(pret,'</div><div class=', dQuote('kblk'), '><p class=', dQuote('leader'), 
                           '><span class=',dQuote('keycol'),'>',
                           '<mark id=', dQuote(paste0('key_', gen_name, "_", keyx)), '>', keyx, '</mark>')
          }
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
        mat_subgen1 = paste0("((?:…*\\.*\\s*)(\\()(?:[A-Z][a-z]{1,}(.*)\\)))|", 
                               "((?:…+\\.*\\s*)([A-Z])(?:[a-z]{1,}(?:…+|\\.+)))")
        # cannot match spacing because may a species name, not subgenus (only one word)
        # i.e. cannot match (but can match ...(Subgenus Euacartia))...)
        # regexpr(mat_subgenus, "of urosomites smooth…………....……………………Euacartia …..28", perl=T)
        # use ?= to get only start position, but here we need length to get whole subgenus
        wl2 <- regexpr(mat_subgen1, x2, perl=T)
      
        if (wl2>0) {
          subgen <- gsub("\\(Subgenus |\\(Subgen |\\(|\\)|…|\\.|\\s", "", substr(x2, wl2+1, wl2+attributes(wl2)$match.length-1))
          print(paste0("Find Subgenus: ", subgen, " in i, keyx: ", i, ", ", keyx))
        
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
        mat_sp1 = paste0("(?:(…+\\.*\\s*…*|\\.{2,}…*\\s*))(([A-Z])\\.\\s*|", gen_name, "\\s)[a-z]{1,}$")
        wl3 <- regexpr(mat_sp1, x2, perl=T)
        if (wl3>0) {
          nsp <- gsub("\\.", "\\. ", gsub("^\\.", "", gsub("…|\\.{2,}|\\s(?![a-z]+)", "", substr(x2, wl3+1, nchar(x2)), perl=T))) #equal wl2s+attributes(wl2s)$match.length-1)   
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
              xsp <- nsp
            }
          }
          epithet <- gsub(paste0(gen_name, " "), "", xsp)
          keystr <- gsub("\\.$", "", trimx(gsub("…|\\.{2,}", "", substr(x2, 1, wl3))))
          pret <- paste0(pret, keystr)
          
        } else {
          wl3 <- regexpr("(?:(…+\\.*\\s*|\\.{2,}…*\\s*))[0-9]+$",x2)
          
          if (wl3<0) {
            if (!st_conti_flag) {
              st_conti_flag <- TRUE
              i <- i+1
              next
            } else {
              print("Too many cutted-line! check it!")
              break
            } 
          }
          nxtk <- as.integer(gsub("…|\\.","",substr(x2,wl3+1,nchar(x2))))
          stopifnot(!any(is.na(nxtk)))
          nxttype <- 0L
          if (keystr=="") { #no subgen, so no keystr fetched
            keystr <- trimx(gsub("\\.\\s*$", "", gsub("…|\\.{2,}", "", substr(x2, 1, wl3))))
            pret <- paste0(pret, keystr)
          }
        }
        
        if (nxttype==1L) {
          xc <- paste0(pret,
                       '</span><span class=',dQuote('keycol'),'>',
                       paste0('<mark id=',  dQuote(paste0('taxon_', gsub("\\s","_",xsp))), 
                              '><em><a href=', dQuote(paste0('#fig_', gsub("\\s","_", xsp))), '>', xsp, '</a></em></mark></span></p>'))
          
        } else if (subgen!="" | nxtk!=0L) {
          if (grepl("\\,", subgen)) { #with multiple subgenus
            subgx <- trimx(unlist(tstrsplit(subgen, ","), use.names = F))
            subgen<- paste(subgx, collapse=", ") #to make format consistently
            
            xc0 <- do.call(function(x) {paste0('<mark id=',dQuote(paste0('subgen_', x)),'><em>', x, '</em></mark>')}, list(subgx)) %>%
              paste(collapse=",&nbsp;")
            
            xc <- paste0(pret, '</span>&nbsp;<span class=',dQuote('keycol'),'>', 
              paste0('(', xc0, ')'),
              #using markdown
              #paste0('[', nxtk, '](#key_', gen_name, "_", nxtk,'a)'), 
              paste0('<a href=', dQuote(paste0('#key_', gen_name, "_", nxtk,'a')), '>', nxtk,'</a>'), 
              '</span></p>')
          } else {
            xc <- paste0(#gsub("…|\\.{2,}|…\\.{1,}|\\.{1,}…","",
              #ifelse(st_conti_flag, xc, substr(xc,1,nchar(xc)-stt))),
              pret, '</span>&nbsp;<span class=',dQuote('keycol'),'>', 
              ifelse(subgen=="", "", paste0('<mark id=',dQuote(paste0('subgen_', subgen)),'>(<em>', subgen, '</em>)</mark>')),
              #using markdown
              #paste0('[', nxtk, '](#key_', gen_name, "_", nxtk,'a)'),
              paste0('<a href=', dQuote(paste0('#key_', gen_name, "_", nxtk,'a')), '>', nxtk,'</a>'), 
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
        print(paste0("Warning: No Subkey found for keyx: ", keyx, " of genus: ", gen_name, " at i: ", i))
      }
      prekeyn <- as.integer(gsub("[a-z]", "", prekeyx))
      if (is.na(prekeyn)) {
        prekeyn <- 0L
      }

      if (substr(keystr,1,6)=="Female") {
        female_start <- nxtk
        xsex_flag <- TRUE
        print(paste0("Note: Female key after: ", nxtk, " of genus: ", gen_name, " at i: ", i))
      }
      if (substr(keystr,1,4)=="Male") {
        male_start <- nxtk
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
      subgen <- ifelse(subgen=="", NA_character_, subgen)

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
        
        dtk <- rbindlist(list(dtk,data.table(rid=i, unikey=paste0(gen_name, "_", keyx),
                                             ckey= keyx, subkey= subkeyx, pkey= prekeyx,
                                             figs=NA_character_, type=nxttype, nkey=nxtk, 
                                             taxon=xsp, abbrev_taxon=nsp, fullname=NA_character_,
                                             subgen=subgen, genus=gen_name, family=fam_name,
                                             epithets=NA_character_, keystr=keystr, ctxt=xc, fkey=NA_character_, 
                                             sex=xsex))) #keyword=NA_character_)))
      } else {
        xc <- paste0('</div><div><p class=',dQuote(paste0(indentx, ' lxbot')), '><span class=', 
                     dQuote(padx), '><em>', paste(epix, collapse="</em>, <em>"), '</em></span></p>')
        xc0 <- gsub("<p class(.*?)><span", 
                    paste0('<p class=',dQuote(paste0('leader ', indentx, ' lxtop')), '><span'), 
                    dtk[nrow(dtk),]$ctxt)
        dtk[nrow(dtk), ctxt:=paste0(xc0, xc)]
      }
    
      #if (nxttype==1L | subgen != "" | nxtk != 0L) {
      st_conti_flag <- FALSE
      keyx <- ""; prekeyx <- ""; subkeyx <- ""
      pret <- ""
      subgen <- ""
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
  
  dtk[nrow(dtk), ctxt:=paste0(dtk[nrow(dtk),]$ctxt, '</div><br><br>\n\n')]
  print(paste0("Checking fig_mode: ", fig_mode))
  chkt <- dtk[!is.na(taxon), .(taxon, sex)]
  if (any(duplicated(chkt))) {
    print(paste0("Warning: Duplicated taxon, sex. Check it: ", 
                 paste0(chkt[duplicated(chkt),]$taxon, collapse=", "),
                 " of genus: ", gen_name))
  }

  #i <- 195L #just when test first doc file #i<=232L before p.12 #i<=tstL #245L p13 #292L before p19 #351L p25
  while (fig_mode & nrow(dtk)>0 & i<=tstL) {
    x <- gsub("\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i]))))
    wa <- regexpr("\\(Size",x)
    if (wa>0) {
      spname<- trimx(substr(x, 1, wa-1))
      sattr <- substr(x, wa, nchar(x))
    } else {
      spname<- trimx(gsub(fig_exclude, "", x))
      sattr <- ""
    }
    
    fig_main <- trimx(gsub(fig_exclude, "", x)) #changed to full_name + sattr with link to ckey when stored in dtk ctxt
    xsp2 <- sp2namex(spname)
    x_dtk<- which(dtk$taxon==xsp2 & dtk$type==1L)
    
    if (!any(x_dtk)) {
      print(paste0("Error: Check fig_mode got ?? sp: ", xsp2, " at i: ", i))
      break
    } else {
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
      while (within_xsp_flag) {
        x <- gsub("^\\\t", "", gsub("^\\s+|\\s+$", "", as.character(ctent$text[i])))  
        tt <- which(is.na(x) | gsub("Last update(?:.*)", "", x)=="") #ignore Last update:...
        if (i<tstL & any(tt)) {
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
          xt <- trimx(gsub("\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i])))))
          if (length(subfig)==0 & fig_title=="" & trimx(gsub(fig_exclude,"",xt)) != spname) { #(any(subfig=="")) {
            subfig <- gsub("\\s*\\,\\s*", ", ", #make Sewell,1914 -> Sewell, 1914 with the same format
                        trimx(unlist(tstrsplit(x, '\\s{2,}|\\t'), use.names = F))) #note that sometimes pattern has: "a1   b2 & c3", split to "a1" "b2 & c3" 
            i <- i + 1L
            next
          } else if (fig_title=="") {
            x <- trimx(gsub("\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i])))))
            if (length(subfig)>0) {
              xc <- find_subfigx(x, subfig, 1L, print_info = FALSE)
              if (xc[1]>0) {
                print(paste0("Warning: No fig title provided but detect subfig, use default spname in sp: ", spname))
                fig_title <- spname
                next #Note i cannot add 1 and let it go to fig_caption detection
              }
            }
            
            x <- gsub(fig_exclude, "", x)  
            if (x!=spname) {
              print(paste0("Warning: Not equal fig title with spname, check it fig_titile: ", x, "  at i:",  i))
              tt <- sp2namex(x)
              if (tt!=xsp2) {
                print(paste0("Error: Not equal short fig title with taxon, check it fig_title: ", x, "  at i:",  i))
                break
              } else {
                fig_title <- x
              }
            } else {
              fig_title <- x
            }
            i <- i + 1L
            next
          } else {
            x <- trimx(gsub("\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i])))))
            wa <- regexpr("\\(Size",x)
            xsp1 <- trimx(odbapi::sciname_simplify(x, simplify_one = T))
            if (i==tstL | wa>0 | (xsp1==gen_name & trimx(sp2namex(x)) != xsp2)) {
              if (wa<0) {
                spt <- trimx(gsub(fig_exclude, "", x))
              } else {
                spt<- trimx(substr(x, 1, wa-1))
              }
              if (i==tstL | spt != spname) {
                if (i==tstL) {
                  print(paste0("End of doc: ", docfile))
                } else {
                  print(paste0("Start next sp: ", spt, "  at i:",  i)) #cannot add i, repeated this step though..
                }
                within_xsp_flag <- FALSE #A species is completed its record, and go into next sp! 
                
                blk_cnt <- blk_cnt + 1
                #flink <- sapply(fig_num, function(x) {
                #  paste0("fig_", gsub("\\s", "_", xsp2), "_", padzerox(x))
                #}, simplify = T)
                fkey <- substring(gsub("www_sp\\/img\\/|\\.jpg", "", imgf), 6)
                fnum <- gsub("_", "", gsub(gsub("\\s", "_", xsp2), "", fkey))
                
                cap_cite <- data.table(cap=fig_caption, 
                                       cite=c(fig_citation, rep(NA_character_, length(fig_num)-length(fig_citation))))

                citex <- cap_cite[!is.na(cite),]$cite[1]
                cap_cite[is.na(cap), cap:=fig_caption[!is.na(fig_caption)]] 
                cap_cite[is.na(cite), cite:=ifelse(grepl("Original", cap), "Original", citex)]
                
                if (!any("female/male" %chin% dtk[x_dtk,]$sex)) {
                  key_sex <- rbindlist(list(dtk[x_dtk, .(ckey, sex)],
                                            data.table(ckey=paste(dtk[x_dtk,]$ckey, collapse = ","),
                                                       sex="female/male")))
                } else {
                  key_sex <- dtk[x_dtk, .(ckey, sex)]
                }
                
                malekey <- ifelse("male" %chin% key_sex$sex, key_sex[sex=="male",]$ckey, key_sex[sex=="female/male",]$ckey)
                femalekey <- ifelse("female" %chin% key_sex$sex, key_sex[sex=="female",]$ckey, key_sex[sex=="female/male",]$ckey)
                keymat <- chmatch(fsex, key_sex$sex) #cannot just use key_sex[chmatch(fsex, sex),]$ckey because may lost match
                keymat[is.na(keymat)] <- chmatch("female/male", key_sex$sex)
                ckeyx <- key_sex[keymat,]$ckey
                
                fdlink <- paste0("fig_", gsub("\\s", "_", xsp2)) #, "_", paste(fnum, collapse="-"))

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
                if (any(is.na(fig_caption))) {
                  fig_caption <- fig_caption[!is.na(fig_caption)]
                }
                if(length(subfig)==0) {
                  xsubf <- ""
                } else {
                  xsubf <- subfig
                }
                
                #"Acartia (Acanthacartia) bilobata Braham, 1970" ->
                # Acartia (Acanthacartia) bilobata (Braham, 1970)
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
                    gsub("(\\;\\s*|\\s)(M|m)ale\\,*\\s*", 
                      paste0("; <a href=", dQuote(paste0("#key_",gen_name,"_",malekey)), ">male</a>, "), 
                      gsub("\\s*(F|f)emale\\,*\\s*", 
                           paste0(" <a href=", dQuote(paste0("#key_",gen_name,"_",femalekey)), ">female</a>, "), sattr)))
                } else {
                  fig_main = full_name
                  fig_mtxt = paste0(full_name, " ",
                                    paste0("<a href=", dQuote(paste0("#key_",gen_name,"_",femalekey)), ">female</a>; "),
                                    paste0("<a href=", dQuote(paste0("#key_",gen_name,"_",malekey)), ">male</a>)")) 
                }
                
                dfkt <- data.table(fidx=fig_num, fkey=fkey,
                                   ckeyx=ckeyx, #rep(paste(dtk[x_dtk,]$ckey, collapse = ","), length(fig_num)),
                                   imgf=gsub("www_sp\\/", "", imgf), 
                                   fsex=fsex, #rep(NA_character_, length(fig_num)),
                                   main= fig_main,  #c(fig_main, rep(NA_character_, length(fig_num)-1L)),
                                   title=full_name, #c(full_name,rep(NA_character_, length(fig_num)-1L)),
                                   subfig= subfig, caption= cap_cite$cap, 
                                   citation= cap_cite$cite, #may be null, so use fill=NA
                                   flushed=rep(paste(fig_num, collapse = ","), length(fig_num)), ## flushed means flush figs in a row
                                   blkx=blk_cnt, docn=cntg, rid=i, xdtk=paste(x_dtk, collapse=","),
                                   taxon=xsp2, subgen=subgenx,
                                   genus=gen_name, family=fam_name) ### blkx: counter of block of fig, docn: nth document
                
                dfk <- rbindlist(list(dfk, dfkt), fill = TRUE) 
                
                
                dtk[x_dtk, `:=`(
                  fullname = full_name,
                  subgen = subgenx,
                  epithets = epit, 
                  figs = sapply(sex, function(x) {
                    if (x=="male") {
                      fk <- dfkt[fsex=="male" | fsex=="female/male",]$fidx
                    } else if (x=="female") {
                      fk <- dfkt[fsex=="female" | fsex=="female/male",]$fidx
                    } else {
                      fk <- dfkt$fidx
                    }
                    return(paste(fk, collapse=","))
                  }, simplify = TRUE, USE.NAMES = FALSE),
                  fkey = sapply(sex, function(x) { #cannot just use grepl because "female" contains "male"
                    if (x=="male") {
                      fk <- dfkt[fsex=="male" | fsex=="female/male",]$fkey
                    } else if (x=="female") {
                      fk <- dfkt[fsex=="female" | fsex=="female/male",]$fkey
                    } else {
                      fk <- dfkt$fkey
                    }
                    return(paste(fk, collapse=","))
                  }, simplify = TRUE, USE.NAMES = FALSE)
                )]
                
                dtk <- rbindlist(list(dtk, data.table(rid=i, unikey=fdlink,
                                      ckey= NA_character_, subkey= NA_character_, pkey= NA_character_,
                                      figs=paste(fig_num, collapse = ","), type=2L, nkey=NA_integer_, 
                                      taxon=xsp2, abbrev_taxon=dtk[x_dtk[1],]$abbrev_taxon, fullname=full_name,
                                      subgen=subgenx, genus=gen_name, family=fam_name,
                                      epithets=epit, keystr=keystr, 
                                      ctxt=paste0(paste(paste0('\n\n<div id=', dQuote(fdlink),'><span class=', dQuote('blkfigure'),'>'), 
                                                 paste0('<div class=', dQuote("fig_title"),'><span class=', dQuote('spmain'), '>', italics_spname(fig_mtxt, spname),'</span></div>'),
                                                 mapply(function(outf,flink,cfigx,spanx) {
                                                   paste0('<span class=', dQuote(spanx), '><a class=', dQuote("fbox"), 
                                                          ' href=', dQuote(outf),
                                                          #' data-alt=', dQuote(paste0(capx)),
                                                          ' /><img src=',
                                                          dQuote(outf), ' border=', dQuote('0'),
                                                          ' /></a><span id=', dQuote(paste0("fig_",flink)), ' class=', dQuote('spnote'),
                                                          '>',cfigx, #' *',sp,'* ',sex,
                                                          #' [&#9754;](#key_',ckeyx,') &nbsp;', fdupx,
                                                          '</span></span>') ############ Only MARK duplicated imgf
                                                   },outf=gsub("www_sp\\/", "", imgf), # No need www_sp/ in html link
                                                     flink=fkey, cfigx=xsubf, #fgcnt=fig_num,
                                                   MoreArgs = list(spanx=spanx), SIMPLIFY = TRUE, USE.NAMES = FALSE) %>% 
                                                 paste(collapse=" "),'</span></div>', 
                                                 paste0('<div class=', dQuote("fig_title"),'><span class=', dQuote('spnote'), '>', italics_spname(full_name, spname),'</span></div>'),
                                                 sapply(seq_along(fig_caption), function(k) { #citex, capx, 
                                                   citex=fig_citation; capx=fig_caption
                                                   cx <- ifelse(is.na(citex[k]) | citex[k]=="", "", 
                                                                paste0('<div class=', dQuote('fig_cite'), '><span class=', dQuote('spnote'), '>', italics_spname(citex[k], spname),'</span></div>'))
                                                   out <-paste0('<div class=', dQuote('fig_cap'), '><span class=', dQuote('spnote'), '>',
                                                     bold_spsex(italics_spname(capx[k], spname)), '</span></div>', cx)
                                                   return(out)
                                                  }, #citex=fig_citation, capx=fig_caption, 
                                                  #MoreArgs = list(k=seq_along(fig_caption)), SIMPLIFY = TRUE, 
                                                  simplify = TRUE, USE.NAMES = FALSE) %>%
                                                  paste(collapse="<br>"), 
                                                  sep="<br>"), ifelse(i==tstL, "<br><br><br><br>\n\n", "")),
                                      fkey=paste(fkey, collapse=","), 
                                      sex=NA_character_))) #, keyword="figs"))) #figs is type =2
                next
              } else {
                print(paste0("Warning: Format not consistent to get the same sp: ", spt, "  Check it at i:",  i))
                break 
              }
            } else {
              #if (length(fig_caption)==0) {
                flag_getcap <- FALSE
                xc <- c(-1)
                if (length(subfig)>0 & imgj < length(subfig)) {
                  xc <- find_subfigx(x, subfig, imgj+1)
                }
                if (length(subfig)==0 & length(fig_caption)==0) { #only one fig in this row and not read any fig_caption yet
                  flag_getcap <- TRUE
                } else if (imgj >= length(subfig)) { #End of fetch subfig
                  flag_getcap <- FALSE
                } else if ((xc[1]>0) | #(subfig[imgj+1] == substr(x, 1, nchar(subfig[imgj+1]))) | 
                           (imgj==0 & (("Female" %chin% subfig & grepl("Female", x)) |
                                       ("Male" %chin% subfig & grepl("Male", x))))) {
                  flag_getcap <- TRUE
                }
                if (flag_getcap) {    
                  k <- 1
                  if (length(subfig)>0) {
                    if (xc[1]<0) { #subfig[imgj+1] != substr(x, 1, nchar(subfig[imgj+1]))) {
                      if (imgj==0 & ("Female" %chin% subfig & grepl("Female", x)) &
                          ("Male" %chin% subfig & grepl("Male", x))) {
                        k <- 2 # one description (x) contains two subfigs
                      }
                    } else if (imgj==0 & length(xc)>1 & xc[1]>0) {
                      k <- length(xc)
                    } else if (imgj<length(subfig) & xc[1]>0) { #subfig[imgj+1] == substr(x, 1, nchar(subfig[imgj+1]))) {
                      k <- imgj+1 # 2nd run for subfig[2], every time just run 1 turn because wait i+1 description in next turn
                    }
                  }
                  if (length(xc)>1 & k>1) {
                    iprex <- "Fig."
                    xstr <- gsub("\\sfig\\.", " Fig.", gsub("\\splate", " Plate", x))
                    if (all(grepl("Plate|Pl\\.", subfig))) {
                      if (grepl("\\sPlate", xstr)) {
                        iprex <- "Plate"
                      } else if (grepl("\\sPl.", xstr)) {
                        iprex <- "Pl."
                      } else {
                        print(paste0("Warning: Detect Plate as subfig but NO Plate, Pl. in xstr, use empty prex: ", xstr))
                        iprex <- ""
                      }
                    }
                    iprext <- gsub("\\.", "\\\\.", iprex)
                    xseg <- trimx(unlist(tstrsplit(xstr, paste0("(\\s|\\.)", iprext)), use.names = F))
                    if (substr(x, 1, 4) != iprex) { xseg <- xseg[-1] }
                    if (length(xseg) != length(xc)) {
                      print(paste0("Warning: Detect subfig is integer but NOT equal segemnt! Check this str: ", xstr))
                    }
                  } #else {
                    #xseg <- x
                  #}
                  
                  while (imgj<k) {
                  #if (subfig[imgj+1] != "Original") {
                    cntg_fig <- cntg_fig + 1L
                    doc_fign <- doc_fign + 1L
                    fig_num[imgj+1] <- cntg_fig
                    docfn <- unlist(tstrsplit(docfile, "\\/"), use.names = F) %>% .[length(.)]
                    imgsrc <- paste0(doc_imgdir, 
                                     gsub("\\s", "_", gsub("Key to the species of\\s|\\s\\(China seas\\s*[2]*\\)\\.docx", "", docfn)),
                                     "/word/media/image", doc_fign, ".jpeg")
                    if (!file.exists(imgsrc)) {
                      print(paste0("Error: Cannot get the the image file: ", imgsrc, "  Check it at i:",  i))
                      break 
                    }
                    imgf[imgj+1L] <- paste0(web_img, padzerox(cntg_fig, 4), "_",
                                            gsub("\\s", "_", xsp2),
                                            "_", padzerox(doc_fign), ".jpg")
                    if (!file.exists(imgf[imgj+1L])) {
                      system(enc2utf8(paste0("cmd.exe /c copy ", gsub("/","\\\\", imgsrc), 
                                             " ",gsub("/","\\\\",imgf[imgj+1L]))))
                    }
                    if (k>1 & imgj>=1 & (xc[1]<0 | (length(xc)>1 & length(xc)==k))) { #subfig[imgj+1] != substr(x, 1, nchar(subfig[imgj+1]))) {
                      fig_caption[imgj+1L] <- NA_character_ #only one description but contains two subfigs
                    } else {
                      fig_caption[imgj+1L] <- trimx(gsub("°", "&deg;", gsub("\\.Mmale",". Male",gsub("\\.Female",". Female",gsub("\\.{1,}Fig.", ". Fig.", x)))))
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
                        xt <- xseg[imgj+1]
                      } else {
                        xt <- x
                      }
                      if (grepl("(\\s|\\.)Male", xt)) {
                        if (grepl("(\\s|\\.)Female", xt)) {
                          fsex[imgj+1L] <- "female/male"
                        } else {
                          fsex[imgj+1L] <- "male"
                        }
                      } else if (grepl("(\\s|\\.)Female", xt)) {
                        fsex[imgj+1L] <- "female"
                      } else {
                        fsex[imgj+1L] <- NA_character_
                      }
                    } else {
                      fsex[imgj+1L] <- tolower(subfig[imgj+1L])
                    }
                    imgj <- imgj + 1L
                  }  
                  i <- i + 1L
                  next
                  
                } else { #Not another subfig, can be citation of subfig
                  if (length(subfig)>0 & imgj <= length(subfig)) {
                    if (subfig[imgj] == "Original" | substr(x,1,7) != "Adapted") {
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
}  


cat(na.omit(dtk$ctxt), file=paste0(web_dir, "web_tmp.txt"))

## output source html_txt, fig file
fwrite(dtk, file="doc/newsp_htm_extract.csv")
fwrite(dfk, file="doc/newsp_fig_extract.csv")

length(unique(na.omit(dtk$ckey))) #187
which(!1:187 %in% unique(na.omit(dtk$ckey)))
nrow(unique(dtk[!is.na(ckey)|!is.na(subkey),])) #391
