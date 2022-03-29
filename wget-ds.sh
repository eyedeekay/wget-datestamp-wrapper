#! /usr/bin/env sh

# get the URL that was passed to wget, the last argument
for URL; do true; done

# find the value of the -O flag
for OPT in "$@"; do
  if [ "$OPT" = "-O" ]; then
    shift
    FILE="$1"
    shift
  fi
done

if [ -z "$FILE" ]; then
  FILE=$(wget --server-response -q -O - "$URL" 2>&1 | 
  grep "Content-Disposition:" | tail -1 | 
  awk 'match($0, /filename=(.+)/, f){ print f[1] }')
fi

# use wget to collect the date stamp
UPSTREAM_DATE=$(wget --spider -S "$URL" 2>&1 | grep Last-Modified | sed 's/^.*: //')

UNIVERSAL_UPSTREAM_DATE=$(date -u -d "$UPSTREAM_DATE" +%Y%m%d%H%M%S)

echo "$@"
echo "Upstream date: $UPSTREAM_DATE"
echo "Universal upstream date: $UNIVERSAL_UPSTREAM_DATE"
echo "Filename: $FILE"

if [ -f "$FILE" ]; then
  LOCAL_DATE=$(stat "$FILE" | grep Modify | sed 's/^.*: //')
  UNIVERSAL_LOCAL_DATE=$(date -u -d "$LOCAL_DATE" +%Y%m%d%H%M%S)
  echo "Local date: $LOCAL_DATE"
  echo "Universal local date: $UNIVERSAL_LOCAL_DATE"
  if [ "$UNIVERSAL_LOCAL_DATE" -ge "$UNIVERSAL_UPSTREAM_DATE" ]; then
    echo "Local file is newer than upstream file, skipping download"
    exit 0
  fi
  echo "Local file is older than upstream file, downloading"
  mv "$FILE" "$FILE.old"
fi

wget -c -O "$FILE" "$URL"
rm -f "$FILE.old"