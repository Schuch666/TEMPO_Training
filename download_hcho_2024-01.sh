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
    echo "https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T230041Z_S013.nc"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T230041Z_S013.nc -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T230041Z_S013.nc | tail -1)
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
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T230041Z_S013.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T222036Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T212036Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T202036Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T192036Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T182036Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T172036Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T162036Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T152036Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T142036Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T134031Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.23/TEMPO_HCHO_L3_V03_20240123T130026Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.22/TEMPO_HCHO_L3_V03_20240122T230026Z_S013.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.22/TEMPO_HCHO_L3_V03_20240122T222021Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.22/TEMPO_HCHO_L3_V03_20240122T212021Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.22/TEMPO_HCHO_L3_V03_20240122T202021Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.22/TEMPO_HCHO_L3_V03_20240122T192021Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.22/TEMPO_HCHO_L3_V03_20240122T182021Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.22/TEMPO_HCHO_L3_V03_20240122T172021Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.22/TEMPO_HCHO_L3_V03_20240122T162021Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.22/TEMPO_HCHO_L3_V03_20240122T152021Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.22/TEMPO_HCHO_L3_V03_20240122T142021Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.22/TEMPO_HCHO_L3_V03_20240122T134016Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.22/TEMPO_HCHO_L3_V03_20240122T130011Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.21/TEMPO_HCHO_L3_V03_20240121T230009Z_S013.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.21/TEMPO_HCHO_L3_V03_20240121T222004Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.21/TEMPO_HCHO_L3_V03_20240121T212004Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.21/TEMPO_HCHO_L3_V03_20240121T202004Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.21/TEMPO_HCHO_L3_V03_20240121T192004Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.21/TEMPO_HCHO_L3_V03_20240121T182004Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.21/TEMPO_HCHO_L3_V03_20240121T172004Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.21/TEMPO_HCHO_L3_V03_20240121T162004Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.21/TEMPO_HCHO_L3_V03_20240121T152004Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.21/TEMPO_HCHO_L3_V03_20240121T142004Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.21/TEMPO_HCHO_L3_V03_20240121T133959Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.21/TEMPO_HCHO_L3_V03_20240121T125954Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.20/TEMPO_HCHO_L3_V03_20240120T225951Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.20/TEMPO_HCHO_L3_V03_20240120T221946Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.20/TEMPO_HCHO_L3_V03_20240120T211946Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.20/TEMPO_HCHO_L3_V03_20240120T201946Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.20/TEMPO_HCHO_L3_V03_20240120T191946Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.20/TEMPO_HCHO_L3_V03_20240120T181946Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.20/TEMPO_HCHO_L3_V03_20240120T174515Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.20/TEMPO_HCHO_L3_V03_20240120T151947Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.20/TEMPO_HCHO_L3_V03_20240120T141946Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.20/TEMPO_HCHO_L3_V03_20240120T133941Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.20/TEMPO_HCHO_L3_V03_20240120T125936Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.19/TEMPO_HCHO_L3_V03_20240119T225932Z_S013.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.19/TEMPO_HCHO_L3_V03_20240119T221927Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.19/TEMPO_HCHO_L3_V03_20240119T211927Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.19/TEMPO_HCHO_L3_V03_20240119T201927Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.19/TEMPO_HCHO_L3_V03_20240119T191927Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.19/TEMPO_HCHO_L3_V03_20240119T181927Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.19/TEMPO_HCHO_L3_V03_20240119T171927Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.19/TEMPO_HCHO_L3_V03_20240119T161927Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.19/TEMPO_HCHO_L3_V03_20240119T151927Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.19/TEMPO_HCHO_L3_V03_20240119T141927Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.19/TEMPO_HCHO_L3_V03_20240119T133922Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.19/TEMPO_HCHO_L3_V03_20240119T125917Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.18/TEMPO_HCHO_L3_V03_20240118T225913Z_S013.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.18/TEMPO_HCHO_L3_V03_20240118T221908Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.18/TEMPO_HCHO_L3_V03_20240118T211908Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.18/TEMPO_HCHO_L3_V03_20240118T201908Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.18/TEMPO_HCHO_L3_V03_20240118T191908Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.18/TEMPO_HCHO_L3_V03_20240118T181908Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.18/TEMPO_HCHO_L3_V03_20240118T171908Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.18/TEMPO_HCHO_L3_V03_20240118T161908Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.18/TEMPO_HCHO_L3_V03_20240118T151908Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.18/TEMPO_HCHO_L3_V03_20240118T141908Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.18/TEMPO_HCHO_L3_V03_20240118T133903Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.18/TEMPO_HCHO_L3_V03_20240118T125858Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.17/TEMPO_HCHO_L3_V03_20240117T225854Z_S013.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.17/TEMPO_HCHO_L3_V03_20240117T221849Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.17/TEMPO_HCHO_L3_V03_20240117T211849Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.17/TEMPO_HCHO_L3_V03_20240117T201849Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.17/TEMPO_HCHO_L3_V03_20240117T191849Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.17/TEMPO_HCHO_L3_V03_20240117T181849Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.17/TEMPO_HCHO_L3_V03_20240117T171849Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.17/TEMPO_HCHO_L3_V03_20240117T161849Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.17/TEMPO_HCHO_L3_V03_20240117T151849Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.17/TEMPO_HCHO_L3_V03_20240117T141849Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.17/TEMPO_HCHO_L3_V03_20240117T133844Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.17/TEMPO_HCHO_L3_V03_20240117T125839Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.16/TEMPO_HCHO_L3_V03_20240116T232040Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.16/TEMPO_HCHO_L3_V03_20240116T191829Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.16/TEMPO_HCHO_L3_V03_20240116T181828Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.16/TEMPO_HCHO_L3_V03_20240116T171828Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.16/TEMPO_HCHO_L3_V03_20240116T161828Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.16/TEMPO_HCHO_L3_V03_20240116T151828Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.16/TEMPO_HCHO_L3_V03_20240116T141828Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.16/TEMPO_HCHO_L3_V03_20240116T133823Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.16/TEMPO_HCHO_L3_V03_20240116T125818Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.15/TEMPO_HCHO_L3_V03_20240115T225812Z_S013.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.15/TEMPO_HCHO_L3_V03_20240115T221807Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.15/TEMPO_HCHO_L3_V03_20240115T211807Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.15/TEMPO_HCHO_L3_V03_20240115T201807Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.15/TEMPO_HCHO_L3_V03_20240115T191807Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.15/TEMPO_HCHO_L3_V03_20240115T181807Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.15/TEMPO_HCHO_L3_V03_20240115T171807Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.15/TEMPO_HCHO_L3_V03_20240115T161807Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.15/TEMPO_HCHO_L3_V03_20240115T151807Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.15/TEMPO_HCHO_L3_V03_20240115T141807Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.15/TEMPO_HCHO_L3_V03_20240115T133802Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.15/TEMPO_HCHO_L3_V03_20240115T125757Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.14/TEMPO_HCHO_L3_V03_20240114T225750Z_S013.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.14/TEMPO_HCHO_L3_V03_20240114T221745Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.14/TEMPO_HCHO_L3_V03_20240114T211745Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.14/TEMPO_HCHO_L3_V03_20240114T201745Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.14/TEMPO_HCHO_L3_V03_20240114T191745Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.14/TEMPO_HCHO_L3_V03_20240114T181745Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.14/TEMPO_HCHO_L3_V03_20240114T171745Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.14/TEMPO_HCHO_L3_V03_20240114T161745Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.14/TEMPO_HCHO_L3_V03_20240114T151745Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.14/TEMPO_HCHO_L3_V03_20240114T141745Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.14/TEMPO_HCHO_L3_V03_20240114T133740Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.14/TEMPO_HCHO_L3_V03_20240114T125735Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.13/TEMPO_HCHO_L3_V03_20240113T225726Z_S013.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.13/TEMPO_HCHO_L3_V03_20240113T221721Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.13/TEMPO_HCHO_L3_V03_20240113T211721Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.13/TEMPO_HCHO_L3_V03_20240113T201721Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.13/TEMPO_HCHO_L3_V03_20240113T191721Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.13/TEMPO_HCHO_L3_V03_20240113T181721Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.13/TEMPO_HCHO_L3_V03_20240113T171721Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.13/TEMPO_HCHO_L3_V03_20240113T161721Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.13/TEMPO_HCHO_L3_V03_20240113T151721Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.13/TEMPO_HCHO_L3_V03_20240113T141721Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.13/TEMPO_HCHO_L3_V03_20240113T133716Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.13/TEMPO_HCHO_L3_V03_20240113T125711Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.12/TEMPO_HCHO_L3_V03_20240112T225703Z_S013.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.12/TEMPO_HCHO_L3_V03_20240112T221658Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.12/TEMPO_HCHO_L3_V03_20240112T211658Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.12/TEMPO_HCHO_L3_V03_20240112T201658Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.12/TEMPO_HCHO_L3_V03_20240112T191658Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.12/TEMPO_HCHO_L3_V03_20240112T181658Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.12/TEMPO_HCHO_L3_V03_20240112T171658Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.12/TEMPO_HCHO_L3_V03_20240112T161658Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.12/TEMPO_HCHO_L3_V03_20240112T151658Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.12/TEMPO_HCHO_L3_V03_20240112T141658Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.12/TEMPO_HCHO_L3_V03_20240112T133653Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.12/TEMPO_HCHO_L3_V03_20240112T125648Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.11/TEMPO_HCHO_L3_V03_20240111T225640Z_S013.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.11/TEMPO_HCHO_L3_V03_20240111T221635Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.11/TEMPO_HCHO_L3_V03_20240111T211635Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.11/TEMPO_HCHO_L3_V03_20240111T201635Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.11/TEMPO_HCHO_L3_V03_20240111T191635Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.11/TEMPO_HCHO_L3_V03_20240111T181635Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.11/TEMPO_HCHO_L3_V03_20240111T171635Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.11/TEMPO_HCHO_L3_V03_20240111T161635Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.11/TEMPO_HCHO_L3_V03_20240111T151635Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.11/TEMPO_HCHO_L3_V03_20240111T141635Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.11/TEMPO_HCHO_L3_V03_20240111T133630Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.11/TEMPO_HCHO_L3_V03_20240111T125625Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.10/TEMPO_HCHO_L3_V03_20240110T225615Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.10/TEMPO_HCHO_L3_V03_20240110T221610Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.10/TEMPO_HCHO_L3_V03_20240110T211610Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.10/TEMPO_HCHO_L3_V03_20240110T201610Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.10/TEMPO_HCHO_L3_V03_20240110T191610Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.10/TEMPO_HCHO_L3_V03_20240110T181610Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.10/TEMPO_HCHO_L3_V03_20240110T171610Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.10/TEMPO_HCHO_L3_V03_20240110T161610Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.10/TEMPO_HCHO_L3_V03_20240110T151610Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.10/TEMPO_HCHO_L3_V03_20240110T141610Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.10/TEMPO_HCHO_L3_V03_20240110T133605Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.10/TEMPO_HCHO_L3_V03_20240110T125600Z_S001.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.09/TEMPO_HCHO_L3_V03_20240109T225549Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.09/TEMPO_HCHO_L3_V03_20240109T221544Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.09/TEMPO_HCHO_L3_V03_20240109T211544Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.09/TEMPO_HCHO_L3_V03_20240109T201544Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.09/TEMPO_HCHO_L3_V03_20240109T191544Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.09/TEMPO_HCHO_L3_V03_20240109T181544Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.09/TEMPO_HCHO_L3_V03_20240109T171544Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.09/TEMPO_HCHO_L3_V03_20240109T161544Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.09/TEMPO_HCHO_L3_V03_20240109T151544Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.09/TEMPO_HCHO_L3_V03_20240109T141544Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.09/TEMPO_HCHO_L3_V03_20240109T133539Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.09/TEMPO_HCHO_L3_V03_20240109T125534Z_S001.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.08/TEMPO_HCHO_L3_V03_20240108T225524Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.08/TEMPO_HCHO_L3_V03_20240108T221519Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.08/TEMPO_HCHO_L3_V03_20240108T211519Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.08/TEMPO_HCHO_L3_V03_20240108T201519Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.08/TEMPO_HCHO_L3_V03_20240108T191519Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.08/TEMPO_HCHO_L3_V03_20240108T181519Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.08/TEMPO_HCHO_L3_V03_20240108T171519Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.08/TEMPO_HCHO_L3_V03_20240108T161519Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.08/TEMPO_HCHO_L3_V03_20240108T151519Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.08/TEMPO_HCHO_L3_V03_20240108T141519Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.08/TEMPO_HCHO_L3_V03_20240108T133514Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.08/TEMPO_HCHO_L3_V03_20240108T125509Z_S001.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.07/TEMPO_HCHO_L3_V03_20240107T225458Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.07/TEMPO_HCHO_L3_V03_20240107T221453Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.07/TEMPO_HCHO_L3_V03_20240107T211453Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.07/TEMPO_HCHO_L3_V03_20240107T201453Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.07/TEMPO_HCHO_L3_V03_20240107T191453Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.07/TEMPO_HCHO_L3_V03_20240107T181453Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.07/TEMPO_HCHO_L3_V03_20240107T171453Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.07/TEMPO_HCHO_L3_V03_20240107T161453Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.07/TEMPO_HCHO_L3_V03_20240107T151453Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.07/TEMPO_HCHO_L3_V03_20240107T141453Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.07/TEMPO_HCHO_L3_V03_20240107T133448Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.07/TEMPO_HCHO_L3_V03_20240107T125443Z_S001.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.06/TEMPO_HCHO_L3_V03_20240106T225431Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.06/TEMPO_HCHO_L3_V03_20240106T221426Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.06/TEMPO_HCHO_L3_V03_20240106T211426Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.06/TEMPO_HCHO_L3_V03_20240106T201426Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.06/TEMPO_HCHO_L3_V03_20240106T191426Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.06/TEMPO_HCHO_L3_V03_20240106T181426Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.06/TEMPO_HCHO_L3_V03_20240106T171426Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.06/TEMPO_HCHO_L3_V03_20240106T161426Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.06/TEMPO_HCHO_L3_V03_20240106T151426Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.06/TEMPO_HCHO_L3_V03_20240106T141426Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.06/TEMPO_HCHO_L3_V03_20240106T133421Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.06/TEMPO_HCHO_L3_V03_20240106T125416Z_S001.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.05/TEMPO_HCHO_L3_V03_20240105T225405Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.05/TEMPO_HCHO_L3_V03_20240105T221400Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.05/TEMPO_HCHO_L3_V03_20240105T211400Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.05/TEMPO_HCHO_L3_V03_20240105T201400Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.05/TEMPO_HCHO_L3_V03_20240105T191400Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.05/TEMPO_HCHO_L3_V03_20240105T181400Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.05/TEMPO_HCHO_L3_V03_20240105T171400Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.05/TEMPO_HCHO_L3_V03_20240105T161400Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.05/TEMPO_HCHO_L3_V03_20240105T151400Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.05/TEMPO_HCHO_L3_V03_20240105T141400Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.05/TEMPO_HCHO_L3_V03_20240105T133355Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.05/TEMPO_HCHO_L3_V03_20240105T125350Z_S001.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.04/TEMPO_HCHO_L3_V03_20240104T225337Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.04/TEMPO_HCHO_L3_V03_20240104T221332Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.04/TEMPO_HCHO_L3_V03_20240104T211332Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.04/TEMPO_HCHO_L3_V03_20240104T201332Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.04/TEMPO_HCHO_L3_V03_20240104T191332Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.04/TEMPO_HCHO_L3_V03_20240104T181332Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.04/TEMPO_HCHO_L3_V03_20240104T171332Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.04/TEMPO_HCHO_L3_V03_20240104T161332Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.04/TEMPO_HCHO_L3_V03_20240104T151332Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.04/TEMPO_HCHO_L3_V03_20240104T141332Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.04/TEMPO_HCHO_L3_V03_20240104T133327Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.04/TEMPO_HCHO_L3_V03_20240104T125322Z_S001.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.03/TEMPO_HCHO_L3_V03_20240103T225309Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.03/TEMPO_HCHO_L3_V03_20240103T221304Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.03/TEMPO_HCHO_L3_V03_20240103T211304Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.03/TEMPO_HCHO_L3_V03_20240103T201304Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.03/TEMPO_HCHO_L3_V03_20240103T191304Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.03/TEMPO_HCHO_L3_V03_20240103T181304Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.03/TEMPO_HCHO_L3_V03_20240103T171304Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.03/TEMPO_HCHO_L3_V03_20240103T161304Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.03/TEMPO_HCHO_L3_V03_20240103T151304Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.03/TEMPO_HCHO_L3_V03_20240103T141304Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.03/TEMPO_HCHO_L3_V03_20240103T133259Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.03/TEMPO_HCHO_L3_V03_20240103T125254Z_S001.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.02/TEMPO_HCHO_L3_V03_20240102T225241Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.02/TEMPO_HCHO_L3_V03_20240102T221236Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.02/TEMPO_HCHO_L3_V03_20240102T211236Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.02/TEMPO_HCHO_L3_V03_20240102T201236Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.02/TEMPO_HCHO_L3_V03_20240102T191236Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.02/TEMPO_HCHO_L3_V03_20240102T181236Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.02/TEMPO_HCHO_L3_V03_20240102T171236Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.02/TEMPO_HCHO_L3_V03_20240102T161236Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.02/TEMPO_HCHO_L3_V03_20240102T151236Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.02/TEMPO_HCHO_L3_V03_20240102T141236Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.02/TEMPO_HCHO_L3_V03_20240102T133231Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.02/TEMPO_HCHO_L3_V03_20240102T125226Z_S001.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.01/TEMPO_HCHO_L3_V03_20240101T225212Z_S012.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.01/TEMPO_HCHO_L3_V03_20240101T221207Z_S011.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.01/TEMPO_HCHO_L3_V03_20240101T211207Z_S010.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.01/TEMPO_HCHO_L3_V03_20240101T201207Z_S009.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.01/TEMPO_HCHO_L3_V03_20240101T191207Z_S008.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.01/TEMPO_HCHO_L3_V03_20240101T181207Z_S007.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.01/TEMPO_HCHO_L3_V03_20240101T171207Z_S006.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.01/TEMPO_HCHO_L3_V03_20240101T161207Z_S005.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.01/TEMPO_HCHO_L3_V03_20240101T151207Z_S004.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.01/TEMPO_HCHO_L3_V03_20240101T141207Z_S003.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.01/TEMPO_HCHO_L3_V03_20240101T133202Z_S002.nc
https://data.asdc.earthdata.nasa.gov/asdc-prod-protected/TEMPO/TEMPO_HCHO_L3_V03/2024.01.01/TEMPO_HCHO_L3_V03_20240101T125157Z_S001.nc
EDSCEOF