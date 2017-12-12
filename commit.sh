cd "$(dirname "$0")"
FOLDER="/home/play/.minecraft_1.12.2_mods/saves/azaza/opencomputers/4ace2503-2838-4bc9-a6af-1119761b59b8"

rm -R ./items/
mkdir items
cp -R "${FOLDER}/." items/
