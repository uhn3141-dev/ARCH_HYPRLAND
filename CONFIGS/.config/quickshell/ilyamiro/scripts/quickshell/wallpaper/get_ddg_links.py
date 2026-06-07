# #!/usr/bin/env python3
# import sys, json, time, re, os
# import urllib.request, urllib.parse, http.cookiejar

# LOG_FILE = "/tmp/qs_python_scraper.log"
# CONTROL_FILE = "/tmp/ddg_search_control"

# def log(msg):
#     try:
#         with open(LOG_FILE, "a") as f:
#             f.write(f"{time.strftime('%H:%M:%S')} - {msg}\n")
#     except:
#         pass

# def get_state():
#     try:
#         with open(CONTROL_FILE, "r") as f:
#             return f.read().strip()
#     except:
#         return "run"

# def main():
#     log("=== NEW SEARCH STARTING (Safe Search: OFF) ===")
#     if len(sys.argv) < 2: 
#         log("ERROR: No query provided.")
#         return
        
#     query = sys.argv[1].strip() + " wallpaper"
#     log(f"Query: '{query}'")
    
#     cj = http.cookiejar.CookieJar()
#     opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
#     urllib.request.install_opener(opener)

#     headers = {
#         "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
#         "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
#         "Accept-Language": "en-US,en;q=0.5",
#         "Referer": "https://duckduckgo.com/"
#     }

#     search_url = f"https://duckduckgo.com/?q={urllib.parse.quote(query)}&iar=images&iax=images&ia=images&kp=-1"
#     vqd = None

#     log(f"Fetching VQD token from: {search_url}")
#     for i in range(3):
#         try:
#             req = urllib.request.Request(search_url, headers=headers)
#             html = urllib.request.urlopen(req, timeout=10).read().decode("utf-8")
#             match = re.search(r'vqd=([0-9a-zA-Z_-]+)', html) or re.search(r'vqd[\'"]?\s*:\s*[\'"]?([0-9a-zA-Z_-]+)', html)
            
#             if match: 
#                 vqd = match.group(1)
#                 log(f"Success! Found VQD token: {vqd}")
#                 break
#             else:
#                 log(f"Attempt {i+1}: No VQD found in HTML.")
#         except Exception as e: 
#             log(f"Attempt {i+1} Network Error: {str(e)}")
#             time.sleep(1)

#     if not vqd: 
#         log("CRITICAL ERROR: Failed to get VQD token. Exiting.")
#         return

#     headers["Referer"] = search_url
#     headers["Accept"] = "application/json, text/javascript, */*; q=0.01"

#     next_url = None
#     links_found = 0
    
#     for page in range(5): 
#         # Check state before making the next HTTP request
#         state = get_state()
#         if state == "stop":
#             log("Stop signal detected. Exiting cleanly.")
#             break
            
#         while state == "pause":
#             time.sleep(1)
#             state = get_state()

#         log(f"Fetching JSON page {page + 1}...")

#         params = {
#             "l": "us-en",
#             "o": "json",
#             "q": query,
#             "vqd": vqd,
#             "f": ",,,",
#             "p": "-1",
#             "ex": "-1"
#         }

#         if next_url:
#             url = "https://duckduckgo.com" + next_url
#             if "p=-1" not in url: url += "&p=-1"
#             if "vqd=" not in url: url += f"&vqd={vqd}"
#         else:
#             url = "https://duckduckgo.com/i.js?" + urllib.parse.urlencode(params)

#         try:
#             req = urllib.request.Request(url, headers=headers)
#             # Catch HTTP errors specifically so token expiry doesn't crash us violently
#             response = urllib.request.urlopen(req, timeout=10)
#             data = json.loads(response.read().decode("utf-8"))
#             results = data.get("results", [])
#             log(f"Successfully parsed JSON. Found {len(results)} raw image results.")
            
#             for res in results:
#                 width = int(res.get("width", 0))
#                 height = int(res.get("height", 0))
#                 if width >= 1920 and height >= 1080:
#                     t, i = res.get("thumbnail"), res.get("image")
#                     if t and i:
#                         try:
#                             sys.stdout.write(f"{t}|{i}\n")
#                             sys.stdout.flush()
#                             links_found += 1
#                         except BrokenPipeError:
#                             log("Broken pipe detected. Bash script stopped listening. Exiting.")
#                             os._exit(0) 
            
#             next_url = data.get("next")
#             if not next_url: 
#                 log("No 'next' URL provided by DDG.")
#                 break
                
#         except BrokenPipeError:
#             os._exit(0)
#         except Exception as e: 
#             log(f"Error fetching page {page + 1}: {str(e)}. Assuming session expired or blocked.")
#             break
            
#     log(f"=== SEARCH COMPLETE. Total FHD links: {links_found} ===")

# if __name__ == "__main__": 
#     try: os.remove(LOG_FILE)
#     except: pass
    
#     try:
#         main()
#         sys.stdout.flush()
#     except BrokenPipeError:
#         os._exit(0)
#     except KeyboardInterrupt:
#         os._exit(1)
#     except Exception as e:
#         log(f"FATAL: {str(e)}")
#         os._exit(1)
#!/usr/bin/env python3                                                           # Shebang line: uses env to find python3 interpreter for portability across systems
import sys, json, time, re, os                                                   # Imports: sys for exit/args, json for parsing, time for sleep/logging, re for regex, os for file ops
import urllib.request, urllib.parse, http.cookiejar                               # Imports: urllib.request for HTTP requests, urllib.parse for URL encoding, http.cookiejar for cookie handling

LOG_FILE = "/tmp/qs_python_scraper.log"                                           # Defines path to log file for debugging the Python scraping process
CONTROL_FILE = "/tmp/ddg_search_control"                                          # Defines path to the control file used for pause/stop signaling between processes

def log(msg):                                                                     # Helper function that appends timestamped messages to the log file
    try:                                                                          # Try block to handle potential file write errors gracefully
        with open(LOG_FILE, "a") as f:                                            # Opens log file in append mode
            f.write(f"{time.strftime('%H:%M:%S')} - {msg}\n")                     # Writes timestamp (HH:MM:SS format) followed by the message and newline
    except:                                                                       # Silently catches any file write exceptions (disk full, permissions, etc.)
        pass                                                                      # Does nothing on error to prevent logging failures from crashing the scraper

def get_state():                                                                  # Function that reads the current control state from the control file
    try:                                                                          # Try block for file reading
        with open(CONTROL_FILE, "r") as f:                                        # Opens control file in read mode
            return f.read().strip()                                               # Returns the file contents with leading/trailing whitespace removed
    except:                                                                       # Catches FileNotFoundError or any other read error
        return "run"                                                              # Returns "run" as default state if file doesn't exist or can't be read

def main():                                                                       # Main function that orchestrates the DuckDuckGo image scraping process
    log("=== NEW SEARCH STARTING (Safe Search: OFF) ===")                          # Logs search start marker indicating safe search is disabled for maximum results
    if len(sys.argv) < 2:                                                         # Checks if a search query was provided as command-line argument
        log("ERROR: No query provided.")                                          # Logs error if no query argument
        return                                                                    # Exits the function early
        
    query = sys.argv[1].strip() + " wallpaper"                                     # Takes the first argument, strips whitespace, and appends " wallpaper" to focus image results
    log(f"Query: '{query}'")                                                       # Logs the final search query being used
    
    cj = http.cookiejar.CookieJar()                                                # Creates a CookieJar object to store and manage cookies across requests
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))   # Builds a URL opener with cookie processing enabled for session persistence
    urllib.request.install_opener(opener)                                          # Installs the cookie-aware opener as the default for all urllib requests

    headers = {                                                                   # Defines HTTP headers to mimic a real browser and avoid blocking
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", # Chrome 120 on Windows 10 user agent string
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8", # Accept header indicating supported content types with quality preferences
        "Accept-Language": "en-US,en;q=0.5",                                       # Prefers US English, accepts any English at lower priority
        "Referer": "https://duckduckgo.com/"                                       # Sets referer to DuckDuckGo homepage to appear as a legitimate navigation
    }

    search_url = f"https://duckduckgo.com/?q={urllib.parse.quote(query)}&iar=images&iax=images&ia=images&kp=-1" # Constructs the DDG image search URL with URL-encoded query and image-specific parameters (kp=-1 disables safe search)
    vqd = None                                                                     # Initializes the VQD token variable (required by DDG API for subsequent requests)

    log(f"Fetching VQD token from: {search_url}")                                  # Logs the attempt to fetch the VQD token
    for i in range(3):                                                            # Retries up to 3 times to get the VQD token (handles network issues)
        try:                                                                      # Try block for the HTTP request
            req = urllib.request.Request(search_url, headers=headers)              # Creates a GET request to the search URL with browser headers
            html = urllib.request.urlopen(req, timeout=10).read().decode("utf-8")  # Fetches the HTML page with 10-second timeout, reads and decodes as UTF-8
            match = re.search(r'vqd=([0-9a-zA-Z_-]+)', html) or re.search(r'vqd[\'"]?\s*:\s*[\'"]?([0-9a-zA-Z_-]+)', html) # Searches for VQD token in URL parameter format or JavaScript object format
            
            if match:                                                              # If a VQD token was found in the HTML
                vqd = match.group(1)                                               # Extracts the captured VQD token string from the regex match
                log(f"Success! Found VQD token: {vqd}")                           # Logs successful token extraction
                break                                                              # Exits the retry loop since we have the token
            else:                                                                  # If no VQD found in this attempt
                log(f"Attempt {i+1}: No VQD found in HTML.")                      # Logs the failed attempt number
        except Exception as e:                                                     # Catches any network or parsing error
            log(f"Attempt {i+1} Network Error: {str(e)}")                         # Logs the specific error
            time.sleep(1)                                                         # Waits 1 second before retrying

    if not vqd:                                                                    # If after all retries no VQD token was obtained
        log("CRITICAL ERROR: Failed to get VQD token. Exiting.")                   # Logs critical failure
        return                                                                     # Exits the function (no point continuing without token)

    headers["Referer"] = search_url                                                # Updates Referer header to the search URL for API requests
    headers["Accept"] = "application/json, text/javascript, */*; q=0.01"           # Updates Accept header to expect JSON responses from the API

    next_url = None                                                                # Initializes the pagination URL variable (None for first page)
    links_found = 0                                                                # Counter for total high-resolution image links found
    
    for page in range(5):                                                          # Iterates through up to 5 pages of image results
        # Check state before making the next HTTP request                            # Comment explaining control state check
        state = get_state()                                                        # Reads the current control file state
        if state == "stop":                                                        # If stop signal detected
            log("Stop signal detected. Exiting cleanly.")                          # Logs the clean exit
            break                                                                  # Breaks out of the page loop
            
        while state == "pause":                                                    # If pause signal detected, loop until it changes
            time.sleep(1)                                                          # Sleeps 1 second to avoid CPU spinning
            state = get_state()                                                    # Re-reads the control state

        log(f"Fetching JSON page {page + 1}...")                                   # Logs which page is being fetched

        params = {                                                                 # Base query parameters for the DDG image API
            "l": "us-en",                                                         # Locale: US English
            "o": "json",                                                          # Output format: JSON
            "q": query,                                                           # Search query string
            "vqd": vqd,                                                           # The VQD token obtained earlier
            "f": ",,,",                                                           # Filter parameter (empty filters)
            "p": "-1",                                                            # Safe search: -1 (off)
            "ex": "-1"                                                            # Extra parameter
        }

        if next_url:                                                               # If we have a pagination URL from previous page
            url = "https://duckduckgo.com" + next_url                              # Constructs full URL with DDG domain prefix
            if "p=-1" not in url: url += "&p=-1"                                    # Ensures safe search off parameter is included
            if "vqd=" not in url: url += f"&vqd={vqd}"                              # Ensures VQD token is included in the URL
        else:                                                                      # For the first page (no pagination URL yet)
            url = "https://duckduckgo.com/i.js?" + urllib.parse.urlencode(params)   # Constructs the initial API URL with encoded query parameters

        try:                                                                       # Try block for fetching and parsing the JSON response
            req = urllib.request.Request(url, headers=headers)                      # Creates GET request with the constructed URL and headers
            # Catch HTTP errors specifically so token expiry doesn't crash us violently # Comment explaining error handling approach
            response = urllib.request.urlopen(req, timeout=10)                      # Fetches the API response with 10-second timeout
            data = json.loads(response.read().decode("utf-8"))                      # Reads response bytes, decodes as UTF-8, parses as JSON
            results = data.get("results", [])                                       # Extracts the "results" array from JSON, defaults to empty list
            log(f"Successfully parsed JSON. Found {len(results)} raw image results.") # Logs the number of raw results received
            
            for res in results:                                                    # Iterates through each image result
                width = int(res.get("width", 0))                                   # Gets image width as integer, defaults to 0 if missing
                height = int(res.get("height", 0))                                 # Gets image height as integer, defaults to 0
                if width >= 1920 and height >= 1080:                               # Only processes full HD or larger images (1920x1080 minimum)
                    t, i = res.get("thumbnail"), res.get("image")                   # Gets both the thumbnail URL and full image URL
                    if t and i:                                                    # If both thumbnail and image URLs exist
                        try:                                                       # Try block for writing to stdout (pipe to bash)
                            sys.stdout.write(f"{t}|{i}\n")                         # Writes thumbnail and image URLs separated by pipe to stdout
                            sys.stdout.flush()                                     # Immediately flushes the output buffer so bash reads it in real-time
                            links_found += 1                                       # Increments the counter of qualifying links found
                        except BrokenPipeError:                                    # Catches the error when bash stops reading (pipe broken)
                            log("Broken pipe detected. Bash script stopped listening. Exiting.") # Logs the broken pipe
                            os._exit(0)                                            # Immediately exits the process with success code
            next_url = data.get("next")                                            # Gets the pagination URL for the next page of results from the JSON response
            if not next_url:                                                        # If no next URL is provided by DuckDuckGo
                log("No 'next' URL provided by DDG.")                               # Logs that pagination has ended
                break                                                               # Exits the page loop (no more pages available)
                
        except BrokenPipeError:                                                     # Catches broken pipe at the outer request level too
            os._exit(0)                                                             # Immediately exits cleanly if bash stopped listening
        except Exception as e:                                                      # Catches any other error (HTTP errors, JSON parse errors, etc.)
            log(f"Error fetching page {page + 1}: {str(e)}. Assuming session expired or blocked.") # Logs the error and assumes session is no longer valid
            break                                                                   # Breaks out of page loop on error
            
    log(f"=== SEARCH COMPLETE. Total FHD links: {links_found} ===")                # Logs search completion with total count of full HD image links found

if __name__ == "__main__":                                                          # Standard Python idiom: only executes when script is run directly (not imported)
    try: os.remove(LOG_FILE)                                                        # Attempts to delete the old log file for clean start
    except: pass                                                                    # Silently ignores if file doesn't exist or can't be deleted
    
    try:                                                                            # Outer try block for the entire main execution
        main()                                                                      # Calls the main scraping function
        sys.stdout.flush()                                                          # Final flush of any remaining stdout data
    except BrokenPipeError:                                                         # Catches broken pipe at top level
        os._exit(0)                                                                 # Clean exit if pipe broken
    except KeyboardInterrupt:                                                       # Catches Ctrl+C signal from user
        os._exit(1)                                                                 # Exits with error code 1 for user interrupt
    except Exception as e:                                                          # Catches any other unhandled exception
        log(f"FATAL: {str(e)}")                                                     # Logs the fatal error
        os._exit(1)                                                                 # Exits with error code 1 for fatal errors