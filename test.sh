#!/bin/sh
CHANGED_FILES=$(git diff 7901137c1edf74d3f8c7c9fe1081e87cf29a4af2...30cfbab1672419d9f9d8dc123a5da07eb11eb0e9 --name-only)
# Construct the package and os into a json string to be consumed by Github Actions runners
JSON="{\"include\":["
for FILE in $CHANGED_FILES; do
  if [[ $FILE == package_build_list_host_* ]]; then
    PLATFORM=$(echo $FILE | sed -n 's/package_build_list_host_\(.*\).json/\1/p')
    case $PLATFORM in
    linux*)
      OS_RUNNER="ubuntu-20.04"
      ;;
    windows)
      OS_RUNNER="windows-latest" # This is bundled with VS2022
      ;;
    darwin)
      OS_RUNNER="macos-latest"
      ;;
    *)
      OS_RUNNER="windows-latest" # default
      ;;
    esac
    
    echo "  File: $FILE"
    DIFF=$(git diff 7901137c1edf74d3f8c7c9fe1081e87cf29a4af2...30cfbab1672419d9f9d8dc123a5da07eb11eb0e9 --no-ext-diff --unified=0 \
                  --exit-code -a --no-prefix -- $FILE | egrep "^\+" | grep Scripts) # Get only the changes that can be built
    
    echo "  Diff: $DIFF"
    PACKAGE=$(echo $DIFF | cut -d'"' -f2)
    PACKPATH=$(echo $DIFF | egrep -o "package-system/[^ ]*")
    DOCKER=$(test -f "$PACKPATH/Dockerfile" && echo 1 || echo 0)
    JSONline="{\"package\": \"$PACKAGE\", \"os\": \"$OS_RUNNER\", \"dockerfile\": \"$DOCKER\"},"
    if [[ "$JSON" != *"$JSONline"* ]]; then
      JSON="$JSON$JSONline"
    fi
  fi
done

# Remove last "," and add closing brackets
if [[ $JSON == *, ]]; then
  JSON="${JSON%?}"
fi
JSON="$JSON]}"

echo "Json: $JSON"
