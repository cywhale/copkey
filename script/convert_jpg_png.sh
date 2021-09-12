#!/bin/bash
## for copkey, transform all jpg(note may have jpeg) to png by imageMagick ## 120999 -> 47633 size compression
mogrify -colorspace gray -auto-level -define png:compression-level=9 -define png:format=8 -define png:include-chunk=none -define png:color_type=4 -depth 4 -quality 70 -format png *.jpg

