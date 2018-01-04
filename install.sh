MCDIR=~/.minecraft_1.12.2_mods
WORLD=engine

TARGETDIR="$(realpath $(dirname $0))/items"
BASEDIR=$MCDIR/saves/$WORLD/opencomputers

function okmark() {
    echo "$(tput setaf 2)✓$(tput sgr0) "
}

function failmark() {
    echo "$(tput setaf 1)✗$(tput sgr0) "
}

for D in $BASEDIR/* ; do
    if [[ $(basename $D) != "state" ]] ; then
        if [ -f $D/init.lua ] && [ -d $D/bin ] && [ -d $D/etc ] && [ -d $D/usr ] && [ -d $D/home ] ; then  # skip floppy disks
            D="$D/home"
            echo $D
            MUSTSYNC="no"
            if [ -L $D ] ; then
                echo "    $(failmark)Symlink found, skipping"
            elif [ -d $D ] ; then
                echo "    $(okmark)Directory found"
                MUSTSYNC="yes"
            elif [ ! -e $D ] ; then
                mkdir $D
                echo "    $(okmark)Directory doesn't exist, creating"
                MUSTSYNC="yes"
            else
                echo "    $(failmark)Unknown thing, skipping"
            fi
            if [[ $MUSTSYNC == "yes" ]] ; then
                rsync -av $TARGETDIR/ $D
            fi
        fi
    fi
done
