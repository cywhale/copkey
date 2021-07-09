library(officer)
library(odbapi)
library(data.table)
library(magrittr)
library(stringr)

options(useFancyQuotes = FALSE)
skipLine <- 23L
##############  #No need use dynamic pagination
figperLine<-6  #one figure is about 6 line text, to align in formats
wordLine <- 36 #(em) 1 line may contains 40 bytes, used to count page
pageLine <- 30 #in word docx, one page contains 55 line if 12 pt font used

#Mx -> Mx(p) #"Antenn(a|ule)", #Prosom(e|a)
termList <- data.table(name=c("A([1-9])?","(R|L)?P", "Mx(p)?", "Md", 
                              "Le(?:g|gs)", "Re", "Ri", "Head", "Crest",
                              "Rostrum", "Appendage","Antenn(?:a|ule)", "Pedigerous somites",
                              "Prosom(?:e|a)", "Urosome", "Urosomite", "Caudal ram(?:us|i)"),
                       prefix=c(0,1,1,1,2,1,1,3,3,3,3,3,3,3,3,3,3),
                       body = c(F,F,F,F,T,F,F,T,T,T,T,T,T,T,T,T,T))

imglst <- list.files("doc/img/", pattern="\\.jpg$",full.names = T)

dc0 <- read_docx("doc/New Version Key.docx")
ctent <- docx_summary(dc0)

#fc0 <- read_docx("doc/Table of key number.docx")
#ftent <- docx_summary(fc0) 
ftent <- fread("doc/Fig_key_tbl.csv", header = T)
##### Note manually edit doc/Table of key... -> Fig_key_tbl.csv for first column Fig. 8,9 to two rows

trimx <- function (x) {
  gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(x)))
}

########## find file name according to fig in key #####################
find_Figfilex <- function (figxt, ftent, imglst) {
  #require(odbapi)
  
  fdt <- rbindlist(lapply(figxt, function(x, dt, imglst) {
    idx <- match(as.character(x), dt$Fig)
    #if (any(!is.na(idx))) 
    #if have Remarks in mapping table, i.e. figs are in citations, not yet plotted, so is empty
    if (any(is.na(idx)) | trimx(dt[idx[[1]],]$Remarks)!="") {
      if (trimx(dt[idx[[1]],]$Remarks)!="") {
        print(paste0("No fig provided, only in REF: ", trimx(dt[idx[[1]],]$Remarks), "...in i: ", i))
      }
      return(list(fidx=idx, imgf=NA_integer_, 
                  sex=NA_character_, body=NA_character_, remark=trimx(dt[idx[[1]],]$Remarks)))
    }
    
    sp <- dt[idx[[1]],]$Taxon
    tt <- grep(gsub("\\s","_",sciname_simplify(gsub("\\(|\\)","",sp), simplify_two = TRUE)), imglst)
    
    #### too many fuzzy choices.. just use sex as a criteria to judge which file belong to this fig/key    
    tf <- grepl("^female|\\female", trimx(tolower(dt[idx[[1]],]$Characters)))
    tm <- grepl("^male|\\bmale", trimx(tolower(dt[idx[[1]],]$Characters)))
    sex<- ifelse(tf, "female", ifelse(tm, "male", NA_character_))
    
    #"\\b(P|A|Mx|Leg|leg|Re2)\\s{0,1}[0-9]{1,}((?:/|-)[0-9]{1,})?"
    bl <- regexpr(paste0('((^(',paste(tolower(termList[prefix==0,]$name),collapse="|"),')|\\b(',
                         paste(tolower(termList[prefix %in% c(1:2),]$name), collapse="|"),
                         '))\\s{0,}([0-9]{1,}|:)(\\s{0,}(?:/|-|&)\\s{0,}[0-9]{1,})?)|\\b(',
                         paste0(tolower(termList[prefix==3,]$name),collapse="|"),')(?:|\\s)'), 
                  tolower(dt[idx[[1]],]$Characters))
    if (bl>0 & attributes(bl)$match.length > 0) {
      body <- trimx(gsub(":","",gsub("P\\s","P",gsub("/","-",substr(dt[idx[[1]],]$Characters, bl, bl+attributes(bl)$match.length-1L)))))
    } else {
      body <- NA_character_
    }
    
    ### If duplicated figure, used latest version ###########
    vl <- regexpr("[0-9]+(.*?)_[a-zA-Z]", imglst[tt])
    vl[vl<0] <- 0
    vll <- attributes(vl)$match.length
    vll[vll<0] <- 0
    if (any(vl>0) & any(vll>0)) {
      xv <- tstrsplit(substr(imglst[tt],vl,vl+vll-2), "_")
      names(xv) <- c("date","vers")
      xv$date <- as.Date(xv$date, "%Y%m%d")
      xv$vers <- as.integer(xv$vers)
    } else {
      xv <- list(dat=rep(0L, length(tt)), vers=rep(0L, length(tt)))
    }
    
    chklatest <- function(dat, ver) {
      which.max(ver[dat %in% max(dat)])
    }
    
    if (all(is.na(tt))) return(list(fidx=idx, imgf=NA_integer_, 
                                    sex=sex, body=body, remark=NA_character_))
    
    if (any(!is.na(tt)) & length(tt)==1) {
      return(list(fidx=idx, imgf=tt, sex=sex, body=body, remark=NA_character_))
    }
    
    if (!is.na(body)) {
      if (nchar(body)==2 & substr(body,1,1) %in% c('P')) {
        btx <- paste0(body,'|',substr(body,1,1),'[0-9](.*?)(-|_){1,}',substr(body,2,2))
      } else {
        btx <- body
      }
      bt1<- grep(tolower(btx), tolower(imglst[tt]))
      if (!any(bt1)) {
        bdt <- sapply(termList$name, function(x,body) {grepl(x,body)},body=body, 
                      simplify = TRUE, USE.NAMES = FALSE)
        bt1 <- grep(tolower(paste(termList$name[bdt],collapse="|")), tolower(imglst[tt]))
      }
    } else {
      bt1<- integer()
    }
    
    if (!is.na(sex)) {
      if (sex=="female") { ## grep male also get results including "female"
        st1<- grep(sex, tolower(imglst[tt]))
      } else {
        st1<- grep("(\\s|\\b|\\_|\\-)?male", tolower(imglst[tt]))
      }
    } else {
      st1<- integer()
    }
    
    tt1 <- intersect(bt1, st1)
    
    if (any(tt1)) {
      if (length(tt1)>1) {
        tt2 <- chklatest(xv$date[tt1], xv$vers[tt1])
        return(list(fidx=idx, imgf=tt[tt1[tt2]], sex=sex, body=body, 
                    remark=paste(tt[tt1], collapse = ",")))
      } else {
        return(list(fidx=idx, imgf=tt[tt1], sex=sex, body=body, remark=NA_character_))
      }
    } else if (any(!is.na(bt1)) | any(!is.na(st1))) {
      if (any(!is.na(bt1))) {
        cat("Warning Img: Body match, but no sex match in figx: ", x, " sp: ",sp,"\n")
        
        tt2 <- chklatest(xv$date[bt1], xv$vers[bt1])
        return(list(fidx=idx, imgf=tt[bt1[tt2]], sex=sex, body=body, 
                    remark=paste(tt[bt1], collapse = ",")))
      }
      if (length(st1)==1) {
        return(list(fidx=idx, imgf=tt[st1], sex=sex, body=body, remark=paste(tt, collapse = ",")))
      }
      tt2 <- chklatest(xv$date[st1], xv$vers[st1])
      return(list(fidx=idx, imgf=tt[st1[tt2]], sex=sex, body=body, remark=paste(tt[st1], collapse = ",")))
      
    } else {
      tt1 <- chklatest(xv$date, xv$vers)
      return(list(fidx=idx, imgf=tt[tt1], sex=sex, body=body, remark=paste(tt, collapse = ",")))
    }
    #idx <- grep(paste(c(paste0("^",x,","),paste0(",",x,"$")), collapse="|"), dt$Fig)
    #if (any(idx)) return(idx[[1]])
  }, dt=ftent, imglst=imglst))

  return(fdt)  
}
###############################################################################################
tstL <- nrow(ctent)

#tstL <- 308L #key 90(89) #150L #(chk Fig63) #before 107L #key25 93L #key22 #79L #key18 #60L #Calanidae 65L Sinocalanus  #50L #fig.11

#page lcnt, fcnt No need use dynamic pagination, BUT, change to reset after every align with text and fig 20190126
lcnt <- 0L; fcnt <- 0L; page <- 1L #word count and line count (text:lcnt, fig:fcnt) 
insRow<-c()  ########### insert fig in right row of dtk
insBlkId<-c() ########## insert a block in HTML code
## indBlkcnt<-c()########## insert Nth block 
WaitFlush<- c(FALSE) ### Wait Next primary key and flush out stacked Number of figs (before that primary key)!!
blkflush_flag<- FALSE ## Now flush block of figs!!
blkcnt <- 0L; ########## blocks ID (how many times we flush out blocks of figs)
rgtflush_flag<- FALSE ## Flush figs in right-side column
keyx <- 0L; subkeyx <- 1L; padx = "pad1"
st_conti_flag <- FALSE; #line cutted by longer dots, and continue to next line
fig_conti_flag<- FALSE; #figs stacked in st_keep
st_keep <- data.table(xfig = integer(), xkey = integer(), blkx = integer(), case = integer())

dtk <- data.table(rid=integer(), ckey=integer(), 
             subkey=character(), pkey=integer(),
             figs=character(), type=integer(), nkey=integer(), 
             taxon=character(), ctxt=character(), fkey=character(),
             sex=character(), body=character(), keyword=character()) #, page=integer())

#### Used to store figs <-> fig_file mapping
dfk <- data.table(fidx=integer(), imgf=integer(), sex=character(), 
                  body=character(), remark=character(), fdup=character(), # the imgf had been used (diff figx, use the same imgf)
                  flushed=integer(), ckeyx=integer(), ## flushed means if flushed to ctxt already (1, otherwise 0)
                  case=integer(), blkx=integer()) ### case: blkfigure or not; blkx: counter of block of fig flushed into block
i = skipLine+1L
pret <- ""; prekeyx <- 0L

while (i<=tstL) { #nrow(ctent)) {

  x <- gsub("^\\s+|\\s+$", "", gsub("\\s{1,}", " ", as.character(ctent$text[i])))
  
  tt <- which(is.na(x) | x=="")
  if (any(tt)) {
    #    x <- x[-tt]
    #    flagKeyBrk <- TRUE
    # subkeyx <- 1L
    i <- i+1;
    next  
  }
  
  #if (i==skipLine+1L) {pret <- paste0('<p id=',dQuote(paste0("p",page)),'></p>')}
  
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
      pret <- paste0(pret,'<br><p class=leader><span class=',dQuote('keycol'),'>',
                     '<mark id=', dQuote(paste0('key_', keyx)), '>', keyx, '</mark> ')
      stcnt<- nchar(pret)+1L #move pointer to next start in a statment
      x1<- substr(x,wl+attributes(wl)$match.length-1L, nchar(x))
      xc<- paste0(pret,x1) #HTML results
      kflag <- TRUE #primary key found
      prekeyx <- 0L #if primary key not found, no update for prekeyx
      subkeyx <- 1L
    } else {
      xc<- x1
      subkeyx <- subkeyx + 1L
    }
    
    ## detect pre key, such as "2(1) Head..."
    wl0s <- regexpr("^\\((?:[0-9]{1,})\\)",x1)
    if (attributes(wl0s)$match.length>0) {
      cat("Detect prekey in i: ", i, "\n") 
      prekeyx <- as.integer(substr(x1,2L, attributes(wl0s)$match.length-1L)) 
      stopifnot(!any(is.na(prekeyx)))
      
      pret0s <- paste0('([', prekeyx, '](#key_', prekeyx, '))&nbsp;')
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
  #wl1<- regexpr("(?:^[a-zA-Z]{1,}(.*?)fig{1}(.*?))[0-9]",x1)
  #wl2<- regexpr("(?:^[a-zA-Z]{1,}(.*?)fig{1}(.*?))(?:\\))",x1)
  wl1 <- regexpr("\\(*(f|F)ig{1}(s)*(\\.|\\s)*",x1t) ## fig. figs. w/o space + Number(fig id, 1-3 digits)
  #wl1<- regexpr("(?:((f|F)ig{1}(.*?)))[0-9]+",x1)
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
    tt <- substr(x1t,wl1+attributes(wl1)$match.length, wl2+attributes(wl2)$match.length-2L)
    if (grepl('-',tt)) {
      figt <- tstrsplit(tt,"-") %>% unlist(use.names = F) %>% trimx() %>% as.integer() 
      figt <- seq(figt[1], figt[length(figt)])
      pret_case <- 1L ## different HTML code for (fig. 35-37) (it means figs 35,36,37)
    } else {
      figt <- tstrsplit(gsub("\\.|\\s","",tt), ",") %>% unlist(use.names = F) %>% trimx() %>% as.integer()
      pret_case <- 0L #default: it's for (fig. 35,36)
    }
    stopifnot(all(!is.na(figt)))
    
    if (all(!is.na(figx))) {
      figx <- c(figx, figt)
      #stcnt<- stcnt+nchar(as.character(figt[1]))
    } else {
      figx <- figt
    }
    
    if (pret_case == 1L) {
      pret<- paste0('[',tt,'](#figblk_',tt,')')
      insBlkId <- c(insBlkId, paste0('figblk_',tt))
#      if (length(insBlkcnt)==0) {
#        insBlkcnt <- c(blkcnt+1L)
#      } else {
#        insBlkcnt <- c(insBlkcnt, max(insBlkcnt)+1L)
#      }
    } else {
      pret<- do.call(function(x) {paste0('[',x,'](#figx_',x,')')}, list(figt)) %>%
        paste(collapse=", ")
    } 
    
    #x2<-substr(x1t,attributes(wl2)$match.length+1L, nchar(x1t))
    x2<- substr(x1t,wl2+attributes(wl2)$match.length, nchar(x1t))
    #xc<-paste0(substr(xc,1L,stcnt+attributes(wl1)$match.length-2L),
    #           pret, substr(xc,stcnt+attributes(wl2)$match.length,nchar(xc)))
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
    #wl3<- regexpr("(?:…+\\s*|\\.+\\s*)[a-zA-Z]+\\s*[\\(a-zA-Z]+\\s{0,1}(♀|♂|\\))*\\s{0,1}$",x2)
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
  wl4 <- regexpr("^\\s{0,}\\([A-Z][a-z]+(.*?)\\)\\s{0,}(?:…{1,}\\s{0,}|\\.{1,}\\s{0,})",x2)
  if (wl4>0 & attributes(wl4)$match.length>0) {
    xsp <- trimx(gsub("\\(|\\)|\\.|…","",substr(x2,wl4,wl4+attributes(wl4)$match.length-1L))) #%>%
      #tstrsplit("&") %>% unlist(use.names = F)
    
    print(paste0("Find annotated species: ", paste(xsp, collapse=","), " in i: ", i))
    
    wl4t <- regexpr(xsp,xc)
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
      ifelse(substr(x, nchar(x)-1L, nchar(x))=="ae", '**', '*')
    }, simplify = TRUE, USE.NAMES = FALSE)
    
    pret<- do.call(function(x, pres, sex) {paste0('<mark id=',dQuote(paste0(ifelse(is.na(sex),'taxon_', paste0(sex,'_')), 
                                                   gsub("\\s","_",x))),
                                             '>', pres, x, pres, ifelse(is.na(sex),"",ifelse(sex=="female","♀","♂")),
                                             '</mark>')}, 
                   list(x=xspx, pres=pret0s, sex=xsex)) %>% paste(collapse=" & ")

    tt <- substr(x2, wl4, nchar(x2))
    wl4t <- regexpr(")",tt)
    
    xc <- paste0(substr(xc,1L,nchar(xc)-nchar(x2)+2L), pret,
                 substr(tt,wl4t+attributes(wl4t)$match.length-1L, nchar(tt)))
    xsp<- xspx
  }
  
  xc<-paste0(gsub("…|\\.{2,}|…\\.{1,}|\\.{1,}…","",ifelse(st_conti_flag, xc, substr(xc,1,nchar(xc)-stt))),
            '</span><span class=',dQuote('keycol'),'>',
            ifelse(nxttype==0L, paste0('[', nxtk, '](#key_',nxtk,')'), 
                   paste0('<mark id=', 
                   dQuote(paste0(ifelse(all(is.na(xsex)),'taxon_',paste0(xsex,"_")),paste(unlist(tstrsplit(nsp,'\\s')),collapse='_'))), '>*', nsp, '*</mark>')),
            ifelse(all(is.na(xsex)),"",ifelse(xsex=="female","♀","♂")),'</span></p>')

  if (!kflag) {
    if (keyx>=100 & prekeyx>=100) {
      padx = "pad8"
    } else if ((keyx>=100 & prekeyx>=10) | prekeyx>=100) {
      padx = "pad7"
    } else if ((keyx>=100 & prekeyx>0) | (keyx>=10 & prekeyx>=10)) {
      padx = "pad6"
    } else if ((keyx>=10 & prekeyx>0) | prekeyx>=10) {
      padx = "pad5"
    } else if (prekeyx > 0) {
      padx = "pad4"
    } else if (keyx>=100 & prekeyx==0) {
      padx = "pad3"
    } else if (keyx>=10 & prekeyx==0) {
      padx = "pad2"
    } else {
      padx = "pad1"
    }
    xc <- paste0('<p class=leader><span class=', #ifelse(prekeyx>0, dQuote('keycol pad4'), dQuote('keycol pad1')), 
                 dQuote(paste0('keycol ', padx)), '>', xc)
                 #paste(rep("&nbsp;",ifelse(prekeyx>0, 9L, 3L)),collapse=""), xc)
  }
  
  if (kflag & !st_conti_flag & WaitFlush) {
    blkflush_flag <- TRUE
    insRow[1] <- nrow(dtk) ## update insert Row number just before current key (still not in dtk)
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
  
   if (!any(is.na(figx)) & (pret_case!=0L | fig_conti_flag |## WaitFlush will hold-on fig-flush
                            ((all(!WaitFlush) | (length(WaitFlush)==1 & WaitFlush[1] & blkflush_flag)) & ## Case 2a
                             ((fcnt*figperLine+2L) >= lcnt_pre)))) {
     if (pret_case!=0L & (WaitFlush[1] | fig_conti_flag) & any(st_keep$case==0L)) {
       print(paste0("Warning: Flush piped fig in right-column, check them in i: ",i, " with figs: ",
             paste(st_keep[case==0L,]$xfig, collapse=",")))
       #fblk_flag <- FALSE
       fig_conti_flag <- FALSE
       WaitFlush[1] <- FALSE
       rgtflush_flag<- TRUE ### Case 4: flush figs in right-side column!
       dfk[fidx %in% st_keep[case==0L,]$xfig, blkx:=0L]
     }
     if (!WaitFlush[1]) {
       tt <- nrow(st_keep) + length(figx)
       st_keep <- rbindlist(list(st_keep, 
                                 data.table(xfig=figx, xkey=nxtk, blkx=blkcnt+1L, case=pret_case)))
       if (tt %% 2 == 0L | tt %% 3 == 0L | pret_case!=0L) { #### Case 1: pret_case!=0L; & Case 3
         figx <- sort(unique(na.omit(c(st_keep$xfig,figx))))  ## flush out figs link that kept in st_keep 
         fig_conti_flag <- FALSE
         WaitFlush[1] <- TRUE
         insRow <- c(insRow, nrow(dtk)+1L)
       } else { ############################## Case 3 pipe
         print(paste0("... Piping figs in st_keep in i: ",i, " with figs: ",
                      paste(figx, collapse=",")))
         fig_conti_flag <- TRUE
       }
       #fblk_flag <- TRUE
     } else { #if (WaitFlush[1] & pret_case!=0L & !rgtflush_flag) { #### Case 2, 2a pipe
       print(paste0("Warning: 2-nd block comes and pipe fig in st_keep in i: ",i, " with figs: ",
                    paste(figx, collapse=",")))
       st_keep <- rbindlist(list(st_keep, 
                                 data.table(xfig=figx, xkey=nxtk, blkx=max(st_keep$blkx)+1L, case=pret_case)))
       if (pret_case!=0L | length(figx) %% 2 == 0L | length(figx) %% 3 == 0L) {
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
                   sex=character(), body=character(), keyword=character()) 
  
#### plot immediately, Output Fig HTML code  
  if ((rgtflush_flag | blkflush_flag) & any(dfk[!is.na(imgf),]$flushed==0L)) { 

    fig_dt <- dfk[FALSE,]
    if (rgtflush_flag) {
      if (nrow(dfk[!is.na(imgf) & flushed==0L & case==0L & blkx==0L,])>0) {
        fig_dt <- dfk[!is.na(imgf) & flushed==0L & case==0L & blkx==0L,]
        fig_dt[,flushed:=1L]
      } else {
        rgtflush_flag <- FALSE ##it means figxt!=figx, duplicated figx (had been outputted) is used in previous statement
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
      outf<-gsub("(P[0-9]+)_([0-9])","\\1-\\2",
              gsub("-f","_f", gsub("-m","_m",   ## -female, -male to _female _male in file names
              gsub("_\\.","\\.",gsub("^\\s{1,}|^_{1,}|\\s+$|_+$","",
              gsub("_{1,}|[^P0-9a-zA-Z]-{1,}","_",gsub("\\s{1,}|&","_",
              gsub("\\(|\\)|\\;|[^PAMx_\\-][0-9]{1,}|[0-9]{0,}\\.[0-9]{1,}mm|doc/img/","",
              gsub("♀|Female","female",gsub("♂|Male","male",fn))))))))), perl=TRUE)  
      flink <- paste0("figx_", fig_dt$fidx) #figx) 
      
      for (j in seq_along(outf)) {
        if (!file.exists(paste0("www/img/",outf[j]))) {
          cat("copy file from img: ", outf[j])
          system(enc2utf8(paste0("cmd.exe /c copy ", gsub("/","\\\\",paste0("D:/R/copkey/",fn[j])), 
                                 " ",gsub("/","\\\\",paste0("D:/R/copkey/www/img/",outf[j])))))
        }
      }
      
      ft <- sapply(outf, function(outf) {paste(unlist(tstrsplit(gsub("\\.jpg|\\(|\\)","",outf),"_|-")), collapse=" ")},
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
        sxt<- ""
      }
      #################### Output Fig HTML code ####################################################
      if (blkflush_flag & rgtflush_flag & fig_dt[flushed==2L,]$case[1]==0L) { 
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
          insBlkId <- c(paste0("figx_",paste(c(fig_dt[idx2,]$fidx[1],fig_dt[idx2,]$fidx[length(idx2)]), collapse="-")))
        }
        if (length(idx2) %% 3 == 0) {
          spanx <- 'ntrd' ### narrow span
        } else { ############ otherwise, 2 figs in a line, use wider span
          spanx <- 'ntwo'
        }
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
                         body=paste(fig_dt[idx2,]$body, collapse=","), keyword=NA_character_)
        insBlkId <- insBlkId[-1]
      } else {
        idx2 <- c()
      }
      if (rgtflush_flag & nrow(fig_dt[flushed==1L,])>0) { ## if not put fig in block, but in right side, each fig is a unique HTML quote by marginfigure
        idx1 <- which(fig_dt$flushed==1L)
        xf <- rbindlist(list(xf,rbindlist(mapply(function(x, sp, sex, body, flink, outf, ckeyx, cfigx, fdupx, itx) {
          list(rid=itx, ckey=NA_integer_, subkey=NA_character_, pkey=NA_integer_,
               figs=cfigx,  type=NA_integer_, nkey=NA_integer_, taxon=sp,
               ctxt=paste('\n\n```{marginfigure}', 
                          paste0('<a class=', dQuote("fbox"), ' href=', dQuote(paste0('img/',outf)),'><img src=',
                                 dQuote(paste0('img/',outf)), ' border=', dQuote('0'),
                                 ' /></a><span id=', dQuote(flink), ' class=', dQuote('spnote'),
                                 '>Fig.',cfigx,' *',sp,'* ',sex,' [&#9754;](#key_',ckeyx,') &nbsp;',
                                 fdupx,'</span>'),'```\n\n', sep="\n"), ############ Only MARK duplicated imgf
               fkey=flink, sex=sex, body=body, keyword=NA_character_)
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

  if (blkflush_flag & length(insRow)>0 & nrow(dtk)>1) {
    dtk <- rbindlist(list(dtk,data.table(rid=i, ckey= keyx, 
                                     subkey= letters[subkeyx], pkey= prekeyx,
                                     figs=paste0(figx, collapse=","),
                                     type=nxttype, nkey=nxtk, 
                                     taxon=ifelse(!is.na(nsp), nsp, paste(xsp, collapse=",")),
                                     ctxt=xc, fkey=NA_character_, 
                                     sex=ifelse(all(is.na(sex)), NA_character_, paste(sex, collapse=",")),
                                     body=body, keyword=keyt)))
    if (insRow[1]>=nrow(dtk)) {
      print(paste0("Error: Insert Row: ", insRow[1], " is Larger than nrow(dtk): ", nrow(dtk), " in i: ", i))
      dtk <- rbindlist(list(dtk,xf))
    } else {
      dtk <- rbindlist(list(dtk[1:insRow[1],],xf,dtk[(insRow[1]+1L):nrow(dtk),]))
    }
    insRow <- insRow[-1]
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
    
  #fx <- gsub("^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$", "", x)
  #dx <- rbindlist(sapply(x, first_keyx, simplify = FALSE, USE.NAMES = TRUE))

################################# ## still plot, but mark it in this version #######
  if (any(!is.na(fidx_dup))) {
    print(paste0("Find dup... i: ", i))
    
#    do.call(function(fidx_dup,link_dup,dtk) {
#      dupx<-grep(paste0("figx_",fidx_dup), dtk$ctxt)
#      stopifnot(any(dupx))
#      dtk[dupx, ctxt:=gsub(paste0("figx_",fidx_dup), paste0("figx_",link_dup), ctxt)]
#    }, args=list(fidx_dup=fidx_dup, link_dup=link_dup, dtk=dtk)) 
  }
################################# 
  pret <- ""
  if (rgtflush_flag) { rgtflush_flag <- FALSE }
  if (blkflush_flag) {
    blkflush_flag <- FALSE
    #fblk_flag <- FALSE
    if (length(WaitFlush)>1) {
      WaitFlush %<>% .[-1]
    } else {
      WaitFlush[1] <- FALSE 
    }
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


cat(na.omit(dtk$ctxt), file="www/bak/web_tmp.txt")

## output source fig file
fwrite(dfk[!is.na(imgf), ] %>% .[,srcf:=imglst[imgf]] %>% .[,.(fidx, srcf)], file="www/bak/src_figfile_list.csv")

length(unique(na.omit(dtk$ckey))) #187
which(!1:187 %in% unique(na.omit(dtk$ckey)))

nrow(unique(dtk[!is.na(ckey)|!is.na(subkey),])) #391

length(unique(na.omit(dtk$taxon))) #203 (but some taxon nsp is xxx (aaa & bbb), still not subdivided 20180130)
