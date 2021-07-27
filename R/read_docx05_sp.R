## Version 5: Specific version for species key for Shih new work 202107
library(officer)
library(odbapi)
library(data.table)
library(magrittr)
#library(stringr)

key_src_dir <- "D:/ODB/Data/shih/shih_5_202107/Key"
web_dir <- "www_sp/"
web_img <- paste0(web_dir, "img/")
web_imgsrc <- paste0(web_dir, "img_src/")

skipLine <- 4L
#webCite <- "from the website <a href='https://copepodes.obs-banyuls.fr/en/' target='_blank'>https://copepodes.obs-banyuls.fr/en/</a> managed by Razouls, C., F. de Bovée, J. Kouwenberg, & N. Desreumaux (2015-2017)"
#options(useFancyQuotes = FALSE)

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

###############################################################################################
doclst <- list.files(key_src_dir, pattern="^Key?(.*).docx$",full.names = T)
cntg <- 0L
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
#dfk <- data.table(fidx=integer(), imgf=integer(), sex=character(), 
#                  body=character(), remark=character(), fdup=character(), # the imgf had been used (diff figx, use the same imgf)
#                  flushed=integer(), ckeyx=integer(), ## flushed means if flushed to ctxt already (1, otherwise 0)
#                  case=integer(), blkx=integer()) ### case: blkfigure or not; blkx: counter of block of fig flushed into block


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
                       paste0('<mark id=',  dQuote(paste0('taxon_', gsub("\\s","_",xsp))), '>*', xsp, '*</mark></span></p>'))
          
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

  cnt_fig <- 0L 
  while (fig_mode & nrow(dtk)>0 & i<=tstL) {
    x <- gsub("\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i]))))
    wa <- regexpr("\\(Size",x)
    if (wa>0) {
      spname<- substr(x, 1, wa-1)
      sattr <- substr(x, wa, nchar(x))
    } else {
      spname<- x
      sattr <- ""
    }
    
    if (as.numeric(as.character(packageVersion("odbapi"))) < 0.73) {
      xsp2 <- odbapi::sciname_simplify(spname, simplify_two = T)
    } else {
      xsp2 <- odbapi::sciname_simplify(spname, simplify_two = T, trim.subgen = T) #note that odbapi_v073 has trim.subgen
    }
    x_dtk<- which(dtk$taxon==xsp2)
    
    if (!any(x_dtk)) {
      print(paste0("Error: Check fig_mode got ?? sp: ", xsp2, " at i: ", i))
      break
    } else {
      cnt_fig <- cnt_fig + 1L
      within_xsp_flag <- TRUE
      i <- i + 1L
      ncflag <- 0L
      fig_info <- c("subfig", "title", "caption")
      subfig <- ""
      fig_title <- ""
      fig_caption <- c()
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
          if (any(subfig=="")) {
            subfig <- trimx(unlist(tstrsplit(x, '\\s{2,}|\\t'), use.names = F)) #note that sometimes pattern has: "a1   b2 & c3", split to "a1" "b2 & c3" 
            i <- i + 1L
            next
          } else if (fig_title=="") {
            x <- gsub("\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i]))))
            if (x!=spname) {
              print(paste0("Warning: Not equal fig title with spname, check it fig_titile: ", x, "  at i:",  i))
              tt <- odbapi::sciname_simplify(x, simplify_two = T, trim.subgen = T)
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
            x <- gsub("\\\t", "", gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i]))))
            wa <- regexpr("\\(Size",x)
            if (wa>0) {
              spt<- substr(x, 1, wa-1)
              if (spt != spname) {
                print(paste0("Start next sp: ", spt, "  at i:",  i)) #cannot add i, repeated this step though..
                next
              } else {
                print(paste0("Warning: Format not consistent to get the same sp: ", spt, "  Check it at i:",  i))
                break 
              }
            } else {
              if (length(fig_caption)==0) {
                if (subfig[1] == substr(x, 1, nchar(subfig))) {
                  if (subfig[1] != "Original") {
                    cnt_fig <- cnt_fig + 1
                    docfn <- unlist(tstrsplit(docfile, "\\/"), use.names = F) %>% .[length(.)]
                    imgzip = paste0(web_imgsrc, 
                             paste(padzerox(cntg,2), padzerox(cnt_fig,2), 
                                   paste0(unlist(tstrsplit(xsp2, "\\s"), use.names = F), collapse = "_"),
                                   subfig[1], sep="_"),".zip")
                    #if (!file.exists(imgzip)) {
                    #  cat("copy file to img zip: ", imgzip)
                    #  system(enc2utf8(#gsub('\\“|\\”', '"', 
                    #             paste0( #cmd.exe /c copy
                    #                         "powershell -Command 'Copy-Item", 
                    #                         #dQuote(paste0("Copy-Item  ", #gsub("/","\\\\", paste0(key_src_dir, "/")),
                    #                         #"'", docfn, "'",
                    #                         '"', docfile, '"',
                    #                         '"', paste0("D:/proj/copkey/", imgzip), '"', "'" #)
                    #             )
                    #  ))
                    #                         #gsub("/","\\\\", " D:/proj/copkey/"),
                    #                         #gsub("/","\\\\", imgzip))))
                    #}
                    imgf = "D:/proj/copkey/www_sp/img_src/01_02_Acartia_bifilosa_Mazzocchi.zip/word/media/image1.jpeg"
                    
                  }
                  #dfk <- data.table(fidx=integer(), imgf=integer(), sex=character(), 
                  #                  body=character(), remark=character(), fdup=character(), # the imgf had been used (diff figx, use the same imgf)
                  #                  flushed=integer(), ckeyx=integer(), ## flushed means if flushed to ctxt already (1, otherwise 0)
                  #                  case=integer(), blkx=integer()) ### case: blkfigure or not; blkx: counter of block of fig flushed into block
                  
                  dfk <- rbidnlist(list(dfk, data.table(fidx=)))
                }
              }
            }
          }
        }    
      }
      
    }
    

    
  }
  if ((i==tstL & !inTesting) | (kflag & !st_conti_flag & WaitFlush[1])) {
    if (is.na(x) | x=="") {
      xc <- ""
      figx <- NA_character_
    }
    if (i==tstL & !inTesting) {
      xc <- paste0(xc,"</div>")
    }
    
    if (WaitFlush[1] | (nrow(dfk)>0 & any(dfk[!is.na(imgf),]$flushed==0L))) {
      if (nrow(dfk[!is.na(imgf) & flushed==0L,])==1 & nrow(st_keep)==1 & any(is.na(figx))) {
        rgtflush_flag <- TRUE  ###
        blkflush_flag <- FALSE ### 20191015 modified, so that we can pipe fig more earlier
      } else {
        blkflush_flag <- TRUE
      }
      #if (IndexVers<=2) 
      print(paste0("Check insRow correct: ", paste(insRow,collapse=","), " with i: ", i, " with key: ", keyx))
      insRow[1] <- nrow(dtk) ## update insert Row number just before current key (still not in dtk)
    ########################################### Ver3: all figs in sidebar, so insRow will be earlier when figx found
    }
  }  


#  if (nxttype==0L & any(is.na(xsp)) & any(!is.na(figx)) & length(figx)>=1) { # Have figs link but no taxa info
#  20180126 : st_keep change to keep figs in order to keep figs in block with 2-columns
############################################################################################
## Case 1: if pret_case==1L: Find blk-fig by author (figs. xx-yy), piped them and flush before next primary key
## Case 2: if pret_cast==1L and WaitFlush==TRUE, means next blk comes, and previous one still not flushed-out yet
##         We still need to piped them in next blkcnt ID
## Case 2a:if too much figs already in right-side, and pret_case==0L, we can wait until previous blk is going to
##         be flushed (blkflush_flag set) and pipe these new figs in new block
## Case 3: if pret_case==0L but too-much right-side figs, we stacked 2 or 3 figs and flushed in main-column
## Case 4: if previous case is pret_case==0L and still WaitFlush or fig_conti_flag, but now pret_case==1L comes,
##         Just flushed the stacked fig in right-side and pieped the block of current case (pret_case==1L)      
  if (!any(is.na(figx)) & nrow(dfk)>0) {
    chkfx <- sapply(figx, function(x) match(x, dfk[!is.na(imgf),]$fidx))
    if (any(!is.na(chkfx))) { ## already mapping dfk, no need to query again
      figx <- figx[-which(!is.na(chkfx))]
    } 
    if (length(figx)==0) figx <- NA_integer_
  }
  
#  if (WaitFlush[1] & blkflush_flag) { ## st_keep soon be flushed, so pre_update line_count to prevent next figs easily piped
#    lcnt_pre <- (figperLine-1)*(2+(as.integer((nrow(st_keep)-1)/3)+1)) + lcnt
#  } else {
    lcnt_pre <- (figperLine-1)*2 + lcnt 
#  }
  
   if (EnableBlkFig & !any(is.na(figx)) & (IndexVers>2L | pret_case!=0L | fig_conti_flag |## WaitFlush will hold-on fig-flush
        (EnableLongToBlk &  ## Version 3 disable ############################
            (all(!WaitFlush) | (length(WaitFlush)==1 & WaitFlush[1] & blkflush_flag)) & ## Case 2a
            ((fcnt*figperLine+2L) >= lcnt_pre)))) {
     if ((pret_case!=0L & (WaitFlush[1] | fig_conti_flag) & any(st_keep$case==0L))|
         (!any(is.na(figx)) & (nrow(st_keep)>0 | length(figx)>1) & kflag) ### that will cause primary key and 2nd key broken by img (marginfigure)
         ){ ### I'll only know 2nd key is over until next primary key (kflag), but can insert it before primary key
            ### BUT, we still need consider if insert before next kflag, will interupt </div> (before the next primary key)
       print(paste0("Warning: Flush piped fig in right-column, check them in i: ",i, " with figs: ",
             paste(st_keep[case==0L,]$xfig, collapse=",")))
       fig_conti_flag <- FALSE
       WaitFlush[1] <- FALSE
       if (blkflush_flag | nrow(st_keep)>1 | length(figx)>1) {
         blkflush_flag <- TRUE
         #dfk[fidx %in% st_keep[case==0L,]$xfig, blkx:=max(blkx)+1]
       } else {
         rgtflush_flag <- TRUE ### Case 4: flush figs in right-side column!
         dfk[fidx %in% st_keep[case==0L,]$xfig, blkx:=0L]
       }
     }
     if (!WaitFlush[1]) {
       tt <- nrow(st_keep) + length(figx)
       st_keep <- rbindlist(list(st_keep, 
                                 data.table(xfig=figx, xkey=nxtk, blkx=blkcnt+1L, case=pret_case)))
       if (IndexVers<=2 & (tt %% 2 == 0L | tt %% 3 == 0L | pret_case!=0L)) {
         figx <- sort(unique(na.omit(c(st_keep$xfig,figx))))  ## flush out figs link that kept in st_keep 
         fig_conti_flag <- FALSE
         WaitFlush[1] <- TRUE
         insRow <- c(insRow, nrow(dtk)+1L)
       } else { ############################## Case 3 pipe
         print(paste0("... Piping figs in st_keep in i: ",i, " with figs: ", paste(figx, collapse=",")))
         if (!rgtflush_flag & !blkflush_flag) {
           fig_conti_flag <- TRUE
         }
         #if (nrow(dtk)==0) {
         # insRow[1] <- 1
         if (kflag) {
          insRow[1] <- nrow(dtk)+1L #Ver3: insRow will be earlier ## Note <p>marginnote</p> must inside <div kblk></div>
         }
       }
     } else if (WaitFlush[1] & (IndexVers<=2 | kflag)) { #if (WaitFlush[1] & pret_case!=0L & !rgtflush_flag) { #### Case 2, 2a pipe
       print(paste0("Warning: 2-nd block comes and pipe fig in st_keep in i: ",i, " with figs: ",
                    paste(figx, collapse=",")))
       st_keep <- rbindlist(list(st_keep, 
                                 data.table(xfig=figx, xkey=nxtk, blkx=max(st_keep$blkx)+1L, case=pret_case)))
       if (IndexVers<=2 & (pret_case!=0L | length(figx) %% 2 == 0L | length(figx) %% 3 == 0L)) {
         fig_conti_flag <- FALSE
         WaitFlush <- c(WaitFlush, TRUE)
       } else {
         fig_conti_flag <- TRUE
         WaitFlush <- c(WaitFlush, FALSE)
       }
       insRow <- c(insRow, nrow(dtk)+1L)
     }
   } else {
     #if (!blkflush_flag) {
       #fblk_flag <- FALSE
     if (!any(is.na(figx))) {rgtflush_flag <- TRUE}
     #}
   } 

    
  if (any(!is.na(figx)) & length(figx)>=1) { ## Normal cases
    chkfx <- sapply(figx, function(x) match(x, dfk$fidx))
    if (any(!is.na(chkfx))) { ## already mapping dfk, no need to query again
      figxt <- figx[-which(!is.na(chkfx))]
      
      dfk[fidx %in% figx[which(!is.na(chkfx))] & flushed==0, ckeyx:=keyx] ##update fig/cur_key mapping
    } else {
      figxt <- figx
    }
    
    if (length(figxt)>=1) {
      fdt <- find_Figfilex(figxt, ftent, imglst) ##### Find fig file in imglst
      
      if (any(is.na(fdt$sex)) & !all(is.na(xsex))) {
        print(paste0("Warning: Not found sex info in Table, but actually in Key doc, sp: ", 
                     paste(na.omit(c(nsp,xsp)),collapse=","), " in i: ", i))
        if (nrow(fdt[is.na(sex),])!= length(xsex)) {
          print(paste0("Warning: Cannot determine sex in fdt, i: ", i,
                       " for xsex: ", paste(xsex, collapse = ",")))
        } else {
          fdt[is.na(sex), sex:=xsex]
        }
      }
##### fdt' imgf may appear in previous dfk and had been flushed #############################################      
      fdt[,fdup:=""] 
      if (nrow(dfk)>0) {
        fdt %<>% .[imgf %in% dfk[!is.na(imgf),]$imgf, fdup:="DUP"] ## still plot, but mark it in this version
      }
      
      dfk <- rbindlist(list(dfk, fdt[,`:=`(flushed=0L, ckeyx=keyx, case=pret_case,
                                           blkx=ifelse(rgtflush_flag, 0L, max(st_keep$blkx)))]))
      if (any(is.na(fdt$imgf))) {
        print(paste0("Check img file corresponding is NA in i: ", i))
        print(paste(fdt[is.na(imgf),]$fidx, collapse=","))
      }
      ####### 
      ####### Re-determine plot status, since fig numbuer may NA and changed, cannot fit into 2-column block        
      if (any(is.na(fdt$imgf)) | length(figxt)!=length(figx) | ## fig number changed
          !any(dfk[!is.na(imgf),]$flushed==0L)) { ## No figs available, so that delete in st_keep
        if (any(is.na(fdt$imgf)) & fig_conti_flag) {
          st_keep %<>% .[!xfig %in% fdt[is.na(imgf),]$fidx,]
          tt <- sort(unique(na.omit(c(st_keep$xfig,figx[!figx %in% fdt[is.na(imgf),]$fidx]))))
          if (length(tt)>=2 & (length(tt) %% 2 == 0L | length(tt) %% 3 == 0L)) {
            fig_conti_flag <-FALSE
            if (nrow(st_keep)>0) {
              st_keep %<>% .[blkx>(blkcnt+1L),] ## flush it!
            }
            WaitFlush[1] <- TRUE
          }
        } else if (!any(dfk[!is.na(imgf),]$flushed==0L)) {
          st_keep <- data.table(xfig=integer(), xkey=integer(), blkx=integer(), case=integer())  ### clear NA data
          #fblk_flag <- FALSE; 
          fig_conti_flag <- FALSE; rgtflush_flag <- FALSE; blkflush_flag <- FALSE
          WaitFlush <- c(FALSE); insBlkId <- c(); insRow <- c();
          
        } #else if (pret_case==0L & length(figxt)!=length(figx) & !rgtflush_flag &
          #         nrow(dfk[!is.na(imgf) & flushed==0L,])==1L) {
          #st_keep <- rbindlist(list(st_keep, 
          #                          data.table(xfig=figxt, 
          #                                     xkey=dfk[match(figxt,fidx),]$ckeyx)))
          #fig_conti_flag <- TRUE; WaitFlush[1] <- FALSE
          ##fblk_flag <- TRUE ############### Wait next chance to flush, keep in st_keep
        #}
      }
    }
  }
  xf <- data.table(rid=integer(), ckey=integer(), 
                   subkey=character(), pkey=integer(),
                   figs=character(), type=integer(), nkey=integer(), 
                   taxon=character(), ctxt=character(), fkey=character(),
                   sex=character(), body=character(), keyword=character(), fidx=integer()) #20191014 modified to re-order xf 
  
#### plot immediately, Output Fig HTML code  
  fig_dt <- dfk[FALSE,]
  if ((rgtflush_flag | blkflush_flag) & any(dfk[!is.na(imgf),]$flushed==0L)) { 

    if (rgtflush_flag) {
      if (!blkflush_flag) {
        fig_dt <- dfk[!is.na(imgf) & flushed==0L & case==0L,]
        fig_dt[,flushed:=1L]
      } else {
        if (nrow(dfk[!is.na(imgf) & flushed==0L & case==0L & blkx==0L,])>0) {
          fig_dt <- dfk[!is.na(imgf) & flushed==0L & case==0L & blkx==0L,]
          fig_dt[,flushed:=1L]
        } else {
          rgtflush_flag <- FALSE ##it means figxt!=figx, duplicated figx (had been outputted) is used in previous statement
        }
      }
    } 
    if (blkflush_flag) {
      fig_dt <- rbindlist(list(fig_dt, 
                               dfk[!is.na(imgf) & flushed==0L & blkx==(blkcnt+1L),] %>% .[,flushed:=2L]))  
      
    }
    if (nrow(fig_dt)>0) {
      #################### Ouput Figure HTML Function ##############################
      ####### Both not in dfk, but they are using the same imgf, not detected in previous code
      tdup <- which(duplicated(fig_dt$imgf))
      if (any(tdup)) {
        fidx_dup <- fig_dt$fidx[tdup]
        link_dup <- sapply(fig_dt$imgf[tdup], function(x, ftx) {ftx[match(x, imgf),]$fidx[1]},
                           ftx=fig_dt[-tdup,])
        print(paste0("Duplicate link to fig: ", paste(link_dup, collapse=",")))
        stopifnot(all(!is.na(link_dup)))
        ################################# ## still plot, but mark it in this version ##################
        #dfk[fidx %in% fig_dt[tdup,]$fidx, flushed:=99L] #fig_dt[tdup,]$flushed] ## the duplicated plot actually not plotted 
        #fig_dt %<>% .[-tdup,] 
        ################################# ## temporarily only mark it 
        dfk[fidx %in% fig_dt[tdup,]$fidx, fdup:="DUP"]
        fig_dt[tdup, fdup:="DUP"]
      }
      
      fn <- imglst[fig_dt$imgf]
      if (IndexVers==1L) {
        outf<-gsub("(P[0-9]+)_([0-9])","\\1-\\2",
              gsub("-f","_f", gsub("-m","_m",   ## -female, -male to _female _male in file names
              gsub("_\\.","\\.",gsub("^\\s{1,}|^_{1,}|\\s+$|_+$","",
              gsub("_{1,}|[^P0-9a-zA-Z]-{1,}","_",gsub("\\s{1,}|&","_",
              gsub("\\(|\\)|\\;|[^PAMx_\\-][0-9]{1,}|[0-9]{0,}\\.[0-9]{1,}mm|doc/img/","",
              gsub("♀|Female","female",gsub("♂|Male","male",fn))))))))), perl=TRUE)  
      } else {
        outf<-gsub("\\s{1,}","_",substr(fn,22,nchar(fn)))
      }
      flink <- paste0("fig_", fig_dt$fidx) #figx) 
      
      for (j in seq_along(outf)) {
        if (!file.exists(paste0("www/img/",outf[j]))) {
          cat("copy file from img: ", outf[j])
          system(enc2utf8(paste0("cmd.exe /c copy ", gsub("/","\\\\",paste0("D:/R/copkey/",fn[j])), 
                                 " ",gsub("/","\\\\",paste0("D:/R/copkey/www/img/",outf[j])))))
        }
      }
      if (IndexVers==1L) {
        ft <- sapply(outf, function(outf) {paste(unlist(tstrsplit(gsub("\\.jpg|\\(|\\)","",outf),"_|-")), collapse=" ")},
                   simplify = T, USE.NAMES = F)
      } else {
        ft <- sapply(outf, function(outf) {paste(unlist(tstrsplit(gsub("Fig[0-9]{1,}_|\\.jpg|\\(|\\)","",outf),"_|-")), collapse=" ")},
                     simplify = T, USE.NAMES = F)
      }
#### Extract SPname ans SEXinfo ########################            
      if (any(grepl("female|male", ft))) {
        spt<- sciname_simplify(gsub(paste(c("female|male|(P|Mx)?[0-9]+", termList$name), collapse="(\\s|$)|\\b"),"",ft),
                               simplify_two = TRUE)
        sxt<-rep(NA_character_,length(spt))
        wsxt <- regexpr("(\\s|\\b)female",tolower(substr(ft,nchar(spt)+1,nchar(ft)))) 
        sxt[wsxt>0] <- "female"

        wsxt <- regexpr("(\\s|\\b)male",tolower(substr(ft,nchar(spt)+1,nchar(ft)))) 
        sxt[wsxt>0] <- sapply(sxt[wsxt>0], function(x) {paste(na.omit(c(x,"male")),collapse=",")}, simplify = TRUE, USE.NAMES = FALSE) 
        sxt[is.na(sxt)] <- ""  
        #sxt<- gsub("\\s",", ",trimx(gsub("((\\s|\\b)(female|male))","\\1",
        #      #gsub(paste(c("(P|Mx)?[0-9]+", termList$name), collapse="(\\s|$)|\\b"),"",
        #           substr(ft,nchar(spt)+1,nchar(ft)))))
      } else {
        spt<- sciname_simplify(ft, simplify_two = TRUE)
        sxt<-rep("",length(spt))
      }
      #################### Output Fig HTML code ####################################################
      if (blkflush_flag & rgtflush_flag & any(0L %in% fig_dt[flushed==2L,]$case)) { 
        if (nrow(fig_dt) %% 2 == 0 | nrow(fig_dt) %% 3 == 0) {
          print(paste0("FLush Change: right-side fig into main-column in i: ",i, "with figs: ", 
                       paste(fig_dt[flushed==1L,]$fidx, collapse=",")))
          fig_dt[flushed==1L, blkx:=fig_dt[flushed==2L,]$blkx[1]]
          fig_dt[flushed==1L, flushed:=2L]
          rgtflush_flag <- FALSE
        }
      }
      setorder(fig_dt, fidx)
      
      
      if (blkflush_flag & nrow(fig_dt[flushed==2L,])>0) {
        idx2 <- which(fig_dt$flushed==2L)
        if (length(insBlkId)==0) {
          insBlkId <- c(paste0("fig_",paste(c(fig_dt[idx2,]$fidx[1],fig_dt[idx2,]$fidx[length(idx2)]), collapse="-")))
        }
        if (IndexVers<=2L & length(idx2) %% 3 == 0) {
          spanx <- 'ntrd' ### narrow span
        } else if (IndexVers>2L & length(idx2) == 1) {
          spanx <- 'thumbnail'
        } else { ############ otherwise, 2 figs in a line, use wider span
          spanx <- 'ntwo'
        }
        if (IndexVers<=2L) {
          xf <- data.table(rid=i, ckey=NA_integer_, subkey=NA_character_, pkey=NA_integer_,
                           figs=paste(fig_dt[idx2,]$fidx,collapse=","),  type=NA_integer_, nkey=NA_integer_, 
                           taxon=paste(spt[idx2],collapse=","),
                           ctxt=paste(paste0('\n<br><p class=', dQuote('blkfigure'),'>'), 
                                      mapply(function(outf,flink,cfigx,sp,sex,ckeyx,spanx,fdupx) {
                                        paste0('<span id=', dQuote(insBlkId[1]),' class=', dQuote(spanx), '><a class=', dQuote("fbox"), 
                                               ' href=', dQuote(paste0('img/',outf)),'><img src=',
                                               dQuote(paste0('img/',outf)), ' border=', dQuote('0'),
                                               ' /></a><span id=', dQuote(flink), ' class=', dQuote('spnote'),
                                               '>Fig.',cfigx,' *',sp,'* ',sex,' [&#9754;](#key_',ckeyx,') &nbsp;',
                                               fdupx,'</span></span>') ############ Only MARK duplicated imgf
                                      },outf=outf[idx2], flink=flink[idx2], cfigx=fig_dt[idx2,]$fidx, 
                                      sp=spt[idx2], sex=sxt[idx2], ckeyx=fig_dt[idx2,]$ckeyx, fdupx=fig_dt[idx2,]$fdup,
                                      MoreArgs = list(spanx=spanx), SIMPLIFY = TRUE, USE.NAMES = FALSE) %>% 
                                        paste(collapse="\n"),'</p><br>', sep="\n"),
                           fkey=paste(flink[idx2], collapse=","),
                           sex=paste(sxt[idx2], collapse=","), 
                           body=paste(fig_dt[idx2,]$body, collapse=","), 
                           keyword=NA_character_, fidx=min(idx2))
          insBlkId <- insBlkId[-1]
        } else {
          ############################# Ver3: add fig captions from file (fcap)
          caps <- mapply(function(x, sp, fcap, webCite) {
            paste0("<em>",sp,"</em>, ",
                    ifelse(is.na(fcap[Fig==x,]$characters),"",fcap[Fig==x,]$characters),
                    ifelse(is.na(fcap[Fig==x,]$ext),"", paste0("<br>",fcap[Fig==x,]$citation, ", ", webCite)))
          }, x=fig_dt[idx2, ]$imgf, sp=spt[idx2], 
             MoreArgs = list(fcap=fcap, webCite=webCite), SIMPLIFY = TRUE, USE.NAMES = FALSE)
          
          xf <- data.table(rid=i, ckey=NA_integer_, subkey=NA_character_, pkey=NA_integer_,
                           figs=paste(fig_dt[idx2,]$fidx,collapse=","),  type=NA_integer_, nkey=NA_integer_, 
                           taxon=paste(spt[idx2],collapse=","),
                           ctxt=paste(paste0('\n\n```{marginfigure}\n','<span class=', dQuote('blkfigure'),'>'), 
                                      mapply(function(outf,flink,cfigx,sp,sex,ckeyx,spanx,fdupx,capx) {
                                        paste0('<span id=', dQuote(insBlkId[1]),' class=', dQuote(spanx), '><a class=', dQuote("fbox"), 
                                               ' href=', dQuote(paste0('img/',outf)),
                                               ' data-alt=', dQuote(paste0(capx)),' /><img src=',
                                               dQuote(paste0('img/',outf)), ' border=', dQuote('0'),
                                               ' /></a><span id=', dQuote(flink), ' class=', dQuote('spnote'),
                                               '>Fig.',cfigx,' *',sp,'* ',sex,' [&#9754;](#key_',ckeyx,') &nbsp;',
                                               fdupx,'</span></span>') ############ Only MARK duplicated imgf
                                      },outf=outf[idx2], flink=flink[idx2], cfigx=fig_dt[idx2,]$fidx, 
                                      sp=spt[idx2], sex=sxt[idx2], ckeyx=fig_dt[idx2,]$ckeyx, fdupx=fig_dt[idx2,]$fdup,
                                      capx=caps, MoreArgs = list(spanx=spanx), SIMPLIFY = TRUE, USE.NAMES = FALSE) %>% 
                                        paste(collapse="\n"),'</span>','```\n\n', sep="\n"),
                           fkey=paste(flink[idx2], collapse=","),
                           sex=paste(sxt[idx2], collapse=","), 
                           body=paste(fig_dt[idx2,]$body, collapse=","), 
                           keyword=NA_character_, fidx=min(idx2))
          insBlkId <- insBlkId[-1]
        }
      } else {
        idx2 <- c()
      }
      if (rgtflush_flag & nrow(fig_dt[flushed==1L,])>0) { ## if not put fig in block, but in right side, each fig is a unique HTML quote by marginfigure
        idx1 <- which(fig_dt$flushed==1L)
        
        xf <- rbindlist(list(xf,rbindlist(mapply(function(x, sp, sex, body, flink, outf, ckeyx, cfigx, fdupx, itx) {
          list(rid=itx, ckey=NA_integer_, subkey=NA_character_, pkey=NA_integer_,
               figs=cfigx,  type=NA_integer_, nkey=NA_integer_, taxon=sp,
               ctxt=paste('\n\n```{marginfigure}', 
                          paste0(preimgt, dQuote("fbox"), ' href=', dQuote(paste0('img/',outf)),'><img src=',
                                 dQuote(paste0('img/',outf)), ' border=', dQuote('0'),
                                 ' /></a><span id=', dQuote(flink), ' class=', dQuote('spnote'),
                                 '>Fig.',cfigx,' *',sp,'* ',sex,' [&#9754;](#key_',ckeyx,') &nbsp;',
                                 fdupx, endimgt),'```\n\n', sep="\n"), ############ Only MARK duplicated imgf
               fkey=flink, sex=sex, body=body, keyword=NA_character_, fidx=min(idx1))
        }, x=ft[idx1], sp=spt[idx1], sex=sxt[idx1], 
           body=fig_dt[idx1,]$body, flink=flink[idx1], outf=outf[idx1], 
           ckeyx=fig_dt[idx1,]$ckeyx, cfigx=fig_dt[idx1,]$fidx,  fdupx=fig_dt[idx1,]$fdup,
        MoreArgs = list(itx=i), SIMPLIFY = FALSE))))
      } else {
        idx1 <- c()
      }
      ##############################################################################
      dfk[fidx %in% fig_dt[idx1,]$fidx, flushed:=1L]  
      dfk[fidx %in% fig_dt[idx2,]$fidx, flushed:=2L]  
      setorder(xf, fidx)
     
      pgRemain = pageLine-(nrow(dtk)-(page-1L)*pageLine) ## How many rows remain for this page
      if (length(idx2)>0) { 
        if (spanx=="ntrd") {
          addft <- as.integer((length(idx2)-1)/3.0)+1L
          addlt <- (figperLine-2)* addft + 1L #in main-column, fig smaller than right-side
        } else {
          addft <- as.integer((length(idx2)-1)/2.0)+1L
          addlt <- (figperLine-1)* addft + 1L #in main-column, fig smaller than right-side
          #- fcnt*figperLine ## may Negative
        }
        #if (addft <= pgRemain) { ## blkfigure always count 1 by using only one <p></p>
        if (pgRemain>0) {
          lcnt <- lcnt + addlt
          pgRemain <- pgRemain - 1L
          if (pgRemain==0L) {
            lcnt <- 0L
            fcnt <- 0L
            cnt_rst_flag <- TRUE
          }
        } else {
          lcnt <- addlt #### Reset to count ##########
          fcnt <- 0L
          pgRemain <- 0L
          cnt_rst_flag <- TRUE
        }
      }
      
      if (length(idx1)>0) { 
        if (length(idx1) <= pgRemain) {
          fcnt <- fcnt + length(idx1) 
          pgRemain <- pgRemain - length(idx1) 
          if (pgRemain==0L) {
            lcnt <- 0L
            fcnt <- 0L
            cnt_rst_flag <- TRUE
          }
        } else {
          fcnt <- length(idx1) - pgRemain  #### Reset to count ##########
          lcnt <- 0L
          pgRemain <- 0L
          cnt_rst_flag <- TRUE
        }
      } 
    } ## IN aboving, Really plot with nrow(tt, not flushed)>0
  }
  
  if (!is.na(x) & x!="") {
    if (all(!is.na(xsp))) {
      wcnt <- round(nchar(xsp)/2,0)
    } else if (all(!is.na(nsp))) {
      wcnt <- round(nchar(nsp)/2,0)
    } 
    
    keyt<- trimx(gsub('…(.*?)$|\\.{2,}(.*?)$|\\((.*?)\\)', '' ,x1)) #Total statement
    wcnt<- wcnt+ as.integer(nchar(keyt)/2) + 1 + 
      as.integer(ifelse(kflag, nchar(as.character(keyx)), as.integer(substr(padx,4,4)))/2) + 1 +
      as.integer(ifelse(prekeyx>0, nchar(as.character(prekeyx))+2, as.integer(substr(padx,4,4)))/2) + 1
    addlt<-as.integer(wcnt/wordLine)+1L
    #if (addlt>1) {addlt <- addlt+ round((addlt-1)*0.5,0)} ## consider line-height
    lcnt<- lcnt+ addlt
    
    #  if (lcnt > pageLine) {
    #    page <- page + 1L
    #    lcnt <- 0L
    #    #pret <- paste0('<p id=',dQuote(paste0("p",page)),'></p>')
    #    if (nrow(xf)>0) {
    #      xf[,page:=page]
    #    }
    #  } #else {
    #  pret <- ""
    #  #}
    
    if (all(is.na(xsex))) {
      tf  <- grepl("^female|\\bfemale", trimx(tolower(x1)))
      tm  <- grepl("^male|\\bmale", trimx(tolower(x1)))
      sex <- ifelse(tf & tm, "female,male", ifelse(tf, "female", ifelse(tm, "male", NA_character_)))
    } else {
      sex <- xsex
    }
    
    #bl <- regexpr("^[a-zA-Z]+(?:(.*?)\\:|\\s[a-zA-Z0-9])|\\b(P|A|Mx|Leg|leg|Re2)\\s{0,1}[0-9]{1,}((?:/|-)[0-9]{1,})?", x1)
    #if (bl>0 & attributes(bl)$match.length > 0) {
    #  body <- trimx(substr(x1, bl, bl+attributes(bl)$match.length-2L))
    #} else {
    #  body <- NA_character_
    #}
    
    bl <- regexpr(paste0('((^(',paste(tolower(termList[prefix==0,]$name),collapse="|"),')|\\b(',
                         paste(tolower(termList[prefix %in% c(1:2),]$name), collapse="|"),
                         '))\\s{0,}([0-9]{1,}|:)(\\s{0,}(?:/|-|&)\\s{0,}[0-9]{1,})?)|\\b(',
                         paste0(tolower(termList[prefix==3,]$name),collapse="|"),')(?:|\\s)'), 
                  tolower(x1))
    if (bl>0 & attributes(bl)$match.length > 0) {
      body <- trimx(gsub(":","",gsub("P\\s","P",gsub("/","-",substr(x1, bl, bl+attributes(bl)$match.length-1L)))))
    } else {
      body <- NA_character_
    }
  }

  xf[, fidx:=NULL] #20191014 modified
  if (blkflush_flag & length(insRow)>0 & nrow(dtk)>1) {
    dtk <- rbindlist(list(dtk,data.table(rid=i, ckey= keyx, 
                                     subkey= letters[subkeyx], pkey= prekeyx,
                                     figs=paste0(figx, collapse=","),
                                     type=nxttype, nkey=nxtk, 
                                     taxon=ifelse(!is.na(nsp), nsp, paste(xsp, collapse=",")),
                                     ctxt=xc, fkey=NA_character_, 
                                     sex=ifelse(all(is.na(sex)), NA_character_, paste(sex, collapse=",")),
                                     body=body, keyword=keyt)))
    if (length(insRow)==0) {
      dtk <- rbindlist(list(dtk, xf)) ## original old case
    } else {
      if (insRow[1]==1) {  ############# 20191014 modified
      #  dtk <- rbindlist(list(xf, dtk))
        dtk <- rbindlist(list(dtk, xf)) ## original old case
      } else 
      if (insRow[1]>=nrow(dtk)) {
        print(paste0("Error: Insert Row: ", insRow[1], " is Larger than nrow(dtk): ", nrow(dtk), " in i: ", i))
        dtk <- rbindlist(list(dtk,xf))
      } else {
        dtk <- rbindlist(list(dtk[1:insRow[1],],xf,dtk[(insRow[1]+1L):nrow(dtk),]))
      }
      insRow <- insRow[-1]
    }
  } else {
    if (kflag) { ## if major key flag found, should place key ahead of image to end with </div>
      dtk <- rbindlist(list(dtk,
                            data.table(rid=i, ckey= keyx, 
                                       subkey= letters[subkeyx], pkey= prekeyx,
                                       figs=paste0(figx, collapse=","),
                                       type=nxttype, nkey=nxtk, 
                                       taxon=ifelse(!is.na(nsp), nsp, paste(xsp, collapse=",")),
                                       ctxt=xc, fkey=NA_character_, 
                                       sex=ifelse(all(is.na(sex)), NA_character_, paste(sex, collapse=",")),
                                       body=body, keyword=keyt)#, xf
      ))
      if (length(insRow)==0) {
        dtk <- rbindlist(list(dtk, xf)) ## original old case
      } else {
        if (insRow[1]==1) {  ############# 20191014 modified
      #   dtk <- rbindlist(list(xf, dtk))
          dtk <- rbindlist(list(dtk, xf)) ## original old case
        } else {
          if (insRow[1]>=nrow(dtk)) {
            print(paste0("Error: Insert Row: ", insRow[1], " is Larger than nrow(dtk): ", nrow(dtk), " in i: ", i))
            dtk <- rbindlist(list(dtk,xf))
          } else {
            dtk <- rbindlist(list(dtk[1:insRow[1],],xf,dtk[(insRow[1]+1L):nrow(dtk),]))
          }
        }      
        insRow <- insRow[-1]
      }
    } else {
      dtk <- rbindlist(list(dtk,xf,
                            data.table(rid=i, ckey= keyx, 
                                       subkey= letters[subkeyx], pkey= prekeyx,
                                       figs=paste0(figx, collapse=","),
                                       type=nxttype, nkey=nxtk, 
                                       taxon=ifelse(!is.na(nsp), nsp, paste(xsp, collapse=",")),
                                       ctxt=xc, fkey=NA_character_, 
                                       sex=ifelse(all(is.na(sex)), NA_character_, paste(sex, collapse=",")),
                                       body=body, keyword=keyt)
      ))    
    }
  }
    
  #fx <- gsub("^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$", "", x)
  #dx <- rbindlist(sapply(x, first_keyx, simplify = FALSE, USE.NAMES = TRUE))

################################# ## still plot, but mark it in this version #######
  if (any(!is.na(fidx_dup))) {
    print(paste0("Find dup... i: ", i))
    
#    do.call(function(fidx_dup,link_dup,dtk) {
#      dupx<-grep(paste0("fig_",fidx_dup), dtk$ctxt)
#      stopifnot(any(dupx))
#      dtk[dupx, ctxt:=gsub(paste0("fig_",fidx_dup), paste0("fig_",link_dup), ctxt)]
#    }, args=list(fidx_dup=fidx_dup, link_dup=link_dup, dtk=dtk)) 
  }
################################# 
  pret <- ""
  if (rgtflush_flag) { 
    rgtflush_flag <- FALSE 
    st_keep %<>% .[!xfig %in% fig_dt[idx1,]$fidx,] ## 20191014 modified, rgtflush_flag also clear st_keep
    if (length(WaitFlush)>1) {
      WaitFlush %<>% .[-1]
    } else {
      WaitFlush[1] <- FALSE 
    }
  }
  if (blkflush_flag) {
    blkflush_flag <- FALSE
    #fblk_flag <- FALSE
    if (length(WaitFlush)>1) {
      WaitFlush %<>% .[-1]
    } else {
      WaitFlush[1] <- FALSE 
    }
    if (withinCurrKey) withinCurrKey<-FALSE
    if (nrow(st_keep)>0) {
      st_keep %<>% .[blkx>(blkcnt+1L),] ##if pret_case==1, and no consecutive blkfigs, nrow(st_keep) should 0
    }
    blkcnt <- blkcnt + 1L
  }
  if (st_conti_flag) st_conti_flag <- FALSE
  
  if (page<(1L+as.integer((nrow(dtk)-1)/pageLine))) {
    if (!cnt_rst_flag) {
      lcnt <- 0L ## Reset operation is done in the previous code...
      fcnt <- 0L
    } else {
      cnt_rst_flag <- FALSE
    }
    page <- page+1L
  }
  print(paste0("Page: ",page, " at i: ",i," Line count: ", lcnt, " & words in this line: ", wcnt, "& fig cnt: ", fcnt))
  
  i <- i+1
}



cat(na.omit(dtk$ctxt), file=paste0(web_dir, "web_tmp.txt"))

## output source fig file
fwrite(dfk[!is.na(imgf), ] %>% .[,srcf:=imglst[imgf]] %>% .[,.(fidx, srcf)], file="www/bak/src_figfile_list.csv")

length(unique(na.omit(dtk$ckey))) #187
which(!1:187 %in% unique(na.omit(dtk$ckey)))

nrow(unique(dtk[!is.na(ckey)|!is.na(subkey),])) #391
