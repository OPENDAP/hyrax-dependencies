#!/bin/bash

echo "###################################################################"
echo "#     proj_libdir: '$proj_libdir'"
echo "#     deps_libdir: '$deps_libdir'"
echo "# PKG_CONFIG_PATH: '$PKG_CONFIG_PATH'"
echo "#        CPPFLAGS: '$CPPFLAGS'"
echo "#         LDFLAGS: '$LDFLAGS'"
echo "#          OSTYPE: '$OSTYPE'"
echo "#"
pkg-config --list-all | awk '{print "## "$0; }' -
for dir in $proj_libdir; do
    echo "#"
    echo "# ls -l $dir "
    ls -l "$dir"
    if test -d "$dir/pkgconfig"; then
        echo "#"
        echo "# ls -l $dir/pkgconfig: "
        ls -l "$dir/pkgconfig"
    fi
    if test -f "$dir/pkgconfig/proj.pc"; then
        echo "#"
        echo "# awk '{print \"## \"\$0;}' $dir/pkgconfig/proj.pc: "
        awk '{print "## "$0;}' "$dir/pkgconfig/proj.pc"
    fi
done
echo "#"
echo "# pkg-config --exists proj"
pkg-config --exists proj
if test $? -eq 0; then echo "# pkg-config FOUND proj"; else echo "# pkg-config FAILED to find proj"; fi
echo "#"
echo "###################################################################"
