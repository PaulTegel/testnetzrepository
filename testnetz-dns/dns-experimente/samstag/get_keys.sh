#!/bin/bash

echo "Start der Generierung"
date
echo ""
dnssec-keygen -a RSASHA256 -b 1024 -n ZONE de

echo "ZSK key done"
echo ""
date
echo ""
echo ""
dnssec-keygen -a RSASHA256 -b 2048 -f KSK -n ZONE de
echo ""
echo "KSK key done"
echo ""
date

echo "Ende"









