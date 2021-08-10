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
    xsp2 <- odbapi::sciname_simplify(spname, simplify_two = T, trim.subgen = trim_subgen) #note that odbapi_v073 has trim.subgen
  } else {
    xsp2 <- odbapi::sciname_simplify(spname, simplify_two = T)
  }
  return(xsp2)
}

italics_spname <- function(xstr, spname) {
  xsp2 <- sp2namex(spname)
  xspt <- sp2namex(spname, trim_subgen=FALSE)
  chk_sp1 <- regexpr(gsub("\\s","\\\\s",gsub("\\)","\\\\)",gsub("\\(","\\\\(",spname))),xstr)
  chk_sp2 <- regexpr(gsub("\\s","\\\\s(?:.*)",xsp2),xstr)
  chk_sp3 <- regexpr(gsub("\\s","\\\\s",gsub("\\)","\\\\)",gsub("\\(","\\\\(",xspt))),xstr)
  if (chk_sp1<0 & chk_sp2<0 & chk_sp3<0) return(xstr)
  
  if (chk_sp2>0 & chk_sp1 <0 & chk_sp3<0) { #Some text use different subgen in citation that make exactly match A (subgen) epi not work
    xspx <- substr(xstr, chk_sp2, chk_sp2+attributes(chk_sp2)$match.length-1) %>%
      tstrsplit("\\s") %>% unlist(use.names = F)
  } else {
    xspx <- unlist(tstrsplit(xspt, "\\s"), use.names = F)
  }
  str1 <- xstr
  
  for (x in xspx) {
    str1 <- gsub(gsub("\\)","\\\\)",gsub("\\(","\\\\(",x)), paste0("<em>",x,"</em>"), str1)
  }

  return(str1)
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

find_subfigx <- function(xstr, xsubf) {
  #chk_sub <- regexpr(paste0("(?=([A-Z]{1,1}\\.*\\s*){0,1})", xsubf), xstr, perl = T)
  return(regexpr(paste0("^(([A-Z]\\.\\s*){0,})", xsubf), xstr))
}

###############################################################################################
doclst <- list.files(key_src_dir, pattern="^Key?(.*).docx$",full.names = T)
cntg <- 0L
cntg_fig <- 0L
blk_cnt <- 0L
#docfile <- doclst[1]

for (docfile in doclst) {
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
  
  tstL <- nrow(ctent)

#### Used to store figs <-> fig_file mapping
  dfk <- data.table(fidx=integer(), 
                    fkey=character(), ckeyx=character(),
                    imgf=character(), sex=character(), 
                    main=character(), title=character(),
                    subfig=character(), caption=character(), citation=character(),
                    flushed=character(), ## flushed means flush figs in a row
                    blkx=integer(), docn=integer()) ### blkx: counter of block of fig, docn: nth document
  
  dtk <- data.table(rid=integer(), unikey=character(), ckey=character(), 
             subkey=character(), pkey=character(),
             figs=character(), type=integer(), nkey=integer(), 
             taxon=character(), abbrev_taxon=character(), subgen=character(), genus=character(),
             epithets=character(), keystr=character(), ctxt=character(), fkey=character(),
             sex=character(), body=character(), keyword=character()) #, page=integer())

  dtk <- rbindlist(list(dtk,data.table(rid=0, unikey= paste0("gen_", cntg), 
                                     ckey= NA_character_, subkey= NA_character_, pkey= NA_character_,
                                     figs=NA_character_, type=NA_integer_, nkey=NA_integer_, 
                                     taxon=NA_character_, abbrev_taxon=NA_character_, 
                                     subgen=NA_character_, genus=gen_name, epithets=epi_list, 
                                     keystr=NA_character_, ctxt=NA_character_, fkey=NA_character_, 
                                     sex=NA_character_, body=NA_character_, keyword=NA_character_)))

  epiall <- trimx(gsub("\\((?:.*)\\)", "", unlist(tstrsplit(dtk[1,]$epithets, ","), use.names = F)))
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

  while (i<=tstL) {
    x <- gsub("\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i]))))

    tt <- which(is.na(x) | x=="")
    if (any(tt)) {
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
      wl0 <- regexpr("^[A-Z][a-z]{1,}",x)
      if (wl0==1 & nrow(dtk)>0 & ncflag>=1) {
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
            pret0s <- paste0('[', prekeyx, '](#key_',  gen_name, "_", prekeyx, '))&nbsp;') #note it's a md anchor
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
        mat_sp1 = paste0("(?:(…+\\.*\\s*|\\.{2,}…*\\s*))([A-Z])\\.\\s*[a-z]{1,}$")
        wl3 <- regexpr(mat_sp1, x2, perl=T)
        if (wl3>0) {
          nsp <- gsub("\\.", "\\. ", gsub("^\\.", "", gsub("…|\\.{2,}|\\s", "", substr(x2, wl3+1, nchar(x2))))) #equal wl2s+attributes(wl2s)$match.length-1)   
          print(paste0("Find end SP: ", nsp, " in i, keyx: ", i, ", ", keyx, " with equal end: ", nchar(x2)==wl3+attributes(wl3)$match.length-1))
          nxttype <- 1L
          xsp <- gsub("\\s{1,}", " ", gsub(substr(nsp,1,2), paste0(gen_name, " "), nsp))
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
                              '>*<a href=', dQuote(paste0('#fig_', gsub("\\s","_", xsp))), '>', xsp, '</a>*</mark></span></p>'))
          
        } else if (subgen!="" | nxtk!=0L) {
          if (grepl("\\,", subgen)) { #with multiple subgenus
            subgx <- trimx(unlist(tstrsplit(subgen, ","), use.names = F))
            subgen<- paste(subgx, collapse=", ") #to make format consistently
            
            xc0 <- do.call(function(x) {paste0('<mark id=',dQuote(paste0('subgen_', x)),'>*', x, '*</mark>')}, list(subgx)) %>%
              paste(collapse=",&nbsp;")
            
            xc <- paste0(pret, '</span>&nbsp;<span class=',dQuote('keycol'),'>', 
              paste0('(', xc0, ')'),
              paste0('[', nxtk, '](#key_', gen_name, "_", nxtk,'a)'), '</span></p>')
          } else {
            xc <- paste0(#gsub("…|\\.{2,}|…\\.{1,}|\\.{1,}…","",
              #ifelse(st_conti_flag, xc, substr(xc,1,nchar(xc)-stt))),
              pret, '</span>&nbsp;<span class=',dQuote('keycol'),'>', 
              ifelse(subgen=="", "", paste0('<mark id=',dQuote(paste0('subgen_', subgen)),'>(*', subgen, '*)</mark>')),
              paste0('[', nxtk, '](#key_', gen_name, "_", nxtk,'a)'), '</span></p>')
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
      
      xsex = NA_character_
      if (!xsex_flag & nxttype==1L & female_start > 0 & male_start >0) {
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
        
        dtk <- rbindlist(list(dtk,data.table(rid=i, unikey=paste0(gen_name, "_", keyx),
                                             ckey= keyx, subkey= subkeyx, pkey= prekeyx,
                                             figs=NA_character_, type=nxttype, nkey=nxtk, 
                                             taxon=xsp, abbrev_taxon=nsp, subgen=subgen, genus=gen_name,
                                             epithets=NA_character_, keystr=keystr, ctxt=xc, fkey=NA_character_, 
                                             sex=xsex, body=NA_character_, keyword=NA_character_)))
      } else {
        xc <- paste0('</div><div><p class=',dQuote(paste0(indentx, ' lxbot')), '><span class=', 
                     dQuote(padx), '>*', paste(epix, collapse="*, *"), '*</span></p>')
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
  
  dtk[nrow(dtk), ctxt:=paste0(dtk[nrow(dtk),]$ctxt, '</div>')]
  print(paste0("Checking fig_mode: ", fig_mode))
  chkt <- dtk[!is.na(taxon), .(taxon, sex)]
  if (any(duplicated(chkt))) {
    print(paste0("Warning: Duplicated taxon, sex. Check it: ", 
                 paste0(chkt[duplicated(chkt),]$taxon, collapse=", "),
                 " of genus: ", gen_name))
  }

  #i <- 195L #just when test first doc file #i<=232L before p.12 #i<=tstL #247L p13
  while (fig_mode & nrow(dtk)>0 & i<=232L) {
    x <- gsub("\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i]))))
    wa <- regexpr("\\(Size",x)
    if (wa>0) {
      spname<- trimx(substr(x, 1, wa-1))
      sattr <- substr(x, wa, nchar(x))
    } else {
      spname<- trimx(x)
      sattr <- ""
    }
    
    fig_main <- trimx(x)
    xsp2 <- sp2namex(spname)
    x_dtk<- which(dtk$taxon==xsp2)
    
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
        tt <- which(is.na(x) | x=="")
        if (any(tt)) {
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
          xt <- trimx(gsub("\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i])))))
          if (length(subfig)==0 & fig_title=="" & xt != spname) { #(any(subfig=="")) {
            subfig <- trimx(unlist(tstrsplit(x, '\\s{2,}|\\t'), use.names = F)) #note that sometimes pattern has: "a1   b2 & c3", split to "a1" "b2 & c3" 
            i <- i + 1L
            next
          } else if (fig_title=="") {
            x <- trimx(gsub("\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i])))))
            if (x!=spname) {
              print(paste0("Warning: Not equal fig title with spname, check it fig_titile: ", x, "  at i:",  i))
              tt <- sp2namex(x)
              if (tt!=xsp2) {
                print(paste0("Error: Not equal short fig title with taxon, check it fig_titile: ", x, "  at i:",  i))
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
            if (wa>0 | (xsp1==gen_name & trimx(sp2namex(x)) != xsp2)) {
              if (wa<0) {
                spt <- trimx(x)
              } else {
                spt<- trimx(substr(x, 1, wa-1))
              }
              if (spt != spname) {
                print(paste0("Start next sp: ", spt, "  at i:",  i)) #cannot add i, repeated this step though..
                within_xsp_flag <- FALSE #A species is completed its record, and go into next sp! 
                
                blk_cnt <- blk_cnt + 1
                #flink <- sapply(fig_num, function(x) {
                #  paste0("fig_", gsub("\\s", "_", xsp2), "_", padzerox(x))
                #}, simplify = T)
                fkey <- substring(gsub("www_sp\\/img\\/|\\.jpg", "", imgf), 6)
                fnum <- gsub("_", "", gsub(gsub("\\s", "_", xsp2), "", fkey))
                if (length(fig_citation)==0) {
                  fig_citation <- rep(NA_character_, length(fig_num))
                } else if (length(fig_citation) < length(fig_num)) {
                  fig_citation <- c(fig_citation, rep(NA_character_, length(fig_num)-length(fig_citation)))
                }
                
                dfk <- rbindlist(list(dfk, 
                         data.table(fidx=fig_num, fkey=fkey,
                                  ckeyx=rep(paste(x_dtk, collapse = ","), length(fig_num)),
                                  imgf=imgf, sex=fsex, #rep(NA_character_, length(fig_num)),
                                  main=rep(fig_main, length(fig_num)),
                                  title= rep(fig_title, length(fig_num)),
                                  subfig= subfig, caption= fig_caption, 
                                  citation= fig_citation, #may be null, so use fill=NA
                                  flushed=rep(paste(fig_num, collapse = ","), length(fig_num)), ## flushed means flush figs in a row
                                  blkx=blk_cnt, docn=cntg) ### blkx: counter of block of fig, docn: nth document
                ), fill = TRUE) 
                
                fdlink <- paste0("fig_", gsub("\\s", "_", xsp2)) #, "_", paste(fnum, collapse="-"))
                
                if (length(fig_num)>=3) {
                  spanx <- 'ntrd' ### narrow span
                } else if (length(fig_num) == 2) {
                  spanx <- 'ntwo'
                } else { 
                  spanx <- 'nfig'
                }
                #break #only for test
                if (any(is.na(fig_caption))) {
                  fig_caption <- fig_caption[!is.na(fig_caption)]
                }
                
                dtk <- rbindlist(list(dtk,data.table(rid=i, unikey=fdlink,
                                      ckey= NA_character_, subkey= NA_character_, pkey= NA_character_,
                                      figs=paste(fig_num, collapse = ","), type=NA_integer_, nkey=NA_integer_, 
                                      taxon=xsp2, abbrev_taxon=dtk[x_dtk[1],]$abbrev_taxon, 
                                      subgen=dtk[x_dtk[1],]$subgen, genus=gen_name,
                                      epithets=NA_character_, keystr=keystr, 
                                      ctxt=paste(paste0('\n\n<div id=', dQuote(fdlink),'><span class=', dQuote('blkfigure'),'>'), 
                                                 paste0('<div class=', dQuote("fig_title"),'><span class=', dQuote('spmain'), '>', italics_spname(fig_main, spname),'</span></div>'),
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
                                                     flink=fkey, cfigx=subfig, #fgcnt=fig_num,
                                                   MoreArgs = list(spanx=spanx), SIMPLIFY = TRUE, USE.NAMES = FALSE) %>% 
                                                 paste(collapse=" "),'</span></div>', 
                                                 paste0('<div class=', dQuote("fig_title"),'><span class=', dQuote('spnote'), '>', italics_spname(fig_title, spname),'</span></div>'),
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
                                                  sep="<br>"),
                                      fkey=paste(fkey, collapse=","), 
                                      sex=NA_character_, body=NA_character_, keyword="figs")))
                next
              } else {
                print(paste0("Warning: Format not consistent to get the same sp: ", spt, "  Check it at i:",  i))
                break 
              }
            } else {
              #if (length(fig_caption)==0) {
                flag_getcap <- FALSE
                xc <- -1
                if (length(subfig)>0 & imgj < length(subfig)) {
                  xc <- find_subfigx(x, subfig[imgj+1])
                }
                if (length(subfig)==0) {
                  flag_getcap <- TRUE
                } else if (imgj >= length(subfig)) { #End of fetch subfig
                  flag_getcap <- FALSE
                } else if ((xc>0) | #(subfig[imgj+1] == substr(x, 1, nchar(subfig[imgj+1]))) | 
                           (imgj==0 & (("Female" %chin% subfig & grepl("Female", x)) |
                                       ("Male" %chin% subfig & grepl("Male", x))))) {
                  flag_getcap <- TRUE
                }
                if (flag_getcap) {    
                  k <- 1
                  if (length(subfig)>0) {
                    if (xc<0) { #subfig[imgj+1] != substr(x, 1, nchar(subfig[imgj+1]))) {
                      if (imgj==0 & ("Female" %chin% subfig & grepl("Female", x)) &
                          ("Male" %chin% subfig & grepl("Male", x))) {
                        k <- 2 # one description (x) contains two subfigs
                      }
                    } else if (imgj==1 & xc>0) { #subfig[imgj+1] == substr(x, 1, nchar(subfig[imgj+1]))) {
                      k <- 2 # 2nd run for subfig[2]
                    }
                  }
                  while (imgj<k) {
                  #if (subfig[imgj+1] != "Original") {
                    cntg_fig <- cntg_fig + 1L
                    doc_fign <- doc_fign + 1L
                    fig_num[imgj+1] <- cntg_fig
                    docfn <- unlist(tstrsplit(docfile, "\\/"), use.names = F) %>% .[length(.)]
                    imgsrc <- paste0(doc_imgdir, 
                                     gsub("\\s", "_", gsub("Key to the species of\\s|\\s\\(China seas 2\\)\\.docx", "", docfn)),
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
                    if (k==2 & imgj==1 & xc<0) { #subfig[imgj+1] != substr(x, 1, nchar(subfig[imgj+1]))) {
                      fig_caption[imgj+1L] <- NA_character_ #only one description but contains two subfigs
                    } else {
                      fig_caption[imgj+1L] <- x
                    }
                    
                    #xt <- tolower(x)
                    if (subfig[imgj+1L]=="Female" | subfig[imgj+1L]=="Male") {
                      fsex[imgj+1L] <- tolower(subfig[imgj+1L])
                    } else {
                      if (grepl("(\\s|\\.)Male", x)) {
                        if (grepl("(\\s|\\.)Female", x)) {
                          fsex[imgj+1L] <- "female/male"
                        } else {
                          fsex[imgj+1L] <- "male"
                        }
                      } else if (grepl("(\\s|\\.)Female", x)) {
                        fsex[imgj+1L] <- "female"
                      } else {
                        fsex[imgj+1L] <- NA_character_
                      }
                    }
                    imgj <- imgj + 1L
                  }  
                  i <- i + 1L
                  next
                  
                } else { #Not another subfig, can be citation of subfig
                  if (subfig[imgj] == "Original" | substr(x,1,7) != "Adapted") {
                    print(paste0("Warning: Get a not-citation remark: ", x, "  Check it at i:",  i))
                  }
                  if (length(subfig)>0 & imgj >= length(subfig)) {
                    fig_citation[length(na.omit(fig_caption))] <- x
                  } else {
                    fig_citation[imgj] <- x
                  }
                  i <- i+1
                  next
                }
              #}
            } # end of fig_caption
          }
        }    
      } #within_xsp_flag
    } 
  }
}  


cat(na.omit(dtk$ctxt), file=paste0(web_dir, "web_tmp.txt"))

## output source fig file
fwrite(dfk[!is.na(imgf), ] %>% .[,srcf:=imglst[imgf]] %>% .[,.(fidx, srcf)], file="www/bak/src_figfile_list.csv")

length(unique(na.omit(dtk$ckey))) #187
which(!1:187 %in% unique(na.omit(dtk$ckey)))

nrow(unique(dtk[!is.na(ckey)|!is.na(subkey),])) #391
