#!/bin/sh -e

topdir="$PROJECT_DIR/.."

dest="$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/couchbase-core"

clean_lib() {
    while read something
    do
        base=${something##*/}
        echo "Fixing $1 $something -> $dest/lib/$base"
        if [ -f "$dest/lib/$base" ]
        then
            :
        else
            if [ -f "$something" ]
            then
                cp "$something" "$dest/lib/$base"
            elif [ -f "/usr/local/lib/$base" ]
            then
                cp "/usr/local/lib/$base" "$dest/lib/$base"
            else
                echo "Can't resolve $base"
                exit 1
            fi
        fi
        chmod 755 "$dest/lib/$base"
        install_name_tool -change "$something" "lib/$base" "$1"
    done
}

# ns_server bits
rsync -a "$topdir/install/" "$dest/"
rm "$dest/bin/couchjs"
cp "$PROJECT_DIR/Couchbase Server/erl" "$dest/bin/erl"
cp "$PROJECT_DIR/Couchbase Server/couchjs.tpl" "$dest/bin/couchjs.tpl"
cp "$PROJECT_DIR/Couchbase Server/erl" "$dest/lib/erlang/bin/erl"
cp "$PROJECT_DIR/Couchbase Server/start-couchbase.sh" "$dest/../start-server.sh"
rm "$dest/etc/couchbase/static_config"
cp "$topdir/ns_server/etc/static_config.in" "$dest/etc/couchbase/static_config.in"

mkdir -p "$dest/priv" "$dest/logs" "$dest/config" "$dest/tmp"
cp "$topdir/ns_server/priv/init.sql" \
    "$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/init.sql"

cd "$dest"

# Fun with libraries
for f in bin/* lib/couchdb/bin/*
do
    fn="$dest/$f"
    otool -L "$fn" | egrep -v "^[/a-z]" | grep -v /usr/lib \
        | grep -v /System \
        | sed -e 's/(\(.*\))//g' | clean_lib "$fn"
done

# Fun with libraries
for i in 1 2
do
    for fn in `find * -name '*.dylib'` `find * -name '*.so'`
    do
        otool -L "$fn" | egrep -v "^[/a-z]" | grep -v /usr/lib \
            | grep -v /System \
            | sed -e 's/(\(.*\))//g' | clean_lib "$fn"
    done
done

cd "$topdir/install"
install_absolute_path=`pwd`
echo `pwd`

cd "$dest"
# fix cli paths
echo "fixing path for cb* commands"
echo "$install_absolute_path"
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/couchbase-cli
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbstats
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbflushctl
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbadm-online-restore
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbadm-online-update
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/docloader
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbadm-tap-registration
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbbackup
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbbackup-incremental
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbbackup-merge-incremental
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbdbconvert
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbdbmaint
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbdbupgrade
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbrestore
sed -ie "s,\$root/\`basename \$0\`,\"\`dirname \"\$0\"\`\/..\/lib/python\"\/\`basename \"\$0\"\`,g" bin/cbworkloadgen

