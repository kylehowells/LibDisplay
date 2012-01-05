#!/bin/bash

ARGS=$*

# Rename the files
cp ./Tweak.mm ./Tweak.xm
cp ./LibDisplay.h /opt/theos/include/libdisplay/libdisplay.h
cp ./obj/LibDisplay.dylib /opt/theos/lib/libdisplay.dylib
echo "Copied Tweak"

# Build
echo ""
echo "||---- Building..."
echo ""
make $ARGS
echo ""
echo "||---- Built!"
echo ""


# Rename the files
#rm ./Tweak.xm
#echo "Deleted Tweak.xm"


exit 0