#!/usr/bin/env bash
set -euo pipefail

shadcn_files="$(find "${HOME}/.pub-cache/git" -maxdepth 4 -type f -path "*/shadcn_flutter-*/lib/shadcn_flutter.dart" 2>/dev/null || true)"
if [[ -z "${shadcn_files}" ]]; then
  exit 0
fi

while IFS= read -r shadcn_file; do
  [[ -z "${shadcn_file}" ]] && continue
  shadcn_dir="$(dirname "${shadcn_file}")"

  # Flutter 3.32 widgets.dart no longer re-exports Brightness; shadcn expects it.
  if grep -q "show Icons, MaterialPageRoute, MaterialPage, SliverAppBar, FlutterLogo;" "${shadcn_file}"; then
    sed -i "s/show Icons, MaterialPageRoute, MaterialPage, SliverAppBar, FlutterLogo;/show Icons, MaterialPageRoute, MaterialPage, SliverAppBar, FlutterLogo, Brightness;/" "${shadcn_file}"
  fi

  # vector_math 2.1.x doesn't have scaleByDouble/translateByDouble.
  find "${shadcn_dir}/src" -type f -name "*.dart" -print0 | xargs -0 perl -0777 -i -pe \
    's/translateByDouble\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/translate($1, $2, $3)/gs; s/scaleByDouble\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/scale($1, $2, $3)/gs;'
done <<< "${shadcn_files}"
