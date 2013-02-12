#!/usr/bin/ksh

cd ~/reports/volspace

echo "d ALL^%FREECNT\n\n\nh\n" | csession prd > volspace.tmp

awk -f volspace.awk volspace.tmp > volspace.rpt

mail -s 'Epic Volume Space: '$(hostname) isdbunix@chw.org < volspace.rpt
