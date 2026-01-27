#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (schuch666): " username
    username=${username:-schuch666}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.31/TEMPO_HCHO_L3_V03_20240731T233257Z_S016.nc"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.31/TEMPO_HCHO_L3_V03_20240731T233257Z_S016.nc -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.31/TEMPO_HCHO_L3_V03_20240731T233257Z_S016.nc | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T235427Z_S016.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T231422Z_S015.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T221422Z_S014.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T211422Z_S013.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T201422Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T191422Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T181422Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T171422Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T161422Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T151422Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T141422Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T131422Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T123417Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T115412Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T111407Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T103402Z_S001.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T011421Z_S018.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.07.01/TEMPO_HCHO_L3_V03_20240701T003416Z_S017.nc
EDSCEOF
