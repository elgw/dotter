# Count the number of nuclei and dots
# From a csv file where column 
# 6 is the nuclei number
# and column 7 is the field number
#
# Usage:
# awk -f df_1.awk file.csv

BEGIN {
  FS="," # field separator
  }
{
#  print "f" $7  "n"  $6
  if (NR > 1) 
    F["f" $7 "n" $6]++
} 
END {
  for(a in F) {
    print a ", " F[a]
    dots+=F[a]
    nuclei++ }
}
