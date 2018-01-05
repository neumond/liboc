MCDIR=~/.minecraft_1.12.2_newmods
WORLD=engine

TARGETDIR="$(realpath $(dirname $0))/items"
BASEDIR=$MCDIR/saves/$WORLD/opencomputers

function okmark() {
    echo "$(tput setaf 2)✓$(tput sgr0) "
}

function failmark() {
    echo "$(tput setaf 1)✗$(tput sgr0) "
}

declare -a SYNCLIST

for D in $BASEDIR/* ; do
    BASED=$(basename $D)
    if [[ $BASED != "state" ]] ; then
        if [ -f $D/init.lua ] && [ -d $D/bin ] && [ -d $D/etc ] && [ -d $D/usr ] && [ -d $D/home ] ; then  # skip floppy disks
            if [[ "ALL" == $1 ]] || ( [ ! -z $1 ] && [[ ${BASED:0:${#1}} == $1 ]] ) ; then  # filters
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
                    SYNCLIST[${#SYNCLIST[*]}]=$D
                fi
            fi
        fi
    fi
done




echo "Found ${#SYNCLIST[*]} disks:"
for D in ${SYNCLIST[*]} ; do
    echo "  $(basename $(dirname $D))   $(du -hs $D | cut -f 1) / $(du -hs $(dirname $D) | cut -f 1)"
done

read -p "Are you sure? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] ; then
    for D in ${SYNCLIST[*]} ; do
        rsync -av $TARGETDIR/ $D
    done
fi
