$DiscordURI = "YOUR DISCORD WEBHOOK URL"
$EmailFrom = "YOUR SENDING EMAIL ADDRESS (CAN BE THE SAME AS BELOW)"
$EmailTo = "YOUR RECEIVING EMAIL ADDRESS (CAN BE THE SAME AS ABOVE)"
$NAME = "YOUR NAME"
$SMTP = "YOUR EMAIL PROVIDERS SMTP ADDRESS"
$USERNAME = "YOUR CORE-POOL USERNAME"
$Password = "YOUR CORE-POOL PASSWORD"
$NotificationFrequencyInSeconds = 240

#### DO NOT EDIT BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING ####

$SecondsToMinutes = ($NotificationFrequencyInSeconds / 60) 

$from = new-object System.Net.Mail.MailAddress($EmailFrom, "Chia Farmer Alerts")

$mailParamsOffline = @{
Body = 'Please check the status of your farmer by clicking the link to login at <a href= https://core-pool.com>Core-Pool</a>.'
To = $EmailTo
from = $from
Subject = 'Your Chia Farmer Is Offline!'
smtpserver = $SMTP
}

$mailParamsOnline = @{
body = 'No need to panic, your farmer is back online.'
to = $EmailTo
from = $from
subject = 'Your Chia Farmer Is Back Online!'
smtpserver = $SMTP
}
 
$Body = @{
username = $USERNAME
password = $Password
}
$LoginResponse = Invoke-WebRequest 'https://core-pool.com/login' -SessionVariable websession -Body $Body -Method 'POST'
$ProfileResponse = Invoke-WebRequest 'https://core-pool.com/dashboard' -WebSession $websession
do
{    
$HTML = Invoke-RestMethod https://core-pool.com/dashboard -WebSession $websession
if ($HTML -match '<div class="badge badge-primary badge-success">Online</div>' -eq "True")
{
$state = "Online"
}
elseif ($HTML -match '<div class="badge badge-primary badge-danger">Offline</div>' -eq "True")
{
$state = "Offline"
$payload = [PSCustomObject]@{content = "<a:redalert:835994375556300822>  Uh Oh $NAME, Your Farmer Is Offline, I Will Update Your Farmer Status In $SecondsToMinutes Minutes.  <a:redalert:835994375556300822>"} | ConvertTo-Json
Invoke-RestMethod -Method Post -ContentType 'application/json'-Body $payload -uri $DiscordURI
Send-MailMessage @mailParamsOffline -BodyAsHTML
Sleep -Seconds $NotificationFrequencyInSeconds
}
while($state -eq "Offline")
{
$HTML = Invoke-RestMethod https://core-pool.com/dashboard -WebSession $websession
if ($HTML -match '<div class="badge badge-primary badge-danger">Offline</div>' -eq "True")
{
$state = "Offline"
$payload = [PSCustomObject]@{content = "<a:redalert:835994375556300822>  Uh Oh $NAME, Your Farmer Is Offline, I Will Update Your Farmer Status In $SecondsToMinutes Minutes.  <a:redalert:835994375556300822>"} | ConvertTo-Json
Invoke-RestMethod -Method Post -ContentType 'application/json'-Body $payload -uri $DiscordURI
Sleep -Seconds $NotificationFrequencyInSeconds
}
elseif ($HTML -match '<div class="badge badge-primary badge-success">Online</div>' -eq "True")
{
$state = "Online"
$payload = [PSCustomObject]@{content = "Hey $NAME, Your Farmer Is Back Online. No Need To Worry."} | ConvertTo-Json 
Invoke-RestMethod -Method Post -ContentType 'application/json'-Body $payload -uri $DiscordURI
Send-MailMessage @mailParamsOnline -BodyAsHTML
}
}
Sleep -Seconds 30
}
until(1 -ne 1)
