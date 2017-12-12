cd "$(dirname "$0")"
FOLDER="/home/play/.minecraft_1.12.2_mods/saves/azaza/opencomputers"

rm -R ./items/
mkdir items
for d in ${FOLDER}/*/home/ ; do
    ITEM_ID="$(basename "$(dirname "$d")")"
    cp -R "$d" "items/${ITEM_ID}"
done
