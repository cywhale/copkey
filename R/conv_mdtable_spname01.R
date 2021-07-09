## convert spname to italic from md coverted from google docs script, which lost format in tablecell.
library(data.table)
library(magrittr)
library(odbapi)

skipLine <- 20L ## first row is column that make some following fail, just print and skip it.

dc0 <- readLines("doc/Table - MARINE CALANOID COPEPODS OF CHINA SEA.md", encoding = "Latin-1")
## for the character <e2><99>\u0080size mm ♀size ♂

writelinex <- function(str, file, append=TRUE) {
  try(write(str, file=file, append=append), silent=TRUE)
}

for(i in seq_along(dc0)) {
  if (grepl("<table>",dc0[i])) {
    writelinex("<br><table>",file="doc/output_tbl.md",append=TRUE)
    next
  }
  if (grepl("</table>",dc0[i])) {
    writelinex("<table><br>",file="doc/output_tbl.md",append=TRUE)
    next
  }
  
  if (i<= skipLine | !grepl("<td>",dc0[i])) {
    writelinex(dc0[i],file="doc/output_tbl.md",append=TRUE)
    next
  }
  
  wl <- regexpr(">",dc0[i])
  el <- regexpr("</",dc0[i])
  if (wl<0 | el<0) {
    writelinex(dc0[i],file="doc/output_tbl.md",append=TRUE)
    next
  }
  
  tc1 <- try(substr(dc0[i], wl+1, el-1), silent = TRUE)
  if (class(tc1)=="try-error") {
    writelinex(dc0[i],file="doc/output_tbl.md",append=TRUE)
    next
  }
  
  len <- lengths(gregexpr("\\W+", tc1))
  if (grepl("^[0-9]+", tc1) | len<=1) {
    writelinex(dc0[i],file="doc/output_tbl.md",append=TRUE)
    next
  }
  
  sp1 <- sciname_simplify(tc1, simplify_one = TRUE)  
  sp2 <- sciname_simplify(tc1, get_second = TRUE)
  
  if (grepl("\\,", sp1) | grepl("\\,", sp2) | nchar(sp1)<=2 | nchar(sp2)<=2) {
    writelinex(dc0[i],file="doc/output_tbl.md",append=TRUE)
    next
  }

  wl1 <- regexpr(sp1, tc1)
  wl2 <- regexpr(sp2, tc1)
 
  if ((wl1+attributes(wl1)$match.length+1) != wl2) {
    spa <- substr(tc1, wl1+attributes(wl1)$match.length+1, wl2-2)
    if (!grepl("^\\(", spa) | !grepl("\\)$", spa)) {
      print(paste0("Wanring: check spname format in i: ", i, "; spname: ", tc1))
    }
    spb <- paste0("(*",substr(spa,2,nchar(spa)-1),"*)")
  } else {
    spb <- ""
  }
  
  spn <- paste0("*", sp1, "* ", spb, ifelse(spb=="", "*", " *"), sp2,"*")
  
  if (nchar(tc1) > wl2+attributes(wl2)$match.length) {
    spt <- substr(tc1, wl2+attributes(wl2)$match.length, nchar(tc1))
  } else {
    spt <- " " #one word spacing
  }
  out <- paste0(substr(dc0[i],1,wl), spn, spt, substr(dc0[i], el, nchar(dc0[i]))) 
  writelinex(out,file="doc/output_tbl.md",append=TRUE)
}



