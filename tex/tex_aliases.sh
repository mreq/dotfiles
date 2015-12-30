# Counts words in a pdf file
countpdfwords() {
  pdftotext "$1" - | tr -d '.' | wc -w
}
