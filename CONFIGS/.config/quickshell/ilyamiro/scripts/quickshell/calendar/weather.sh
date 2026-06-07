# #!/usr/bin/env bash

# # Force standard C locale for number formatting (fixes printf decimal/comma issues on varying OS locales)
# export LC_NUMERIC=C

# # Paths
# cache_dir="$HOME/.cache/quickshell/weather"
# json_file="${cache_dir}/weather.json"
# view_file="${cache_dir}/view_id"
# daily_cache_file="${cache_dir}/daily_weather_cache.json"
# next_day_cache_file="${cache_dir}/next_day_precache.json"
# ENV_FILE="$(dirname "$0")/.env"

# # API Settings
# # Load environment variables silently
# if [ -f "$ENV_FILE" ]; then
#     export $(grep -v '^#' "$ENV_FILE" | xargs)
# fi

# # API Settings from .env
# KEY="$OPENWEATHER_KEY"
# ID="$OPENWEATHER_CITY_ID"
# UNIT="${OPENWEATHER_UNIT:-metric}" # Default to metric if not set

# mkdir -p "${cache_dir}"

# get_icon() {
#     case $1 in
#         "50d"|"50n") icon=""; quote="Mist" ;;
#         "01d") icon=""; quote="Sunny" ;;
#         "01n") icon=""; quote="Clear" ;;
#         "02d"|"02n"|"03d"|"03n"|"04d"|"04n") icon=""; quote="Cloudy" ;;
#         "09d"|"09n"|"10d"|"10n") icon=""; quote="Rainy" ;;
#         "11d"|"11n") icon=""; quote="Storm" ;;
#         "13d"|"13n") icon=""; quote="Snow" ;;
#         *) icon=""; quote="Unknown" ;;
#     esac
#     echo "$icon|$quote"
# }

# get_hex() {
#     case $1 in
#         "50d"|"50n") echo "#84afdb" ;;
#         "01d") echo "#f9e2af" ;;
#         "01n") echo "#cba6f7" ;;
#         "02d"|"02n"|"03d"|"03n"|"04d"|"04n") echo "#bac2de" ;;
#         "09d"|"09n"|"10d"|"10n") echo "#74c7ec" ;;
#         "11d"|"11n") echo "#f9e2af" ;;
#         "13d"|"13n") echo "#cdd6f4" ;;
#         *) echo "#cdd6f4" ;;
#     esac
# }

# write_dummy_data() {
#     final_json="["
#     for i in {0..4}; do
#         future_date=$(date -d "+$i days")
#         f_day=$(date -d "$future_date" "+%a")
#         f_full_day=$(date -d "$future_date" "+%A")
#         f_date_num=$(date -d "$future_date" "+%d %b")
        
#         final_json="${final_json} {
#             \"id\": \"${i}\",
#             \"day\": \"${f_day}\",
#             \"day_full\": \"${f_full_day}\",
#             \"date\": \"${f_date_num}\",
#             \"max\": \"0.0\",
#             \"min\": \"0.0\",
#             \"feels_like\": \"0.0\",
#             \"wind\": \"0\",
#             \"humidity\": \"0\",
#             \"pop\": \"0\",
#             \"icon\": \"\",
#             \"hex\": \"#cdd6f4\",
#             \"desc\": \"No API Key\",
#             \"hourly\": [{\"time\": \"00:00\", \"temp\": \"0.0\", \"icon\": \"\", \"hex\": \"#cdd6f4\"}]
#         },"
#     done
#     final_json="${final_json%,}]"
#     echo "{ \"forecast\": ${final_json} }" > "${json_file}"
# }

# get_data() {
#     # ---------------------------------------------------------
#     # DUMMY DATA FALLBACK (If API key is missing or skipped)
#     # ---------------------------------------------------------
#     if [[ -z "$KEY" || "$KEY" == "Skipped" || "$KEY" == "OPENWEATHER_KEY" ]]; then
#         write_dummy_data
#         return
#     fi

#     # ---------------------------------------------------------
#     # STANDARD API FETCH LOGIC
#     # ---------------------------------------------------------
#     forecast_url="http://api.openweathermap.org/data/2.5/forecast?APPID=${KEY}&id=${ID}&units=${UNIT}"
#     raw_api=$(curl -sf "$forecast_url")
    
#     # Check if curl failed OR if OpenWeather returned an error (like 401 for pending keys)
#     api_cod=$(echo "$raw_api" | jq -r '.cod' 2>/dev/null)
    
#     if [ -z "$raw_api" ] || [[ "$api_cod" != "200" ]]; then
#         write_dummy_data
#         return
#     fi

#     current_date=$(date +%Y-%m-%d)
#     tomorrow_date=$(date -d "tomorrow" +%Y-%m-%d)

#     # 1. ROLLOVER CHECK
#     if [ -f "$next_day_cache_file" ]; then
#         precache_date=$(cat "$next_day_cache_file" | jq -r '.[0].dt_txt' | cut -d' ' -f1)
#         if [ "$precache_date" == "$current_date" ]; then
#             mv "$next_day_cache_file" "$daily_cache_file"
#         fi
#     fi

#     # 2. PROCESS TODAY
#     api_today_items=$(echo "$raw_api" | jq -c ".list[] | select(.dt_txt | startswith(\"$current_date\"))" | jq -s '.')

#     if [ -f "$daily_cache_file" ]; then
#         cached_date=$(cat "$daily_cache_file" | jq -r '.[0].dt_txt' | cut -d' ' -f1)
#         if [ "$cached_date" == "$current_date" ]; then
#             merged_today=$(echo "$api_today_items" | jq --slurpfile cache "$daily_cache_file" \
#                 '($cache[0] + .) | unique_by(.dt) | sort_by(.dt)')
#         else
#             merged_today="$api_today_items"
#         fi
#     else
#         merged_today="$api_today_items"
#     fi

#     echo "$merged_today" > "$daily_cache_file"

#     # 3. PRE-CACHE TOMORROW
#     api_tomorrow_items=$(echo "$raw_api" | jq -c ".list[] | select(.dt_txt | startswith(\"$tomorrow_date\"))" | jq -s '.')
#     echo "$api_tomorrow_items" > "$next_day_cache_file"

#     # 4. BUILD FINAL JSON
#     processed_forecast=$(echo "$raw_api" | jq --argjson today "$merged_today" --arg date "$current_date" \
#         '.list = ($today + [.list[] | select(.dt_txt | startswith($date) | not)])')

#     if [ ! -z "$processed_forecast" ]; then
#         dates=$(echo "$processed_forecast" | jq -r '.list[].dt_txt | split(" ")[0]' | uniq | head -n 5)
        
#         final_json="["
#         counter=0
        
#         for d in $dates; do
#             day_data=$(echo "$processed_forecast" | jq "[.list[] | select(.dt_txt | startswith(\"$d\"))]")

#             raw_max=$(echo "$day_data" | jq '[.[].main.temp_max] | max')
#             f_max_temp=$(printf "%.1f" "$raw_max")

#             raw_min=$(echo "$day_data" | jq '[.[].main.temp_min] | min')
#             f_min_temp=$(printf "%.1f" "$raw_min")

#             raw_feels=$(echo "$day_data" | jq '[.[].main.feels_like] | max')
#             f_feels_like=$(printf "%.1f" "$raw_feels")

#             f_pop=$(echo "$day_data" | jq '[.[].pop] | max')
#             f_pop_pct=$(echo "$f_pop * 100" | bc | cut -d. -f1)
#             f_wind=$(echo "$day_data" | jq '[.[].wind.speed] | max | round')
#             f_hum=$(echo "$day_data" | jq '[.[].main.humidity] | add / length | round')
            
#             f_code=$(echo "$day_data" | jq -r '.[length/2 | floor].weather[0].icon')
#             f_desc=$(echo "$day_data" | jq -r '.[length/2 | floor].weather[0].description' | sed -e "s/\b\(.\)/\u\1/g")
#             f_icon_data=$(get_icon "$f_code")
#             f_icon=$(echo "$f_icon_data" | cut -d'|' -f1)
#             f_hex=$(get_hex "$f_code")
            
#             f_day=$(date -d "$d" "+%a")
#             f_full_day=$(date -d "$d" "+%A")
#             f_date_num=$(date -d "$d" "+%d %b")

#             hourly_json="["
#             count_slots=$(echo "$day_data" | jq '. | length')
#             count_slots=$((count_slots-1))
            
#             for i in $(seq 0 1 $count_slots); do
#                 slot_item=$(echo "$day_data" | jq ".[$i]")
                
#                 raw_s_temp=$(echo "$slot_item" | jq ".main.temp")
#                 s_temp=$(printf "%.1f" "$raw_s_temp")
                
#                 s_dt=$(echo "$slot_item" | jq ".dt")
#                 s_time=$(date -d @$s_dt "+%H:%M")
#                 s_code=$(echo "$slot_item" | jq -r ".weather[0].icon")
#                 s_hex=$(get_hex "$s_code")
#                 s_icon=$(get_icon "$s_code" | cut -d'|' -f1)
                
#                 hourly_json="${hourly_json} {\"time\": \"${s_time}\", \"temp\": \"${s_temp}\", \"icon\": \"${s_icon}\", \"hex\": \"${s_hex}\"},"
#             done
#             hourly_json="${hourly_json%,}]"

#             final_json="${final_json} {
#                 \"id\": \"${counter}\",
#                 \"day\": \"${f_day}\",
#                 \"day_full\": \"${f_full_day}\",
#                 \"date\": \"${f_date_num}\",
#                 \"max\": \"${f_max_temp}\",
#                 \"min\": \"${f_min_temp}\",
#                 \"feels_like\": \"${f_feels_like}\",
#                 \"wind\": \"${f_wind}\",
#                 \"humidity\": \"${f_hum}\",
#                 \"pop\": \"${f_pop_pct}\",
#                 \"icon\": \"${f_icon}\",
#                 \"hex\": \"${f_hex}\",
#                 \"desc\": \"${f_desc}\",
#                 \"hourly\": ${hourly_json}
#             },"
#             ((counter++))
#         done
#         final_json="${final_json%,}]"

#         echo "{ \"forecast\": ${final_json} }" > "${json_file}"
#     fi
# }

# # --- MODE HANDLING ---
# if [[ "$1" == "--getdata" ]]; then
#     get_data

# elif [[ "$1" == "--json" ]]; then
#     CACHE_LIMIT=900         # 15 minutes for valid working data
#     PENDING_RETRY_LIMIT=3600 # 1 hour for invalid/activating keys

#     if [ -f "$json_file" ]; then
#         file_time=$(stat -c %Y "$json_file")
#         current_time=$(date +%s)
#         diff=$((current_time - file_time))
        
#         if grep -q '"desc": "No API Key"' "$json_file"; then
#             # Key is pending/invalid. Check once an hour.
#             if [ $diff -gt $PENDING_RETRY_LIMIT ]; then
#                 touch "$json_file" # Bump file timestamp slightly to avoid spamming processes
#                 get_data &
#             fi
#         else
#             # Normal working API key. Check every 15 mins.
#             if [ $diff -gt $CACHE_LIMIT ]; then
#                 touch "$json_file"
#                 get_data &
#             fi
#         fi
#         cat "$json_file"
#     else
#         get_data
#         cat "$json_file"
#     fi

# elif [[ "$1" == "--view-listener" ]]; then
#     if [ ! -f "$view_file" ]; then echo "0" > "$view_file"; fi
#     tail -F "$view_file"

# elif [[ "$1" == "--nav" ]]; then
#     if [ ! -f "$view_file" ]; then echo "0" > "$view_file"; fi
#     current=$(cat "$view_file")
#     direction=$2
#     max_idx=4
#     if [[ "$direction" == "next" ]]; then
#         if [ "$current" -lt "$max_idx" ]; then
#             new=$((current + 1))
#             echo "$new" > "$view_file"
#         fi
#     elif [[ "$direction" == "prev" ]]; then
#         if [ "$current" -gt 0 ]; then
#             new=$((current - 1))
#             echo "$new" > "$view_file"
#         fi
#     fi

# elif [[ "$1" == "--icon" ]]; then
#     cat "$json_file" | jq -r '.forecast[0].icon'

# elif [[ "$1" == "--temp" ]]; then 
#     t=$(cat "$json_file" | jq -r '.forecast[0].max')
#     echo "${t}°C"

# elif [[ "$1" == "--hex" ]]; then 
#     cat "$json_file" | jq -r '.forecast[0].hex'

# # --- NEW HOURLY MODES FOR TOPBAR ---
# elif [[ "$1" == "--current-icon" ]]; then
#     curr_time=$(date +%H:%M)
#     cat "$json_file" | jq -r --arg ct "$curr_time" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .icon'

# elif [[ "$1" == "--current-temp" ]]; then 
#     curr_time=$(date +%H:%M)
#     t=$(cat "$json_file" | jq -r --arg ct "$curr_time" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .temp')
#     echo "${t}°C"

# elif [[ "$1" == "--current-hex" ]]; then
#     curr_time=$(date +%H:%M)
#     cat "$json_file" | jq -r --arg ct "$curr_time" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .hex'
# fi





#!/usr/bin/env bash                                                                                          # Shebang: tells the system to execute this script using the bash shell found in the user's PATH environment

# Force standard C locale for number formatting (fixes printf decimal/comma issues on varying OS locales)    # Comment explaining that LC_NUMERIC=C ensures consistent decimal point formatting across different systems
export LC_NUMERIC=C                                                                                          # Sets the numeric locale category to C (standard), preventing printf from using commas instead of decimal points

# Paths                                                                                                      # Section comment: defines all file paths used by the weather script
cache_dir="$HOME/.cache/quickshell/weather"                                                                  # Sets the base cache directory path for storing all weather-related data files
json_file="${cache_dir}/weather.json"                                                                        # Sets the path to the main weather JSON output file read by the QML frontend
view_file="${cache_dir}/view_id"                                                                             # Sets the path to a file storing the current weather view index (0-4 for different days)
daily_cache_file="${cache_dir}/daily_weather_cache.json"                                                     # Sets the path to the cache file storing today's processed forecast data for rollover
next_day_cache_file="${cache_dir}/next_day_precache.json"                                                    # Sets the path to the cache file pre-storing tomorrow's forecast data for efficient rollover
ENV_FILE="$(dirname "$0")/.env"                                                                              # Resolves the path to the .env file located in the same directory as this script

# API Settings                                                                                               # Section comment: OpenWeatherMap API configuration
# Load environment variables silently                                                                         # Comment explaining the .env file loading process
if [ -f "$ENV_FILE" ]; then                                                                                  # Checks if the .env configuration file exists at the resolved path
    export $(grep -v '^#' "$ENV_FILE" | xargs)                                                               # Filters out comment lines (starting with #), then exports all key=value pairs as environment variables
fi

# API Settings from .env                                                                                     # Comment: these variables are populated from the .env file via the export above
KEY="$OPENWEATHER_KEY"                                                                                       # Stores the OpenWeatherMap API key from the environment variable
ID="$OPENWEATHER_CITY_ID"                                                                                    # Stores the OpenWeatherMap city ID from the environment variable
UNIT="${OPENWEATHER_UNIT:-metric}" # Default to metric if not set                                             # Stores the temperature unit; defaults to "metric" (Celsius) if the environment variable is not set

mkdir -p "${cache_dir}"                                                                                      # Creates the cache directory and any necessary parent directories if they don't already exist

get_icon() {                                                                                                 # Defines a function that maps OpenWeatherMap icon codes to Nerd Font icon glyphs and weather descriptions
    case $1 in                                                                                               # Begins a case statement checking the first function argument (weather icon code like "01d")
        "50d"|"50n") icon=""; quote="Mist" ;;                                                               # For mist/fog codes: sets icon to wind/mist symbol and quote to "Mist"
        "01d") icon=""; quote="Sunny" ;;                                                                    # For clear sky day: sun icon, "Sunny" description
        "01n") icon=""; quote="Clear" ;;                                                                    # For clear sky night: moon icon, "Clear" description
        "02d"|"02n"|"03d"|"03n"|"04d"|"04n") icon=""; quote="Cloudy" ;;                                   # For few clouds, scattered clouds, broken clouds (day/night): cloud icon, "Cloudy"
        "09d"|"09n"|"10d"|"10n") icon=""; quote="Rainy" ;;                                                 # For shower rain and rain (day/night): rain icon, "Rainy"
        "11d"|"11n") icon=""; quote="Storm" ;;                                                              # For thunderstorms: lightning icon, "Storm"
        "13d"|"13n") icon=""; quote="Snow" ;;                                                               # For snow: snowflake icon, "Snow"
        *) icon=""; quote="Unknown" ;;                                                                       # Default fallback for any unrecognized code: cloud icon, "Unknown"
    esac                                                                                                     # Ends the case statement
    echo "$icon|$quote"                                                                                      # Outputs the icon and quote separated by a pipe character for the caller to parse
}

get_hex() {                                                                                                  # Defines a function that maps OpenWeatherMap icon codes to accent hex colors for theming
    case $1 in                                                                                               # Begins a case statement on the weather icon code argument
        "50d"|"50n") echo "#84afdb" ;;                                                                        # Mist/fog: soft blue-grey hex color
        "01d") echo "#f9e2af" ;;                                                                              # Clear day: warm golden/sunny hex color
        "01n") echo "#cba6f7" ;;                                                                              # Clear night: soft mauve/purple hex color
        "02d"|"02n"|"03d"|"03n"|"04d"|"04n") echo "#bac2de" ;;                                              # Cloudy variations: light steel blue hex
        "09d"|"09n"|"10d"|"10n") echo "#74c7ec" ;;                                                           # Rain: bright sky blue hex
        "11d"|"11n") echo "#f9e2af" ;;                                                                        # Storm: golden yellow hex (lightning accent)
        "13d"|"13n") echo "#cdd6f4" ;;                                                                        # Snow: light lavender hex
        *) echo "#cdd6f4" ;;                                                                                  # Default: light lavender hex for unknown codes
    esac                                                                                                     // Ends the case statement
}

write_dummy_data() {                                                                                         // Defines a function that generates placeholder weather data when no valid API key is available
    final_json="["                                                                                           // Initializes the JSON array string with an opening bracket
    for i in {0..4}; do                                                                                      // Loops 5 times (indices 0 through 4) for a 5-day forecast
        future_date=$(date -d "+$i days")                                                                    // Calculates the date for i days from today using GNU date arithmetic
        f_day=$(date -d "$future_date" "+%a")                                                                // Extracts the abbreviated weekday name (e.g., "Mon") from the future date
        f_full_day=$(date -d "$future_date" "+%A")                                                           // Extracts the full weekday name (e.g., "Monday") from the future date
        f_date_num=$(date -d "$future_date" "+%d %b")                                                        // Extracts the day number and abbreviated month (e.g., "01 Jan") from the future date
        
        final_json="${final_json} {                                                                          // Appends a JSON object for this forecast day to the array string
            \"id\": \"${i}\",                                                                                // Sets the forecast ID to the loop index
            \"day\": \"${f_day}\",                                                                           // Sets the abbreviated day name field
            \"day_full\": \"${f_full_day}\",                                                                 // Sets the full day name field
            \"date\": \"${f_date_num}\",                                                                     // Sets the formatted date field
            \"max\": \"0.0\",                                                                                // Sets maximum temperature to 0.0 placeholder
            \"min\": \"0.0\",                                                                                // Sets minimum temperature to 0.0 placeholder
            \"feels_like\": \"0.0\",                                                                         // Sets feels-like temperature to 0.0 placeholder
            \"wind\": \"0\",                                                                                 // Sets wind speed to 0 placeholder
            \"humidity\": \"0\",                                                                             // Sets humidity to 0 placeholder
            \"pop\": \"0\",                                                                                  // Sets probability of precipitation to 0 placeholder
            \"icon\": \"\",                                                                                 // Sets default cloud icon placeholder
            \"hex\": \"#cdd6f4\",                                                                            // Sets default light lavender color placeholder
            \"desc\": \"No API Key\",                                                                        // Sets description to "No API Key" to indicate dummy data
            \"hourly\": [{\"time\": \"00:00\", \"temp\": \"0.0\", \"icon\": \"\", \"hex\": \"#cdd6f4\"}]  // Sets a single hourly slot at midnight with placeholder values
        },"                                                                                                  // Closes the JSON object with a trailing comma for array syntax
    done                                                                                                     // Ends the loop
    final_json="${final_json%,}]"                                                                            // Removes the trailing comma from the last object and closes the JSON array
    echo "{ \"forecast\": ${final_json} }" > "${json_file}"                                                  // Wraps the array in a forecast object and writes the complete JSON to the output file
}

get_data() {                                                                                                 // Defines the main function that fetches and processes weather data from the OpenWeatherMap API
    # ---------------------------------------------------------                                               // Visual separator
    # DUMMY DATA FALLBACK (If API key is missing or skipped)                                                // Section explaining the fallback logic
    # ---------------------------------------------------------                                               // Visual separator
    if [[ -z "$KEY" || "$KEY" == "Skipped" || "$KEY" == "OPENWEATHER_KEY" ]]; then                          // Checks if the API key is empty, set to "Skipped", or still has the default placeholder value
        write_dummy_data                                                                                     // Calls the dummy data function to generate placeholder forecast data
        return                                                                                               // Exits the function early since there's no valid API key to use
    fi

    # ---------------------------------------------------------                                               // Visual separator
    # STANDARD API FETCH LOGIC                                                                              // Section for the actual API call and data processing
    # ---------------------------------------------------------                                               // Visual separator
    forecast_url="http://api.openweathermap.org/data/2.5/forecast?APPID=${KEY}&id=${ID}&units=${UNIT}"      // Constructs the OpenWeatherMap 5-day/3-hour forecast API URL with key, city ID, and units
    raw_api=$(curl -sf "$forecast_url")                                                                      // Makes a silent HTTP GET request to the API; -s suppresses progress, -f fails silently on HTTP errors
                                                                                                             
    # Check if curl failed OR if OpenWeather returned an error (like 401 for pending keys)                  // Comment explaining error checking logic
    api_cod=$(echo "$raw_api" | jq -r '.cod' 2>/dev/null)                                                    // Extracts the API response code field (e.g., "200" for success, "401" for unauthorized) using jq
                                                                                                             
    if [ -z "$raw_api" ] || [[ "$api_cod" != "200" ]]; then                                                  // Checks if the API response is empty (curl failed) OR the response code is not 200 (API error)
        write_dummy_data                                                                                     // Writes placeholder data since the API call failed
        return                                                                                               // Exits the function early
    fi

    current_date=$(date +%Y-%m-%d)                                                                           // Gets today's date in ISO format (e.g., "2025-01-15") for filtering forecast data
    tomorrow_date=$(date -d "tomorrow" +%Y-%m-%d)                                                            // Gets tomorrow's date in ISO format for pre-caching

    # 1. ROLLOVER CHECK                                                                                     // Section: checks if yesterday's pre-cached data should become today's cache
    if [ -f "$next_day_cache_file" ]; then                                                                    // Checks if the next-day pre-cache file exists
        precache_date=$(cat "$next_day_cache_file" | jq -r '.[0].dt_txt' | cut -d' ' -f1)                    // Extracts the date portion from the first entry's timestamp in the pre-cache file
        if [ "$precache_date" == "$current_date" ]; then                                                     // If the pre-cached date matches today's date (meaning it's now valid for today)
            mv "$next_day_cache_file" "$daily_cache_file"                                                     // Moves the pre-cache file to become today's daily cache (efficient rollover)
        fi
    fi

    # 2. PROCESS TODAY                                                                                      // Section: filters and merges today's forecast data
    api_today_items=$(echo "$raw_api" | jq -c ".list[] | select(.dt_txt | startswith(\"$current_date\"))" | jq -s '.') // Filters the API response for entries starting with today's date and combines into a JSON array

    if [ -f "$daily_cache_file" ]; then                                                                       // Checks if a daily cache file exists from a previous run
        cached_date=$(cat "$daily_cache_file" | jq -r '.[0].dt_txt' | cut -d' ' -f1)                         // Extracts the date from the first entry in the cache file
        if [ "$cached_date" == "$current_date" ]; then                                                       // If the cached date matches today (cache is still valid)
            merged_today=$(echo "$api_today_items" | jq --slurpfile cache "$daily_cache_file" \              // Merges the new API data with the cached data
                '($cache[0] + .) | unique_by(.dt) | sort_by(.dt)')                                           // Combines both arrays, removes duplicates by timestamp, sorts by time
        else                                                                                                 // If the cache is for a different (past) date
            merged_today="$api_today_items"                                                                   // Uses only the fresh API data, ignoring the stale cache
        fi
    else                                                                                                     // If no cache file exists at all
        merged_today="$api_today_items"                                                                       // Uses only the fresh API data
    fi

    echo "$merged_today" > "$daily_cache_file"                                                               // Writes the merged today data to the daily cache file for future rollover use

    # 3. PRE-CACHE TOMORROW                                                                                // Section: saves tomorrow's data for efficient next-day rollover
    api_tomorrow_items=$(echo "$raw_api" | jq -c ".list[] | select(.dt_txt | startswith(\"$tomorrow_date\"))" | jq -s '.') // Filters API response for tomorrow's entries and creates JSON array
    echo "$api_tomorrow_items" > "$next_day_cache_file"                                                       // Saves tomorrow's data to the pre-cache file for tomorrow's rollover check

    # 4. BUILD FINAL JSON                                                                                   // Section: constructs the complete 5-day forecast JSON output
    processed_forecast=$(echo "$raw_api" | jq --argjson today "$merged_today" --arg date "$current_date" \   // Creates a modified API response with today's merged data replacing the original today entries
        '.list = ($today + [.list[] | select(.dt_txt | startswith($date) | not)])')                          // Sets the list to: merged today data + all entries NOT starting with today's date

    if [ ! -z "$processed_forecast" ]; then                                                                   // Checks if the processed forecast data is not empty
        dates=$(echo "$processed_forecast" | jq -r '.list[].dt_txt | split(" ")[0]' | uniq | head -n 5)      // Extracts unique dates from all forecast entries, takes first 5 (today + 4 future days)
        
        final_json="["                                                                                        // Initializes the final JSON array string
        counter=0                                                                                             // Initializes a counter for the forecast day ID
        
        for d in $dates; do                                                                                  // Loops through each unique date in the forecast
            day_data=$(echo "$processed_forecast" | jq "[.list[] | select(.dt_txt | startswith(\"$d\"))]")    // Filters all forecast entries for the current date and creates a JSON array

            raw_max=$(echo "$day_data" | jq '[.[].main.temp_max] | max')                                    // Finds the maximum temperature from all entries for this day
            f_max_temp=$(printf "%.1f" "$raw_max")                                                            // Formats the max temperature to 1 decimal place using C locale for consistent formatting

            raw_min=$(echo "$day_data" | jq '[.[].main.temp_min] | min')                                    // Finds the minimum temperature from all entries for this day
            f_min_temp=$(printf "%.1f" "$raw_min")                                                            // Formats the min temperature to 1 decimal place

            raw_feels=$(echo "$day_data" | jq '[.[].main.feels_like] | max')                                // Finds the maximum feels-like temperature for this day
            f_feels_like=$(printf "%.1f" "$raw_feels")                                                        // Formats feels-like temperature to 1 decimal place

            f_pop=$(echo "$day_data" | jq '[.[].pop] | max')                                                // Finds the maximum probability of precipitation (0-1 scale)
            f_pop_pct=$(echo "$f_pop * 100" | bc | cut -d. -f1)                                              // Converts probability to percentage (multiply by 100) and truncates decimal using bc
            f_wind=$(echo "$day_data" | jq '[.[].wind.speed] | max | round')                                // Finds maximum wind speed and rounds to nearest integer
            f_hum=$(echo "$day_data" | jq '[.[].main.humidity] | add / length | round')                     // Calculates average humidity by summing all values, dividing by count, and rounding
            
            f_code=$(echo "$day_data" | jq -r '.[length/2 | floor].weather[0].icon')                        // Gets the weather icon code from the middle entry (representative for the day)
            f_desc=$(echo "$day_data" | jq -r '.[length/2 | floor].weather[0].description' | sed -e "s/\b\(.\)/\u\1/g") // Gets weather description, capitalizes first letter of each word using sed
            f_icon_data=$(get_icon "$f_code")                                                                 // Calls get_icon function to get icon glyph and quote separated by pipe
            f_icon=$(echo "$f_icon_data" | cut -d'|' -f1)                                                    // Extracts just the icon glyph (first field before the pipe)
            f_hex=$(get_hex "$f_code")                                                                        // Calls get_hex function to get the accent color for this weather code
            
            f_day=$(date -d "$d" "+%a")                                                                       // Formats the date as abbreviated weekday name (e.g., "Mon")
            f_full_day=$(date -d "$d" "+%A")                                                                  // Formats the date as full weekday name (e.g., "Monday")
            f_date_num=$(date -d "$d" "+%d %b")                                                               // Formats the date as day number and abbreviated month (e.g., "15 Jan")

            hourly_json="["                                                                                   // Initializes the hourly forecast array for this day
            count_slots=$(echo "$day_data" | jq '. | length')                                                // Gets the number of 3-hour forecast slots for this day
            count_slots=$((count_slots-1))                                                                    // Decrements by 1 for zero-based loop indexing
            
            for i in $(seq 0 1 $count_slots); do                                                              // Loops through each forecast slot from 0 to count_slots in steps of 1
                slot_item=$(echo "$day_data" | jq ".[$i]")                                                    // Extracts the JSON object for this specific forecast slot
                
                raw_s_temp=$(echo "$slot_item" | jq ".main.temp")                                            // Gets the temperature value for this slot
                s_temp=$(printf "%.1f" "$raw_s_temp")                                                         // Formats slot temperature to 1 decimal place
                
                s_dt=$(echo "$slot_item" | jq ".dt")                                                         // Gets the Unix timestamp for this forecast slot
                s_time=$(date -d @$s_dt "+%H:%M")                                                             // Converts Unix timestamp to HH:MM format
                s_code=$(echo "$slot_item" | jq -r ".weather[0].icon")                                       // Gets the weather icon code for this slot
                s_hex=$(get_hex "$s_code")                                                                     // Gets the hex color for this slot's weather condition
                s_icon=$(get_icon "$s_code" | cut -d'|' -f1)                                                  // Gets just the icon glyph for this slot
                
                hourly_json="${hourly_json} {\"time\": \"${s_time}\", \"temp\": \"${s_temp}\", \"icon\": \"${s_icon}\", \"hex\": \"${s_hex}\"}," // Appends an hourly forecast object to the array string
            done                                                                                              // Ends the hourly forecast loop
            hourly_json="${hourly_json%,}]"                                                                   // Removes trailing comma and closes the hourly JSON array

            final_json="${final_json} {                                                                       // Appends the complete forecast day object to the final array
                \"id\": \"${counter}\",                                                                       // Sets the forecast ID to the current counter value
                \"day\": \"${f_day}\",                                                                        // Sets abbreviated day name
                \"day_full\": \"${f_full_day}\",                                                              // Sets full day name
                \"date\": \"${f_date_num}\",                                                                  // Sets formatted date
                \"max\": \"${f_max_temp}\",                                                                   // Sets maximum temperature
                \"min\": \"${f_min_temp}\",                                                                   // Sets minimum temperature
                \"feels_like\": \"${f_feels_like}\",                                                          // Sets feels-like temperature
                \"wind\": \"${f_wind}\",                                                                      // Sets wind speed
                \"humidity\": \"${f_hum}\",                                                                   // Sets humidity percentage
                \"pop\": \"${f_pop_pct}\",                                                                    // Sets precipitation probability percentage
                \"icon\": \"${f_icon}\",                                                                      // Sets weather icon glyph
                \"hex\": \"${f_hex}\",                                                                        // Sets accent hex color
                \"desc\": \"${f_desc}\",                                                                      // Sets weather description
                \"hourly\": ${hourly_json}                                                                    // Embeds the hourly forecast array
            },"                                                                                               // Closes the day object with trailing comma
            ((counter++))                                                                                     // Increments the ID counter for the next day
        done                                                                                                  // Ends the days loop
        final_json="${final_json%,}]"                                                                         // Removes trailing comma and closes the final JSON array

        echo "{ \"forecast\": ${final_json} }" > "${json_file}"                                               // Wraps array in forecast object and writes complete JSON to output file
    fi
}

# --- MODE HANDLING ---                                                                                     // Section: command-line argument parsing to determine script behavior
if [[ "$1" == "--getdata" ]]; then                                                                           // Checks if the first argument is "--getdata" (force data fetch mode)
    get_data                                                                                                 // Calls the main data fetching function directly

elif [[ "$1" == "--json" ]]; then                                                                            // Checks if first argument is "--json" (standard cache-aware output mode)
    CACHE_LIMIT=900         # 15 minutes for valid working data                                              // Sets cache refresh interval to 900 seconds (15 minutes) when API key is working
    PENDING_RETRY_LIMIT=3600 # 1 hour for invalid/activating keys                                            // Sets retry interval to 3600 seconds (1 hour) when API key is pending/invalid

    if [ -f "$json_file" ]; then                                                                              // Checks if the weather JSON output file exists
        file_time=$(stat -c %Y "$json_file")                                                                  // Gets the last modification time of the JSON file in seconds since epoch
        current_time=$(date +%s)                                                                              // Gets the current time in seconds since epoch
        diff=$((current_time - file_time))                                                                    // Calculates the age of the cache file in seconds
        
        if grep -q '"desc": "No API Key"' "$json_file"; then                                                  // Checks if the JSON contains the "No API Key" dummy data indicator
            # Key is pending/invalid. Check once an hour.                                                    // Comment explaining the retry strategy for invalid keys
            if [ $diff -gt $PENDING_RETRY_LIMIT ]; then                                                       // If the cache is older than 1 hour (3600 seconds)
                touch "$json_file" # Bump file timestamp slightly to avoid spamming processes                 // Updates the file timestamp to prevent multiple simultaneous refresh attempts
                get_data &                                                                                    // Starts data fetch in background (non-blocking) for pending key retry
            fi
        else                                                                                                 // If the JSON contains valid weather data (not dummy)
            # Normal working API key. Check every 15 mins.                                                   // Comment explaining normal refresh strategy
            if [ $diff -gt $CACHE_LIMIT ]; then                                                               // If cache is older than 15 minutes (900 seconds)
                touch "$json_file"                                                                            // Updates file timestamp to prevent race conditions
                get_data &                                                                                    // Starts background data refresh
            fi
        fi
        cat "$json_file"                                                                                      // Outputs the current cache content to stdout (always, regardless of refresh)
    else                                                                                                     // If the JSON file doesn't exist at all
        get_data                                                                                              // Performs synchronous data fetch to create the initial cache
        cat "$json_file"                                                                                      // Outputs the newly created cache content
    fi

elif [[ "$1" == "--view-listener" ]]; then                                                                   // Checks if first argument is "--view-listener" (monitors view_id file changes)
    if [ ! -f "$view_file" ]; then echo "0" > "$view_file"; fi                                                // Creates the view_id file with initial value "0" if it doesn't exist
    tail -F "$view_file"                                                                                      // Follows the view_id file, outputting new lines as they're appended (used for IPC)

elif [[ "$1" == "--nav" ]]; then                                                                             // Checks if first argument is "--nav" (navigation between forecast days)
    if [ ! -f "$view_file" ]; then echo "0" > "$view_file"; fi                                                // Creates view_id file with "0" if missing
    current=$(cat "$view_file")                                                                               // Reads the current view index from the file
    direction=$2                                                                                              // Gets the navigation direction from second argument ("next" or "prev")
    max_idx=4                                                                                                 // Sets maximum view index to 4 (5 days total: 0-4)
    if [[ "$direction" == "next" ]]; then                                                                     // If navigating forward
        if [ "$current" -lt "$max_idx" ]; then                                                                // If current index is less than maximum
            new=$((current + 1))                                                                              // Increments the view index
            echo "$new" > "$view_file"                                                                        // Writes new index to the view_id file
        fi
    elif [[ "$direction" == "prev" ]]; then                                                                   // If navigating backward
        if [ "$current" -gt 0 ]; then                                                                         // If current index is greater than 0
            new=$((current - 1))                                                                              // Decrements the view index
            echo "$new" > "$view_file"                                                                        // Writes new index to the view_id file
        fi
    fi

elif [[ "$1" == "--icon" ]]; then                                                                            // Checks if first argument is "--icon" (output today's weather icon)
    cat "$json_file" | jq -r '.forecast[0].icon'                                                              // Extracts and outputs the icon glyph for the first forecast day (today)

elif [[ "$1" == "--temp" ]]; then                                                                            // Checks if first argument is "--temp" (output today's max temperature)
    t=$(cat "$json_file" | jq -r '.forecast[0].max')                                                          // Extracts the max temperature value for today
    echo "${t}°C"                                                                                             // Outputs temperature with degree Celsius suffix

elif [[ "$1" == "--hex" ]]; then                                                                             // Checks if first argument is "--hex" (output today's accent color)
    cat "$json_file" | jq -r '.forecast[0].hex'                                                               // Extracts and outputs the hex color for today's weather

# --- NEW HOURLY MODES FOR TOPBAR ---                                                                        // Section: modes specifically for showing current-hour weather in the top bar
elif [[ "$1" == "--current-icon" ]]; then                                                                    // Checks for "--current-icon" mode (icon for the closest hourly slot to current time)
    curr_time=$(date +%H:%M)                                                                                  // Gets current time in HH:MM format
    cat "$json_file" | jq -r --arg ct "$curr_time" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .icon' // Finds the hourly slot with time <= current time, or falls back to first slot; outputs its icon

elif [[ "$1" == "--current-temp" ]]; then                                                                    // Checks for "--current-temp" mode (temperature for current hour)
    curr_time=$(date +%H:%M)                                                                                  // Gets current time
    t=$(cat "$json_file" | jq -r --arg ct "$curr_time" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .temp') // Finds matching hourly slot temperature
    echo "${t}°C"                                                                                             // Outputs temperature with Celsius suffix

elif [[ "$1" == "--current-hex" ]]; then                                                                     // Checks for "--current-hex" mode (accent color for current hour)
    curr_time=$(date +%H:%M)                                                                                  // Gets current time
    cat "$json_file" | jq -r --arg ct "$curr_time" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .hex' // Finds matching hourly slot hex color
fi                                                                                                           // Ends the if-elif chain for mode handling