#!/usr/bin/env bash
# CurseForge upload for auxForever (project 1727417), used by the Release workflow.
#   curseforge.sh check                    lists what CurseForge knows about Forever's game version
#   curseforge.sh upload <zip> <notes.md>  uploads the zip as a Beta file with those notes
# Needs the repository secret CF_API_KEY (a CurseForge API token, account settings, API Tokens).
# API: https://wow.curseforge.com/api (game/versions, projects/<id>/upload-file, header X-Api-Token).
set -euo pipefail

API=https://wow.curseforge.com/api
PROJECT_ID=${CF_PROJECT_ID:-1727417}

if [ -z "${CF_API_KEY:-}" ]; then
  echo "The CF_API_KEY secret is not set (GitHub: Settings, Secrets and variables, Actions)."
  exit 1
fi

# The game version name from the TOC's Interface number: 16001 is 1.60.1
interface=$(sed -n 's/^## Interface: *\([0-9]*\).*/\1/p' auxForever/auxForever.toc | tr -d '\r' | head -n 1)
game_version="$((interface / 10000)).$(((interface % 10000) / 100)).$((interface % 100))"
echo "auxForever.toc Interface $interface, game version $game_version"

versions=$(curl -sS --fail-with-body -H "X-Api-Token: $CF_API_KEY" "$API/game/versions")
types=$(curl -sS --fail-with-body -H "X-Api-Token: $CF_API_KEY" "$API/game/version-types")

# the id of the version named like the TOC's game version; several types can share a name, so a
# type whose name or slug mentions Forever is preferred
version_id=$(jq -r --arg v "$game_version" --argjson types "$types" '
  [ .[] | select(.name == $v) | . as $g
    | ($types[] | select(.id == $g.gameVersionTypeID)) as $t
    | {id: $g.id, forever: (($t.name + " " + $t.slug) | ascii_downcase | test("forever"))} ]
  | (map(select(.forever)) + .) | first | .id // empty' <<<"$versions")

case "${1:-}" in
  check)
    echo
    echo "Game version types:"
    jq -r '.[] | "  \(.id)  \(.name)  (\(.slug))"' <<<"$types"
    echo
    echo "Game versions named $game_version, or whose type mentions Forever:"
    jq -r --arg v "$game_version" --argjson types "$types" '
      .[] | . as $g | ($types[] | select(.id == $g.gameVersionTypeID)) as $t
      | select(.name == $v or (($t.name + " " + $t.slug) | ascii_downcase | test("forever")))
      | "  id \(.id)  name \(.name)  type \($t.name)"' <<<"$versions"
    echo
    if [ -n "$version_id" ]; then
      echo "Uploads would use game version id $version_id."
    else
      echo "No CurseForge game version is named $game_version: uploads would fail."
      exit 1
    fi
    ;;
  upload)
    zip=$2
    notes=$3
    if [ -z "$version_id" ]; then
      echo "No CurseForge game version is named $game_version. Run the CurseForge check workflow to see the list."
      exit 1
    fi
    version=$(sed -n 's/^## Version: forever-//p' auxForever/auxForever.toc | tr -d '\r')
    metadata=$(jq -n --rawfile changelog "$notes" --arg name "auxForever $version" --argjson gv "$version_id" \
      '{changelog: $changelog, changelogType: "markdown", displayName: $name, gameVersions: [$gv], releaseType: "beta"}')
    echo "Uploading $zip to CurseForge project $PROJECT_ID as 'auxForever $version' (beta, game version id $version_id)"
    curl -sS --fail-with-body -H "X-Api-Token: $CF_API_KEY" \
      -F "metadata=$metadata" -F "file=@$zip" "$API/projects/$PROJECT_ID/upload-file"
    echo
    echo "Uploaded."
    ;;
  *)
    echo "usage: curseforge.sh check | upload <zip> <notes.md>"
    exit 1
    ;;
esac
