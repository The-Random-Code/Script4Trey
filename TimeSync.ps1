# Define the URI for the API
$uri = "http://worldclockapi.com/api/json/utc/now"

# Function to fetch the correct time from the API. Going to be called in while loop.
function Get-CorrectTime {
    # Send the API request and get the response
    $response = Invoke-RestMethod -Uri $uri -Method Get

    # Grab the currentFileTime. I'm doing it this way because the formatting of the other members would require parsing output and,
    # more problematically, I'd have to account for a bunch of single digit months and days if I started parsing through this stuff.
    $currentFileTime = $response.currentFileTime

    # Convert the file time to DateTime. Making it a string so I can use basic -eq or -ne operators. Makes it easy.
    return ([System.DateTime]::FromFileTime($currentFileTime) | Out-String).trim()
}

# Function to get the local time in the desired format. Going to be called in while loop.
function Get-MyTime {
    # Get my Time, making sure that the formatting of this is identical to the $CorrectTime string.
    return (Get-Date -Format "dddd, MMMM d, yyyy h:mm:ss tt" | Out-String).trim()
}

# Initialize the values
$CorrectTime = Get-CorrectTime
$MyTime = Get-MyTime

# The overarching logic is to compare the time of my computer with the "correct date" (pulled from a time site using an API call)
# until the computer and the "correct date" are in agreement, at which point we will exit the while loop.
while ($MyTime -ne $CorrectTime) {

    # Restart the Windows Time service
    Restart-Service -Name w32time -Force

    # Force time synchronization using w32tm
    Start-Process -FilePath "w32tm" -ArgumentList "/resync /force" -NoNewWindow -Wait

    # Re-Initalize the values after the sync attempt
    $CorrectTime = Get-CorrectTime
    $MyTime = Get-MyTime

    # Add a delay to avoid hammering the API or system
    Start-Sleep -Seconds 5
}
