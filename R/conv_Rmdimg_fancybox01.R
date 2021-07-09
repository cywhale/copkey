## convert img file in Rmd files to fancybox html format
library(data.table)
library(magrittr)
#library(odbapi)

#skipLine <- 20L ## first row is column that make some following fail, just print and skip it.
dirx <- "D:/R/copkey/copkey_book/"
out_dirx <- paste0("D:/R/copkey/versions/", as.character(Sys.Date()),"/")
dir.create(file.path("D:/R/copkey/versions", as.character(Sys.Date())), showWarnings = TRUE)
rmd_files <- c("index.Rmd",
            "introduction.Rmd",
            "morphology-of-the-calanoida.Rmd",
            "taxonomy-of-calanoida.Rmd",
            "distribution.Rmd",
            "list-of-species-known-to-occur-in-the-china-seas.Rmd",
            "references.Rmd")

fig_prex <- "text-fig."
fbox_str1<- '<a class=\"fbox\" href=\"img/text-fig' #001.jpg
fbox_str2<- '.jpg\" data-alt=\"\" />' #text-fig. 1
fbox_ends<- '</a>'

fbox_strfx <- function(x, str1='<a class=\"fbox\" href=\"img/text-fig', 
                       str2='.jpg\" data-alt=\"\" />',
                       ends='</a>', fig_prex="text-fig.") {
  return(paste0(str1, x, str2, fig_prex, " ", paste0(as.integer(x)), ends))
}

fbox_gsubx <- function(strx, patx, repl) {
  for (i in seq_along(patx)) {
    strx <- gsub(patx[i], repl[i], strx, perl=TRUE)
  }
  return(strx)
}

writelinex <- function(str, file, append=TRUE) {
  try(write(str, file=file, append=append), silent=TRUE)
  return (TRUE) ## return a flag to make sure the file have been written at least once
}

for (ft in seq_along(rmd_files)) {
  ftx <- paste0(dirx, rmd_files[ft])
  if (!file.exists(ftx)) {
#    file.copy(from=ftx, to=bak_dirx, 
#             overwrite = TRUE, recursive = FALSE, copy.mode = TRUE)
#  } else {
    next
  }
  dc0 <- readLines(paste0(dirx, rmd_files[ft]))
  file<- paste0(out_dirx, rmd_files[ft])
  first_flag <- TRUE
  
  for(i in seq_along(dc0)) {
    if (grepl(fig_prex, dc0[i])) {
      
      #wl1 <- gregexpr(fig_prex, dc0[i])
      #gregexpr("(?<=text-fig).\\s{0,}[0-9]+", dc0[i], perl=TRUE)
      #del_patx <- paste0("(?<=", fig_prex, ")(\\s{0,}[0-9]+)\\s{0,}=\\s{0,}fig.\\s{0,}[0-9]+")
      del_patx <- paste0("=\\s{0,}fig.\\s{0,}[0-9]+")
      wlx <- gregexpr(del_patx, dc0[i], perl=TRUE)
      
      if (any(wlx[[1]]>0)) {
        dcx <- gsub(del_patx, "", dc0[i])
      } else {
        dcx <- dc0[i]
      }
      
      img_patx <- paste0("(?<=", fig_prex, ")\\s{0,}[0-9]+")
      img_numx <- as.integer(unlist(regmatches(dcx, gregexpr(img_patx, dcx, perl=TRUE)),use.names = FALSE))

      img_nums <- vector("character", length=length(img_numx))
      img_nums[img_numx<10] <- paste0("00", img_numx[img_numx<10])
      img_nums[img_numx>=10 & img_numx<100] <- paste0("0", img_numx[img_numx>=10 & img_numx<100])
      img_nums[img_numx>=100] <- paste0(img_numx[img_numx>=100])
      
      img_strx <- sapply(img_nums, fbox_strfx, simplify = TRUE, USE.NAMES = FALSE)
      
      patx <- unlist(regmatches(dcx, gregexpr(paste0(fig_prex, "\\s{0,}[0-9]+"), dcx, perl=TRUE)),use.names = FALSE)
      if (length(patx)!=length(img_strx)) {
        print(paste0("Warning: in file ", ftx, " at lines: ", i, ". NOT MATCH in img pattern length."))
        dct <- dcx
      } else {
        dct <- fbox_gsubx(strx=dcx, patx=patx, repl=img_strx)
      }
      first_flag <- !(writelinex(dct,file=file,append=!first_flag))
    } else {
      first_flag <- !(writelinex(dc0[i],file=file,append=!first_flag))
    }  
  }
}






