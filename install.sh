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
            D="$D/home/liboc"
            echo $D
            MUSTSYMLINK="no"
            if [ -L $D ] ; then
                if [[ $(readlink $D) == $TARGETDIR ]] ; then
                    echo "    $(okmark)Already a symlink, proper target set, skipping"
                else
                    echo "    $(failmark)Already a symlink, bad target: $(readlink $D), skipping"
                fi
            elif [ -d $D ] ; then
                if [ -z "$(ls -A $D)" ] ; then  # empty dir
                    echo "    $(okmark)Empty directory found, symlinking"
                    rmdir $D
                    MUSTSYMLINK="yes"
                else
                    echo "    $(failmark)Directory is not empty, skipping"
                    ls -A $D
                fi
            elif [ ! -e $D ] ; then
                echo "    $(okmark)Directory doesn't exist, symlinking"
                MUSTSYMLINK="yes"
            else
                echo "    $(failmark)Unknown thing, skipping"
            fi
            if [[ $MUSTSYMLINK == "yes" ]] ; then
                ln -s $TARGETDIR $D
            fi
        fi
    fi
done
