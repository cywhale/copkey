## Versuib 5: for Genus key, that integrated with species key, Note change markdown -> HTML
## 20211110 --------------------------------------------------------------------------------
## 20211110 (Deleted) Version 2: try to maintain the compatibility with version 1
## Version 3: move blkfigure into sidebar, sidebar can turn on/off, will not consistent with the behaviors of previous version
## Version 4: Still have some bugs 1. if sp name have a spacing btw dots and name cause italitic mark * have additional spacing
##            bug 1 in New_Version_Key.docs is at 48(43) and the spacing is before Metacalanus
##            bug 2. if species annotation within (SP with sex), the sex will appear in the end with key value
##                  for example 50(49), cause copkey web appear 51_with_sex and 57_with_sex 
## Version 4_sp: for old, genus extraction and match/sync query format as read_docx05_sp.R (species extraction)
library(officer)
library(odbapi)
library(data.table)
library(magrittr)
library(stringr)
library(jsonlite)

IndexVers<- 3L ## Shih's document version
EnableBlkFig <- TRUE ## Enable Block figure, but move from main-column to sidebar
BlkFigSide <- TRUE #### After version 3
EnableLongToBlk <- FALSE #### too long side bar, flush figs into blk (Version 3 disable: all figs in sidebar)

options(useFancyQuotes = FALSE)
skipLine <- 23L
##############  #No need use dynamic pagination
wordLine <- 36 #(em) 1 line may contains 40 bytes, used to count page
pageLine <- 30 #in word docx, one page contains 55 line if 12 pt font used
figperLine<-6  #one figure is about 6 line text, to align in formats

webCite <- "from the website <a href='https://copepodes.obs-banyuls.fr/en/' target='_blank'>https://copepodes.obs-banyuls.fr/en/</a> managed by Razouls, C., F. de Bovée, J. Kouwenberg, & N. Desreumaux (2015-2017)"

#Mx -> Mx(p) #"Antenn(a|ule)", #Prosom(e|a)
termList <- data.table(name=c("A([1-9])?","(R|L)?P", "Mx(p)?", "Md", 
                              "Le(?:g|gs)", "Re", "Ri", "Head", "Crest",
                              "Rostrum", "Appendage","Antenn(?:a|ule)", "Pedigerous somites",
                              "Prosom(?:e|a)", "Urosome", "Urosomite", "Caudal ram(?:us|i)",
                              "maxilliped", "mandible"), #maxilliped, mandible used in Vers=2L
                       prefix=c(0,1,1,1,2,1,1,3,3,3,3,3,3,3,3,3,3,3,3),
                       body = c(F,F,F,F,T,F,F,T,T,T,T,T,T,T,T,T,T,T,T))

##### Note manually edit doc/Table of key... -> Fig_key_tbl.csv for first column Fig. 8,9 to two rows
  imglst <- list.files("doc/img2/", pattern="\\.jpg$",full.names = T)
  dc0 <- read_docx("doc/New_Version_Key.docx") ######################## 20191014 modified
  ftent <- rbindlist(list(tstrsplit(imglst, "_", names=TRUE)))[,3:7] %>%
    setnames(1:5, c("figx","genus","spp","sext","cht")) %>%
    .[,`:=`(Fig=as.integer(substr(figx,4,6)),
            Taxon=gsub(".jpg","",paste0(genus," ",spp)),
            Characters=ifelse(is.na(sext)|sext==".jpg", NA_character_, 
                      ifelse(is.na(cht), gsub(".jpg","", sext),
                        paste0(gsub(".jpg","", sext),": ",
                               gsub(".jpg","", cht)))),
            Remarks=NA_character_)] %>% .[,.(Fig, Taxon, Characters, Remarks)]
               
  #preimgt <- paste0('<span class=',dQuote('thumbnail'),'><a class=')
  #endimgt <- '</span></span>'
  #### Ver3 add citation text in figs.
  fcap <- fread("doc/Fig_key_ref2.csv", header = T)
#}
ctent <- docx_summary(dc0)

trimx <- function (x) {
  gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(x)))
}

padzerox <- function (x, nzero=3) {
  xt <- as.character(x)
  if (is.na(xt)) return(NA_character_)
  if (nzero <= 1 | nzero <= nchar(xt)) return(xt)
  return (paste0(paste0(rep(0, nzero-nchar(xt)), collapse=""), xt))
}

########## find file name according to fig in key #####################
find_Figfilex <- function (figxt, ftent, imglst, Vers=IndexVers) {
  #require(odbapi)
  
  fdt <- rbindlist(lapply(figxt, function(x, dt, imglst, vers) {
    idx <- match(as.character(x), dt$Fig)
    #if (any(!is.na(idx))) 
    #if have Remarks in mapping table, i.e. figs are in citations, not yet plotted, so is empty
    if (any(is.na(idx)) | (!is.na(dt[idx[[1]],]$Remarks) & trimx(dt[idx[[1]],]$Remarks)!="")) {
      if (trimx(dt[idx[[1]],]$Remarks)!="") {
        print(paste0("No fig provided, only in REF: ", trimx(dt[idx[[1]],]$Remarks), "...in i: ", i))
      }
      return(list(fidx=idx, imgf=NA_integer_, 
                  fsex=NA_character_, body=NA_character_, remark=trimx(dt[idx[[1]],]$Remarks)))
    }
    
    sp <- dt[idx[[1]],]$Taxon
    
    #### too many fuzzy choices.. just use sex as a criteria to judge which file belong to this fig/key    
    tf <- grepl("^female|\\female", trimx(tolower(dt[idx[[1]],]$Characters)))
    tm <- grepl("^male|\\bmale", trimx(tolower(dt[idx[[1]],]$Characters)))
    if (length(tf)==0 & length(tm)==0) {
      sex <- NA_character_
    } else {
      sex<- ifelse(tf, "female", ifelse(tm, "male", NA_character_))
    }
    
    #"\\b(P|A|Mx|Leg|leg|Re2)\\s{0,1}[0-9]{1,}((?:/|-)[0-9]{1,})?"
    body <- NA_character_
    if (!is.na(dt[idx[[1]],]$Characters)) {
      bl <- regexpr(paste0('((^(',paste(tolower(termList[prefix==0,]$name),collapse="|"),')|\\b(',
                           paste(tolower(termList[prefix %in% c(1:2),]$name), collapse="|"),
                           '))\\s{0,}([0-9]{1,}|:)(\\s{0,}(?:/|-|&)\\s{0,}[0-9]{1,})?)|\\b(',
                           paste0(tolower(termList[prefix==3,]$name),collapse="|"),')(?:|\\s)'), 
                    tolower(dt[idx[[1]],]$Characters))
      if (bl>0 & attributes(bl)$match.length > 0) {
        body <- trimx(gsub(":","",gsub("P\\s","P",gsub("/","-",substr(dt[idx[[1]],]$Characters, bl, bl+attributes(bl)$match.length-1L)))))
      } #else {
        #body <- NA_character_
      #}
    }
    #if (vers>1L) {  #20211112 delete old versions
    return(list(fidx=idx, imgf=idx, fsex=sex, body=body, remark=NA_character_))
    #}
  }, dt=ftent, imglst=imglst, vers=Vers))

  return(fdt)  
}
###############################################################################################
tstL <- nrow(ctent)
inTesting <- FALSE  ### please change it to FALSE when generate HTML finally

#tstL <- 308L #key 90(89) #150L #(chk Fig63) #before 107L #key25 93L #key22 #79L #key18 #60L #Calanidae 65L Sinocalanus  #50L #fig.11

#page lcnt, fcnt No need use dynamic pagination, BUT, change to reset after every align with text and fig 20190126
lcnt <- 0L; fcnt <- 0L; page <- 1L #word count and line count (text:lcnt, fig:fcnt) 
insRow<-c()  ########### insert fig in right row of gtk
insBlkId<-c() ########## insert a block in HTML code
WaitFlush<- c(FALSE) ### Wait Next primary key and flush out stacked Number of figs (before that primary key)!!
blkflush_flag<- FALSE ## Now flush block of figs!!
gblk_cnt <- 0L; ########## blocks ID (how many times we flush out blocks of figs)
rgtflush_flag<- FALSE ## Flush figs in right-side column
keyx <- 0L; subkeyx <- 1L; padx = "pad1"; indentx = "indent2"
withinCurrKey <- FALSE # Within one major key, in version3, those figs within will merge into block(blk) figs
st_conti_flag <- FALSE # line cutted by longer dots, and continue to next line
fig_conti_flag<- FALSE # figs stacked in st_keep
st_keep <- data.table(xfig = integer(), xkey = integer(), blkx = integer(), case = integer(),
                      nsp = character())#xdiv = character()) #202111 add to give it in a div id "00a_genus_unikeyxx_figs_00x"
xdiv_id <- ""
ukeyPrex <- "00a_genus_" #"Calanoid_"

gtk <- data.table(rid=integer(), unikey=character(), ckey=character(), # integer-> character, consistent with sp
             subkey=character(), pkey=character(), ##################### 20211110
             figs=character(), type=integer(), nkey=integer(), 
             taxon=character(), keystr=toJSON(character()),
             ctxt=character(), fkey=character(),
             sex=character())#, docn=integer(), kcnt=integer()) ######## docn always 0
             #body=character(), keyword=character()) #, ####### keyword -> keystr
             #page=integer())
gtk <- gtk[-1]

#### Used to store figs <-> fig_file mapping
gfk <- data.table(fidx=integer(),
                  fkey=character(), ckeyx=character(),
                  imgf=integer(), fsex=character(), 
                  body=character(), remark=character(), fdup=character(), # the imgf had been used (diff figx, use the same imgf)
                  flushed=integer(),  ## flushed means if flushed to ctxt already (1, otherwise 0)
                  case=integer(), blkx=integer(), ### case: blkfigure or not; blkx: counter of block of fig flushed into block
                  #kcnt=integer(), tokcnt=integer(), 
                  #xdtk=character(), 
                  taxon=character())
i = skipLine+1L
prekeyx <- 0L
pret <- ""

while (i<=30L) { #nrow(ctent)) {

  x <- gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i])))
  
  tt <- which(is.na(x) | x=="")
  if (any(tt)) {
    if (i<tstL) {
      i <- i+1
      next
    }
  } else {
    if (!st_conti_flag) {
      stcnt <- 1L; wcnt <- 0L #word count, #stcnt: pointer where to start to catch key in a statement 
      figx <- NA_integer_; fidx_dup <- NA_integer_ ## some duplicated fig_ling but link to the same fig file
      kflag <- FALSE #; prekflag <- FALSE; figflag <- FALSE; 
      nxtk <- 0L; nxttype <- 0L; #0: integer key, 1: sp name 
      pret_case <- 0L # 1L: fig. xx-yy and display in block of main-column
      #fblk_flag <- FALSE; # if flag, display figs in block of main-column (not in right-side)
      nsp <- NA_character_; xsp <- NA_character_; xf <- NA_character_
      xsex<- NA_character_; body <- NA_character_; keyword <- NA_character_
      cnt_rst_flag <- FALSE; ###### counter reset flag if the page had only few figs so idx1=0 idx2=0 not exhaust pgRemain
      
      ## detect primary key, such as "1 Head..."
      x1 <- x; x2<-x
      wl <- regexpr("^[0-9]{1,}(?:\\s|[a-zA-Z]|\\()",x)
      if (attributes(wl)$match.length>0) {
        keyx <- as.integer(substr(x,wl,wl+attributes(wl)$match.length-2L)) 
        stopifnot(!any(is.na(keyx))) ## because HTML no more support <a name...> for anchor, we use font id to be catched
          pret <- paste0('<div class=', dQuote('kblk'),'><p class=', dQuote('leader'), 
                         '><span class=',dQuote('keycol'),'>',
                         '<mark id=', dQuote(paste0('key_', keyx)), '>', keyx, '</mark> ')
        stcnt<- nchar(pret)+1L #move pointer to next start in a statment
        x1<- substr(x,wl+attributes(wl)$match.length-1L, nchar(x))
        xc<- paste0(pret,x1) #HTML results
        kflag <- TRUE #primary key found
        ##########################################################################################
        #..........pkey......skey.....pkey....skey.....pkey....
        #Kflag.....11111111110000000001111111100000000011111...
        #figx.........11111(sometimes have figs)...1111........
        #fig_conti_flag.111111111111111100(Delay flush until next key, all previous primary-secondary keys unit end)
        #wCurrKey.......00000111111111111000000000.............
        #WaitFlush[1](Ver3)............111100000000.... inform next primary key have found, need flush figs, a pulse.
        ##########################################################################################
        if (fig_conti_flag & withinCurrKey & IndexVers>2) {
          WaitFlush[1] <- TRUE ## Need to flush all prev-key figs
          fig_conti_flag<-FALSE
          withinCurrKey<- FALSE
        }
        prekeyx <- 0L #if primary key not found, no update for prekeyx
        subkeyx <- 1L
      } else {
        xc<- x1
        subkeyx <- subkeyx + 1L
        if (!withinCurrKey) withinCurrKey <- TRUE
      }
      ukeyx <- paste0(ukeyPrex, padzerox(keyx, 3), letters[subkeyx])
      
      ## detect pre key, such as "2(1) Head..."
      wl0s <- regexpr("^\\((?:[0-9]{1,})\\)",x1)
      if (attributes(wl0s)$match.length>0) {
        cat("Detect prekey in i: ", i, "\n") 
        prekeyx <- as.integer(substr(x1,2L, attributes(wl0s)$match.length-1L)) 
        stopifnot(!any(is.na(prekeyx)))
        
        pret0s <- #paste0('([', prekeyx, '](#key_', prekeyx, '))&nbsp;')
                  paste0('(<a href=', dQuote(paste0('#key_', prekeyx)), '>', prekeyx,'</a>)&nbsp;')
        
        x1<- substr(x,wl+attributes(wl)$match.length-1L+attributes(wl0s)$match.length, nchar(x))
        xc<- paste0(pret, pret0s, x1)
        stcnt <- nchar(pret)+nchar(pret0s) +1L
      }
    }  
    
    ## detect figure index, such as "Head... (figs.1,2) and too-long dots start and end, such as "figs)……..2"    
    if (st_conti_flag) {
      x1t <- x ## a cutted line due to word with too-long dots
    } else {
      x1t <- x1 # Normal cases
    }
    wl1 <- regexpr("\\(*(f|F)ig{1}(s)*(\\.|\\s)*",x1t) ## fig. figs. w/o space + Number(fig id, 1-3 digits)
    wl2 <- regexpr("(?:((f|F)ig{1}(.*?)))\\)",x1t)
    
    if (attributes(wl1)$match.length>0 & attributes(wl2)$match.length>0) {
      st_fig_find <- TRUE
    } else {
      st_fig_find <- FALSE
      if (st_conti_flag) {x2 <- x}
    }
    ############## Some fig label scattered in the long sentences.. need find them independently
    while (st_fig_find) {
      #figt<- tstrsplit(gsub("\\.|\\s","",substr(x1t,attributes(wl1)$match.length-1, attributes(wl2)$match.length-1L)), ",") %>%
      fnt <- substr(x1t,wl1+attributes(wl1)$match.length, wl2+attributes(wl2)$match.length-2L)
      if (grepl('-',fnt)) {
        figt <- tstrsplit(fnt,"-") %>% unlist(use.names = F) %>% trimx() %>% as.integer() 
        figt <- seq(figt[1], figt[length(figt)])
        pret_case <- 1L ## different HTML code for (fig. 35-37) (it means figs 35,36,37)
      } else {
        figt <- tstrsplit(gsub("\\.|\\s","",fnt), ",") %>% unlist(use.names = F) %>% trimx() %>% as.integer()
        pret_case <- 0L #default: it's for (fig. 35,36)
      }
      stopifnot(all(!is.na(figt)))
      
      if (all(!is.na(figx))) {
        figx <- c(figx, figt)
      } else {
        figx <- figt
      }
      
      # Design in Species is to link figs_xxx(blk), but it's hard to do so in Genus, because blk can be delayed
      # fig 3 might be delayed to ouput until fig 4 in next key string, thus cannot be correctly extracted
      # to a right figs_xxx(blk) when only fig 3 found in this key string. 
      # So we still let fig 3 scroll to <span fig_3> and the outer div blk id (xdiv_id) is determined later until it's flushed
      # ### old, not work as aboving reason: modified 20211112 for fig_key according all figs in blk not only one fig_num, Duplicated figs should be checked earlier
      # #xdiv_id <- rep("", length(figx))
      # #if (any(figx %in% gfk$fidx)) {
      # #dupft <- gfk[blkx %in% gfk[fidx %in% figx,]$blkx, .(fidx, blkx)] %>% 
      #  .[,xdiv:= paste0("figs_",paste0(sapply(fidx, function(x) {padzerox(x,3)}, simplify = T, USE.NAMES = F), collapse="_")), by=.(blkx)]
      #  xdiv_id[figx %in% gfk$fidx] <- dupft[match(figx[figx %in% gfk$fidx], fidx),]$xdiv
      # #}
      # #if (any(!figx %in% gfk$fidx)) {
      # #xdiv_id[!figx %in% gfk$fidx] <- paste0("figs_", 
      # #     paste0(sapply(figx, function(x) {padzerox(x,3)}, simplify = T, USE.NAMES = F), collapse="_"))
      # #}
      
      if (pret_case == 1L) { #means e.g., fig. 5-8 in key string, that link to <div figs_005_006_007_008
        fdivx <- paste0("figs_", 
                 paste0(sapply(figx, function(x) {padzerox(x,3)}, simplify = T, USE.NAMES = F), collapse="_"))
        pret<- paste0('<a href=', dQuote(paste0('#fig_', fdivx)),'>', fnt,'</a>')
        insBlkId <- c(insBlkId, fdivx) #paste0('figblk_',fnt)
      } else {
        pret<- do.call(function(x) {paste0('<a href=', dQuote(paste0('#fig_',x)), '>',x, '</a>')}, list(figt)) %>% paste(collapse=", ")
        #pret<- do.call(function(x) {
        #    paste0('<a href=', dQuote(paste0('#',xdiv_id,'-',x)), '>',x, '</a>')
        #  }, list(figt)) %>% paste(collapse=", ")
      } #Note that #figs_001_002-1 <- "-1" not match when try to find dom, only for open the real image (Fig001)
      
      x2<- substr(x1t,wl2+attributes(wl2)$match.length, nchar(x1t))
      if (st_conti_flag) {
        xc <- paste0(xc, " ", substr(x1t,1,wl1+attributes(wl1)$match.length-1L), 
                     pret, ')')
      } else {
        xc<- paste0(substr(xc,1L,stcnt+wl1+attributes(wl1)$match.length-2L),  # stcnt now is the exact position if start, so -1L to calculate position
                    pret, substr(xc,stcnt+wl2+attributes(wl2)$match.length-2L,nchar(xc)))
      }
      
      if (!(any(grepl("fig\\.",x2)))) {
        st_fig_find <- FALSE
      } else {
        x1t <- x2
        stcnt <- nchar(xc)-nchar(x1t) + 1L
        wl1 <- regexpr("(f|F)ig{1}(s)*(\\.|\\s)*",x1t)
        wl2 <- regexpr("(?:((f|F)ig{1}(.*?)))\\)",x1t)
      }
    }
    
    wl3 <- regexpr("(?:…+\\.*\\s*)[0-9]+$",x2)
    if (wl3<0) {
      wl3 <- regexpr("(?:…+\\.*\\s*)[a-zA-Z]+(.*?)\\s{0,1}(♀|♂|\\))*\\s{0,1}$",x2)
      
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
      nsp <- as.character(gsub("…|\\.","",substr(x2,wl3+1,nchar(x2))))
      stopifnot(!any(is.na(nxtk)))
      nxttype <- 1L
      stt <- nchar(nsp)
      wl3t <- regexpr("\\s*(♀|♂)\\s*",nsp)
      if (wl3t>0) {
        tt <- trimx(substr(nsp,wl3t,wl3t+attributes(wl3t)$match.length-1L))
        xsex<-ifelse(tt=="♂","male","female")
        nsp <-substr(nsp,1,wl3t-1L)
      }
    } else {
      nxtk <- as.integer(gsub("…|\\.","",substr(x2,wl3+1,nchar(x2))))
      stopifnot(!any(is.na(nxtk)))
      nxttype <- 0L 
      stt <- nchar(paste0(nxtk))
    }
    
    #### Detect annotated species in description, not the next link or sp (nsp) ########  
    #### and sex ♀ (female) ♂ (male)
    wl4 <- regexpr("\\s{0,}\\([A-Z][a-z]+(.*?)\\)\\s{0,}(?:…{1,}\\s{0,}|\\.{1,}\\s{0,})",x2)
    if (wl4>0 & attributes(wl4)$match.length>0) {
      xsp <- trimx(gsub("\\(|\\)|\\.|…","",substr(x2,wl4,wl4+attributes(wl4)$match.length-1L))) #%>%
      wltt<- regexpr(",",xsp) ## Key34(32)  "Augaptilidae, part"
      if (wltt>0) {
        xtt<- substr(xsp,wltt,nchar(xsp))
        xsp<- substr(xsp,1,wltt-1)
      } else {
        xtt<- ")"
      }
      
      #tstrsplit("&") %>% unlist(use.names = F)
      
      print(paste0("Find annotated species: ", paste(xsp, collapse=","), " in i: ", i))
      
      xspt <- tstrsplit(xsp,"&") %>% unlist(use.names = F) %>% trimx()
      ############################### Extract sex info
      wl4t <- regexpr("(♀|♂)",xspt)
      
      if (any(wl4t>0)) {
        wl4t[wl4t<0] <- 0
        tt <- substr(xspt,wl4t,wl4t)
        xsex<-sapply(tt, function(x) {ifelse(x=="♂","male","female")}, simplify = TRUE, USE.NAMES = FALSE)
        xspx<- trimx(substr(xspt,1,wl4t-1L))
        xsex[wl4t==0] <- NA_character_
        xspx[wl4t==0] <- xspt[wl4t==0]
      } else {
        xsex<- rep(NA_character_, length(xspt))
        xspx<- xspt
      }
      
      pret0s <- sapply(xspx, function(x) {
        ifelse(substr(x, nchar(x)-1L, nchar(x))=="ae", 'strong>', 'em>')
      }, simplify = TRUE, USE.NAMES = FALSE)
      
      pret<- do.call(function(x, pres, sex) {paste0('<mark id=',dQuote(paste0(ifelse(is.na(sex),'taxon_', paste0(sex,'_')), 
                                                                              gsub("\\s","_",x))),
                                                    '><', pres, x, '</', pres, ifelse(is.na(sex),"",ifelse(sex=="female","♀","♂")),
                                                    '</mark>')}, 
                     list(x=trimx(xspx), pres=pret0s, sex=xsex)) %>% paste(collapse=" & ")
      
      tt <- substr(x2, wl4, nchar(x2))
      wl4t <- regexpr(xtt,tt) #")"
      
      xc <- paste0(substr(xc,1L,regexpr(xsp,xc)-1), #nchar(xc)-nchar(x2)+2L), 
                          pret, substr(tt,wl4t, nchar(tt)))
      xsp<- xspx
    }
    
    xc<-paste0(gsub("…|\\.{2,}|…\\.{1,}|\\.{1,}…","",ifelse(st_conti_flag, xc, substr(xc,1,nchar(xc)-stt))),
               '</span><span class=',dQuote('keycol'),'>',
               ifelse(nxttype==0L, 
                      paste0('<a href=',dQuote(paste0('#key_',nxtk)), '>', nxtk, '</a>'), 
                      paste0('<mark id=', 
                             dQuote(paste0(ifelse(all(is.na(xsex)),'taxon_',paste0(xsex,"_")),paste(unlist(tstrsplit(nsp,'\\s')),collapse='_'))), '><em>', nsp, '</em></mark>')),
               ifelse(all(is.na(xsex)),"",ifelse(xsex=="female","♀","♂")),'</span></p>')
    
    if (keyx>=100 & prekeyx>=100) {
      padx = "pad8"
      indentx = "indent4"
    } else if ((keyx>=100 & prekeyx>=10) | prekeyx>=100) {
      padx = "pad7"
      indentx = "indent3"
    } else if ((keyx>=100 & prekeyx>0) | (keyx>=10 & prekeyx>=10)) {
      padx = "pad6"
      indentx = "indent3"
    } else if ((keyx>=10 & prekeyx>0) | prekeyx>=10) {
      padx = "pad5"
      indentx = "indent3"
    } else if (prekeyx > 0) {
      padx = "pad4"
      indentx = "indent2"
    } else if (keyx>=100 & prekeyx==0) {
      padx = "pad3"
      indentx = "indent2"
    } else if (keyx>=10 & prekeyx==0) {
      padx = "pad2"
      indentx = "indent2"
    } else {
      padx = "pad1"
      indentx = "indent2"
    }
    
    if (!kflag) {
      if (IndexVers==1L) {
        xc <- paste0('<p class=', dQuote('leader'), '><span class=', #ifelse(prekeyx>0, dQuote('keycol pad4'), dQuote('keycol pad1')), 
                     dQuote(paste0('keycol ', padx)), '>', xc)
        #paste(rep("&nbsp;",ifelse(prekeyx>0, 9L, 3L)),collapse=""), xc)
      } else {
        xc <- paste0('<div ckass=',dQuote('kblk'), 
                     '><p class=',dQuote(paste0('leader ', indentx)),'><span class=',
                     dQuote(paste0('keycol ', padx)), '>', xc)
      }
    } else if (IndexVers>1L) { ## need insert indention in new version
      xc <- gsub("<p class(.*?)><span", paste0('<p class=',dQuote(paste0('leader ', indentx)),'><span'), xc)
    }
  } 
  xc <- paste0(xc,'</div>')
  
  if ((i==tstL & !inTesting) | (kflag & !st_conti_flag & WaitFlush[1])) {
    if (is.na(x) | x=="") {
      xc <- ""
      figx <- NA_character_
    }
    #if (i==tstL & !inTesting) {
    #  xc <- paste0(xc,"</div>")
    #}
    
    if (WaitFlush[1] | (nrow(gfk)>0 & any(gfk[!is.na(imgf),]$flushed==0L))) {
      if (nrow(gfk[!is.na(imgf) & flushed==0L,])==1 & nrow(st_keep)==1 & any(is.na(figx))) {
        rgtflush_flag <- TRUE  ###
        blkflush_flag <- FALSE ### 20191015 modified, so that we can pipe fig more earlier
      } else {
        blkflush_flag <- TRUE
      }
      #if (IndexVers<=2) 
      print(paste0("Check insRow correct: ", paste(insRow,collapse=","), " with i: ", i, " with key: ", keyx))
      insRow[1] <- nrow(gtk) ## update insert Row number just before current key (still not in gtk)
    ########################################### Ver3: all figs in sidebar, so insRow will be earlier when figx found
    }
  }  


#  if (nxttype==0L & any(is.na(xsp)) & any(!is.na(figx)) & length(figx)>=1) { # Have figs link but no taxa info
#  20180126 : st_keep change to keep figs in order to keep figs in block with 2-columns
############################################################################################
## Case 1: if pret_case==1L: Find blk-fig by author (figs. xx-yy), piped them and flush before next primary key
## Case 2: if pret_cast==1L and WaitFlush==TRUE, means next blk comes, and previous one still not flushed-out yet
##         We still need to piped them in next gblk_cnt ID
## Case 2a:if too much figs already in right-side, and pret_case==0L, we can wait until previous blk is going to
##         be flushed (blkflush_flag set) and pipe these new figs in new block
## Case 3: if pret_case==0L but too-much right-side figs, we stacked 2 or 3 figs and flushed in main-column
## Case 4: if previous case is pret_case==0L and still WaitFlush or fig_conti_flag, but now pret_case==1L comes,
##         Just flushed the stacked fig in right-side and pieped the block of current case (pret_case==1L)      
  if (!any(is.na(figx)) & nrow(gfk)>0) {
    chkfx <- sapply(figx, function(x) match(x, gfk[!is.na(imgf),]$fidx))
    if (any(!is.na(chkfx))) { ## already mapping gfk, no need to query again
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
         #gfk[fidx %in% st_keep[case==0L,]$xfig, blkx:=max(blkx)+1]
       } else {
         rgtflush_flag <- TRUE ### Case 4: flush figs in right-side column!
         gfk[fidx %in% st_keep[case==0L,]$xfig, blkx:=0L]
       }
     }
     if (!WaitFlush[1]) {
       tt <- nrow(st_keep) + length(figx)
       if (!is.na(nsp) && nsp!="") print(paste0("Push nsp into gfk: ", nsp, " when fidx: ", paste0(fdt$fidx, collapse=",")))
       st_keep <- rbindlist(list(
                    st_keep, 
                    data.table(xfig=figx, xkey=nxtk, blkx=gblk_cnt+1L, case=pret_case, nsp=nsp)))
                               #xdiv=xdiv_id)))
       ############################## Case 3 pipe
       print(paste0("... Piping figs in st_keep in i: ",i, " with figs: ", paste(figx, collapse=",")))
       if (!rgtflush_flag & !blkflush_flag) {
         fig_conti_flag <- TRUE
       }
       #if (nrow(gtk)==0) {
       # insRow[1] <- 1
       if (kflag) {
          insRow[1] <- nrow(gtk)+1L #Ver3: insRow will be earlier ## Note <p>marginnote</p> must inside <div kblk></div>
       }
     } else if (WaitFlush[1] & (IndexVers<=2 | kflag)) { #if (WaitFlush[1] & pret_case!=0L & !rgtflush_flag) { #### Case 2, 2a pipe
       print(paste0("Warning: 2-nd block comes and pipe fig in st_keep in i: ",i, " with figs: ",
                    paste(figx, collapse=",")))
       if (!is.na(nsp) && nsp!="") print(paste0("Push nsp into gfk: ", nsp, " when fidx: ", paste0(fdt$fidx, collapse=",")))
       st_keep <- rbindlist(list(st_keep, 
                                 data.table(xfig=figx, xkey=nxtk, blkx=max(st_keep$blkx)+1L, case=pret_case,
                                            nsp=nsp)))#xdiv=xdiv_id)))
       fig_conti_flag <- TRUE
       WaitFlush <- c(WaitFlush, FALSE)
       insRow <- c(insRow, nrow(gtk)+1L)
     }
   } else {
     #if (!blkflush_flag) {
       #fblk_flag <- FALSE
     if (!any(is.na(figx))) {rgtflush_flag <- TRUE}
     #}
   } 

    
  if (any(!is.na(figx)) & length(figx)>=1) { ## Normal cases
    chkfx <- sapply(figx, function(x) match(x, gfk$fidx))
    if (any(!is.na(chkfx))) { ## already mapping gfk, no need to query again
      figxt <- figx[-which(!is.na(chkfx))]
      
      gfk[fidx %in% figx[which(!is.na(chkfx))] & flushed==0, ckeyx:=keyx] ##update fig/cur_key mapping
    } else {
      figxt <- figx
    }
    
    if (length(figxt)>=1) {
      fdt <- find_Figfilex(figxt, ftent, imglst) ##### Find fig file in imglst
      
      if (any(is.na(fdt$fsex)) & !all(is.na(xsex))) {
        print(paste0("Warning: Not found sex info in Table, but actually in Key doc, sp: ", 
                     paste(na.omit(c(nsp,xsp)),collapse=","), " in i: ", i))
        if (nrow(fdt[is.na(fsex),])!= length(xsex)) {
          print(paste0("Warning: Cannot determine sex in fdt, i: ", i,
                       " for xsex: ", paste(xsex, collapse = ",")))
        } else {
          fdt[is.na(fsex), fsex:=xsex]
        }
      }
##### fdt imgf may appear in previous gfk and had been flushed #############################################      
      fdt[,fdup:=""] 
      if (nrow(gfk)>0) {
        fdt %<>% .[imgf %in% gfk[!is.na(imgf),]$imgf, fdup:="DUP"] ## still plot, but mark it in this version
      }
      gfk <- rbindlist(list(gfk, fdt[,`:=`(flushed=0L, ckeyx=keyx, case=pret_case,
                                           blkx=ifelse(rgtflush_flag, 0L, max(st_keep$blkx)),
                                           fkey=NA_character_, 
                                           #kcnt=insRow+1, tokcnt=insRow, xdtk=as.character(insRow), 
                                           taxon=NA_character_)]),
                       use.names=TRUE)
      
      if (any(is.na(fdt$imgf))) {
        print(paste0("Check img file corresponding is NA in i: ", i))
        print(paste(fdt[is.na(imgf),]$fidx, collapse=","))
      }
      ####### 
      ####### Re-determine plot status, since fig numbuer may NA and changed, cannot fit into 2-column block        
      if (any(is.na(fdt$imgf)) | length(figxt)!=length(figx) | ## fig number changed
          !any(gfk[!is.na(imgf),]$flushed==0L)) { ## No figs available, so that delete in st_keep
        if (any(is.na(fdt$imgf)) & fig_conti_flag) {
          st_keep %<>% .[!xfig %in% fdt[is.na(imgf),]$fidx,]
          tt <- sort(unique(na.omit(c(st_keep$xfig,figx[!figx %in% fdt[is.na(imgf),]$fidx]))))
          if (length(tt)>=2 & (length(tt) %% 2 == 0L | length(tt) %% 3 == 0L)) {
            fig_conti_flag <-FALSE
            if (nrow(st_keep)>0) {
              st_keep %<>% .[blkx>(gblk_cnt+1L),] ## flush it!
            }
            WaitFlush[1] <- TRUE
          }
        } else if (!any(gfk[!is.na(imgf),]$flushed==0L)) {
          st_keep <- data.table(xfig=integer(), xkey=integer(), blkx=integer(), case=integer())  ### clear NA data
          #fblk_flag <- FALSE; 
          fig_conti_flag <- FALSE; rgtflush_flag <- FALSE; blkflush_flag <- FALSE
          WaitFlush <- c(FALSE); insBlkId <- c(); insRow <- c();
          
        } #else if (pret_case==0L & length(figxt)!=length(figx) & !rgtflush_flag &
          #         nrow(gfk[!is.na(imgf) & flushed==0L,])==1L) {
          #st_keep <- rbindlist(list(st_keep, 
          #                          data.table(xfig=figxt, 
          #                                     xkey=gfk[match(figxt,fidx),]$ckeyx)))
          #fig_conti_flag <- TRUE; WaitFlush[1] <- FALSE
          ##fblk_flag <- TRUE ############### Wait next chance to flush, keep in st_keep
        #}
      }
    }
  }
  xf <- data.table(rid=integer(), unikey=character(), ckey=character(), 
                   subkey=character(), pkey=character(),
                   figs=character(), type=integer(), nkey=integer(), 
                   taxon=character(), keystr=toJSON(character()), ctxt=character(), fkey=character(),
                   sex=character(), #docn=integer(), kcnt=integer(), 
                   #body=character(), keyword=character(), 
                   fidx=integer()) #20191014 modified to re-order xf 
  xf <- xf[-1]
#### plot immediately, Output Fig HTML code  
  fig_dt <- gfk[FALSE,]
  if ((rgtflush_flag | blkflush_flag) & any(gfk[!is.na(imgf),]$flushed==0L)) { 

    if (rgtflush_flag) {
      if (!blkflush_flag) {
        fig_dt <- gfk[!is.na(imgf) & flushed==0L & case==0L,]
        fig_dt[,flushed:=1L]
      } else {
        if (nrow(gfk[!is.na(imgf) & flushed==0L & case==0L & blkx==0L,])>0) {
          fig_dt <- gfk[!is.na(imgf) & flushed==0L & case==0L & blkx==0L,]
          fig_dt[,flushed:=1L]
        } else {
          rgtflush_flag <- FALSE ##it means figxt!=figx, duplicated figx (had been outputted) is used in previous statement
        }
      }
    } 
    if (blkflush_flag) {
      fig_dt <- rbindlist(list(fig_dt, 
                               gfk[!is.na(imgf) & flushed==0L & blkx==(gblk_cnt+1L),] %>% .[,flushed:=2L]))  
      
    }
    if (nrow(fig_dt)>0) {
      #################### Ouput Figure HTML Function ##############################
      ####### Both not in gfk, but they are using the same imgf, not detected in previous code
      tdup <- which(duplicated(fig_dt$imgf))
      if (any(tdup)) {
        fidx_dup <- fig_dt$fidx[tdup]
        link_dup <- sapply(fig_dt$imgf[tdup], function(x, ftx) {ftx[match(x, imgf),]$fidx[1]},
                           ftx=fig_dt[-tdup,])
        print(paste0("Duplicate link to fig: ", paste(link_dup, collapse=",")))
        stopifnot(all(!is.na(link_dup)))
        ################################# ## still plot, but mark it in this version ##################
        #gfk[fidx %in% fig_dt[tdup,]$fidx, flushed:=99L] #fig_dt[tdup,]$flushed] ## the duplicated plot actually not plotted 
        #fig_dt %<>% .[-tdup,] 
        ################################# ## temporarily only mark it 
        gfk[fidx %in% fig_dt[tdup,]$fidx, fdup:="DUP"]
        fig_dt[tdup, fdup:="DUP"]
      }
      
      fn <- imglst[fig_dt$imgf]
      outf<-gsub("\\s{1,}","_",substr(fn,22,nchar(fn)))

      flink <- paste0("fig_", fig_dt$fidx) #figx) 
      
      for (j in seq_along(outf)) {
        if (!file.exists(paste0("www_sp/assets/img/genus/",outf[j]))) {
          cat("copy file from img: ", outf[j])
          system(enc2utf8(paste0("cmd.exe /c copy ", gsub("/","\\\\",paste0("D:/proj/copkey/",fn[j])), 
                                 " ",gsub("/","\\\\",paste0("D:/proj/copkey/www_sp/assets/img/genus/",outf[j])))))
        }
      }

      ft <- sapply(outf, function(outf) {paste(unlist(tstrsplit(gsub("Fig[0-9]{1,}_|\\.jpg|\\(|\\)","",outf),"_|-")), collapse=" ")},
                   simplify = T, USE.NAMES = F)
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
      gfk[!is.na(imgf) & flushed==0L & fidx %in% fig_dt$fidx,
          `:=`(taxon=spt, fkey=flink, remark=gsub("\\.jpg", "", outf))] 
      
      
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
          #insBlkId <- c(paste0("fig_",paste(c(fig_dt[idx2,]$fidx[1],fig_dt[idx2,]$fidx[length(idx2)]), collapse="-")))
          #insBlkId <- st_keep[xfig %in% fig_dt[idx2,]$fidx,]$xdiv[1]
          insBlkId <- paste0("figs_", 
                      paste0(sapply(fig_dt[idx2,]$fidx, function(x) {padzerox(x,3)}, simplify = T, USE.NAMES = F), collapse="_"))
        }
        if (IndexVers<=2L & length(idx2) %% 3 == 0) {
          spanx <- 'ntrd' ### narrow span
        } else if (IndexVers>2L & length(idx2) == 1) {
          spanx <- 'nfig'
        } else { ############ otherwise, 2 figs in a line, use wider span
          spanx <- 'ntwo'
        }

        ############################# Ver3: add fig captions from file (fcap)
        caps <- mapply(function(x, sp, fcap, webCite) {
            paste0("<em>",sp,"</em>, ",
                    ifelse(is.na(fcap[Fig==x,]$characters),"",fcap[Fig==x,]$characters),
                    ifelse(is.na(fcap[Fig==x,]$ext),"", paste0("<br>",fcap[Fig==x,]$citation, ", ", webCite)))
          }, x=fig_dt[idx2, ]$imgf, sp=spt[idx2], 
             MoreArgs = list(fcap=fcap, webCite=webCite), SIMPLIFY = TRUE, USE.NAMES = FALSE)
        fig_kstr <- gsub("<((\\/)*em|br)>", "", caps)
        fig_nsp <- na.omit(st_keep[xfig %in% fig_dt[idx2, ]$fidx,]$nsp)[1]
        if (!is.na(fig_nsp) && fig_nsp!='') {
          fig_title <- paste0('Classification key: #<a href=', dQuote(paste0("#key_", fig_dt[idx2,]$ckeyx[1])),
                              '>', fig_dt[idx2,]$ckeyx[1], '</a> for genus: <em>', fig_nsp, '</em>')
        } else {
          fig_title <- paste0('Classification key: #<a href=', dQuote(paste0("#key_", fig_dt[idx2,]$ckeyx[1])),
                              '>', fig_dt[idx2,]$ckeyx[1], '</a> (Next key: #<a href=', 
                              dQuote(paste0("#key_", st_keep[xfig %in% fig_dt[idx2,]$fidx,]$xkey[1])), 
                              '>', st_keep[xfig %in% fig_dt[idx2,]$fidx,]$xkey[1], '</a>)')
        }
        xf <- data.table(rid=i, unikey=paste0(ukeyx, '_', insBlkId),
                         ckey=NA_integer_, subkey=NA_character_, pkey=NA_integer_,
                         figs=paste(fig_dt[idx2,]$fidx,collapse=","),  type=2, nkey=NA_integer_, 
                         taxon=paste(spt[idx2],collapse=","),
                         keystr=toJSON(paste0(fig_kstr, collapse="; ")),
                         ctxt=paste(paste0('\n\n<div id=', dQuote(insBlkId), 
                                           '><div class=', dQuote('blkfigure'),'>'),
                                    paste0('<div class=', dQuote('fig_title'), '><span class=', dQuote('spmain'), '>',
                                           fig_title, '</span></div>'),
                                    mapply(function(outf,flink,cfigx,#sp,sex,
                                                    ckeyx,spanx,#fdupx,
                                                    capx) {
                                        paste0('<span class=', dQuote(spanx), '><a data-fancybox=', dQuote('gallery'), 
                                               ' class=', dQuote("fbox"), 
                                               ' href=', dQuote(paste0('#',flink)),
                                               '><img src=',
                                               dQuote(paste0('https://bio.odb.ntu.edu.tw/pub/copkey/gthumb/',outf)), ' border=', dQuote('0'),
                                               ' alt=', dQuote(gsub("<((\\/)*em|br)>", "", capx)), 
                                               ' /></a><span id=', dQuote(flink), ' class=', dQuote('spcap'),
                                               '>Fig.',cfigx,'. ',capx,'</span></span>') ############ Only MARK duplicated imgf
                                      },outf=outf[idx2], flink=flink[idx2], cfigx=fig_dt[idx2,]$fidx, 
                                      #sp=spt[idx2], sex=sxt[idx2], ckeyx=fig_dt[idx2,]$ckeyx, fdupx=fig_dt[idx2,]$fdup,
                                      capx=caps, MoreArgs = list(spanx=spanx), SIMPLIFY = TRUE, USE.NAMES = FALSE) %>% 
                                        paste(collapse=""),
                                    '</div><br><br>',  #</div blkfigure>
                                    '</div><br><br>', sep=""), #</div figs_xxx>
                           fkey=paste(flink[idx2], collapse=","),
                           sex=paste(sxt[idx2], collapse=","), 
                           #body=paste(fig_dt[idx2,]$body, collapse=","), 
                           #keyword=NA_character_, 
                           #docn=0, #kcnt=gkeycnt,
                           fidx=paste0(idx2, collapse=",")) #min(idx2))
        insBlkId <- insBlkId[-1]
        
      } else {
        idx2 <- c()
      }
      if (rgtflush_flag & nrow(fig_dt[flushed==1L,])>0) { ## if not put fig in block, but in right side, each fig is a unique HTML quote by marginfigure
        idx1 <- which(fig_dt$flushed==1L)
        fdivx<- st_keep[xfig %in% fig_dt[idx1,]$fidx,]$xdiv
        nxtkx<- st_keep[xfig %in% fig_dt[idx1,]$fidx,]$xkey
        fig_nsp <- na.omit(st_keep[xfig %in% fig_dt[idx1, ]$fidx,]$nsp)[1]

        xf <- rbindlist(list(xf,rbindlist(mapply(function(x, idx, fdiv, nxtk, imgx, fnsp, sp, sex, #body, 
                                                          flink, outf, ckeyx, cfigx, fdupx, itx) {
          capx <- paste0("<em>",sp,"</em>, ",
                    ifelse(is.na(fcap[Fig==imgx,]$characters),"",fcap[Fig==imgx,]$characters),
                    ifelse(is.na(fcap[Fig==imgx,]$ext),"", paste0("<br>",fcap[Fig==imgx,]$citation, ", ", webCite)))
          fig_kstr <- gsub("<((\\/)*em|br)>", "", capx)
          fig_title <- paste0('Classification key: #<a href=', dQuote(paste0("#key_", ckeyx)),
                              '>', ckeyx, '</a> ', 
                              ifelse(!is.na(fnsp) && fnsp!='', 
                                paste0('for genus: <em>', fnsp, '</em>'),
                                paste0('(Next key: #<a href=', dQuote(paste0("#key_", nxtk)), '>', nxtk, '</a>)')))
          return(
          list(rid=itx, unikey=paste0(ukeyx, '_', fdiv),
               ckey=NA_integer_, subkey=NA_character_, pkey=NA_integer_,
               figs=cfigx,  type=2, nkey=NA_integer_, taxon=sp,
               keystr=fig_kstr,
               ctxt=paste(paste0('\n\n<div id=', dQuote(fdiv), 
                                 '><div class=', dQuote('blkfigure'),'>'),
                          paste0('<div class=', dQuote('fig_title'), '><span class=', dQuote('spmain'), '>',
                                 fig_title, '</span></div>'),
                          paste0('<span class=', dQuote('nfig'), '><a data-fancybox=', dQuote('gallery'), 
                                 ' class=', dQuote("fbox"), ' href=', 
                                 dQuote(paste0('#',flink)),'><img src=',
                                 dQuote(paste0('https://bio.odb.ntu.edu.tw/pub/copkey/gthumb/',outf)), 
                                 ' border=', dQuote('0'),
                                 ' alt=', dQuote(gsub("<((\\/)*em|br)>", "", capx)), 
                                 ' /></a><span id=', dQuote(flink), ' class=', dQuote('spcap'),
                                 '>Fig.',cfigx,'. ',capx,'</span></span></div><br><br></div><br><br>'), sep=""), ############ Only MARK duplicated imgf
                   fkey=flink, sex=sex, #body=body, keyword=NA_character_, 
                   fidx=idx)
          )
        }, x=ft[idx1], idx=idx1, fdiv=fdivx, nxtk=nxtkx, imgx=fig_dt[idx1, ]$imgf, fnsp=fig_nsp,
           sp=spt[idx1], sex=sxt[idx1], 
          # body=fig_dt[idx1,]$body, 
        flink=flink[idx1], outf=outf[idx1], 
           ckeyx=fig_dt[idx1,]$ckeyx, cfigx=fig_dt[idx1,]$fidx,  fdupx=fig_dt[idx1,]$fdup,
        MoreArgs = list(itx=i), SIMPLIFY = FALSE))), use.names = T)
      } else {
        idx1 <- c()
      }
      ##############################################################################
      gfk[fidx %in% fig_dt[idx1,]$fidx, flushed:=1L]  
      gfk[fidx %in% fig_dt[idx2,]$fidx, flushed:=2L]  
      setorder(xf, fidx)
     
      pgRemain = pageLine-(nrow(gtk)-(page-1L)*pageLine) ## How many rows remain for this page
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
  if (blkflush_flag & length(insRow)>0 & nrow(gtk)>1) {
    gtk <- rbindlist(list(gtk,data.table(rid=i, unikey=ukeyx, ckey=keyx, 
                                     subkey= letters[subkeyx], pkey= prekeyx,
                                     figs=paste0(figx, collapse=","),
                                     type=nxttype, nkey=nxtk, 
                                     taxon=ifelse(!is.na(nsp), nsp, paste(xsp, collapse=",")),
                                     keystr=toJSON(keyt),
                                     ctxt=xc, fkey=NA_character_, 
                                     sex=ifelse(all(is.na(sex)), NA_character_, paste(sex, collapse=","))
                                     #docn=0, kcnt=gkeycnt
                                     )),use.names = T) #, body=body, keyword=keyt)))
    #gkeycnt <- gkeycnt+1
    if (length(insRow)==0) {
      gtk <- rbindlist(list(gtk, xf), use.names = T) ## original old case
    } else {
      if (insRow[1]==1) {  ############# 20191014 modified
      #  gtk <- rbindlist(list(xf, gtk))
        gtk <- rbindlist(list(gtk, xf), use.names = T) ## original old case
      } else 
      if (insRow[1]>=nrow(gtk)) {
        print(paste0("Error: Insert Row: ", insRow[1], " is Larger than nrow(gtk): ", nrow(gtk), " in i: ", i))
        gtk <- rbindlist(list(gtk,xf), use.names = T)
      } else {
        gtk <- rbindlist(list(gtk[1:insRow[1],],xf,gtk[(insRow[1]+1L):nrow(gtk),]), use.names = T)
      }
      insRow <- insRow[-1]
    }
  } else {
    if (kflag) { ## if major key flag found, should place key ahead of image to end with </div>
      gtk <- rbindlist(list(gtk,
                            data.table(rid=i, unikey=ukeyx, ckey= keyx, 
                                       subkey= letters[subkeyx], pkey= prekeyx,
                                       figs=paste0(figx, collapse=","),
                                       type=nxttype, nkey=nxtk, 
                                       taxon=ifelse(!is.na(nsp), nsp, paste(xsp, collapse=",")),
                                       keystr=toJSON(keyt),
                                       ctxt=xc, fkey=NA_character_, 
                                       sex=ifelse(all(is.na(sex)), NA_character_, paste(sex, collapse=","))#,
                                       #body=body, keyword=keyt)#, xf
                                       #docn=0, kcnt=gkeycnt)
      )), use.names = T)
      #gkeycnt <- gkeycnt+1
      
      if (length(insRow)==0) {
        gtk <- rbindlist(list(gtk, xf), use.names = T) ## original old case
      } else {
        if (insRow[1]==1) {  ############# 20191014 modified
      #   gtk <- rbindlist(list(xf, gtk))
          gtk <- rbindlist(list(gtk, xf), use.names = T) ## original old case
        } else {
          if (insRow[1]>=nrow(gtk)) {
            #print(paste0("Error: Insert Row: ", insRow[1], " is Larger than nrow(gtk): ", nrow(gtk), " in i: ", i))
            gtk <- rbindlist(list(gtk,xf), use.names = T)
          } else {
            gtk <- rbindlist(list(gtk[1:insRow[1],],xf,gtk[(insRow[1]+1L):nrow(gtk),]), use.names = T)
          }
        }      
        insRow <- insRow[-1]
      }
    } else {
      gtk <- rbindlist(list(gtk,xf,
                            data.table(rid=i, unikey=ukeyx, ckey= keyx, 
                                       subkey= letters[subkeyx], pkey= prekeyx,
                                       figs=paste0(figx, collapse=","),
                                       type=nxttype, nkey=nxtk, 
                                       taxon=ifelse(!is.na(nsp), nsp, paste(xsp, collapse=",")),
                                       keystr=toJSON(keyt),
                                       ctxt=xc, fkey=NA_character_, 
                                       sex=ifelse(all(is.na(sex)), NA_character_, paste(sex, collapse=","))#,
                                       #body=body, keyword=keyt)
                                       #docn=0, kcnt=gkeycnt)
      )), use.names = T)
      #gkeycnt <- gkeycnt+1
    }
  }
    
  #fx <- gsub("^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$", "", x)
  #dx <- rbindlist(sapply(x, first_keyx, simplify = FALSE, USE.NAMES = TRUE))

################################# ## still plot, but mark it in this version #######
  if (any(!is.na(fidx_dup))) {
    print(paste0("Find dup... i: ", i))
    
#    do.call(function(fidx_dup,link_dup,gtk) {
#      dupx<-grep(paste0("fig_",fidx_dup), gtk$ctxt)
#      stopifnot(any(dupx))
#      gtk[dupx, ctxt:=gsub(paste0("fig_",fidx_dup), paste0("fig_",link_dup), ctxt)]
#    }, args=list(fidx_dup=fidx_dup, link_dup=link_dup, gtk=gtk)) 
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
      st_keep %<>% .[blkx>(gblk_cnt+1L),] ##if pret_case==1, and no consecutive blkfigs, nrow(st_keep) should 0
    }
    gblk_cnt <- gblk_cnt + 1L
  }
  if (st_conti_flag) st_conti_flag <- FALSE
  
  if (page<(1L+as.integer((nrow(gtk)-1)/pageLine))) {
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


cat(na.omit(gtk$ctxt), file="www/bak/web_tmp.txt")

## output source fig file
fwrite(gfk[!is.na(imgf), ] %>% .[,srcf:=imglst[imgf]] %>% .[,.(fidx, srcf)], file="www/bak/src_figfile_list.csv")

length(unique(na.omit(gtk$ckey))) #187
which(!1:187 %in% unique(na.omit(gtk$ckey)))

nrow(unique(gtk[!is.na(ckey)|!is.na(subkey),])) #391

length(unique(na.omit(gtk$taxon))) #203 (but some taxon nsp is xxx (aaa & bbb), still not subdivided 20180130)
