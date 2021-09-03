
for f in *.docx; do mv "$f" "$(echo "$f" | sed s/Key\\sto\\sthe\\sspecies\\sof\\s//)"; done
rename 's/\s/_/g' *.docx
for f in *.docx; do mv "$f" "$(echo "$f" | sed s/_\(.*\)//)"; done
for f in *.docx; do mv "$f" "$(echo "$f" | sed s/docx/zip/)"; done

#if just want remove () and reserve words within ()
rename 's/[(\)]//g' *.docx
