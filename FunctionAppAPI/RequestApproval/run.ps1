using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Get Authorization Header and Split to get Header Vakue
$authHeader = $Request.Headers.Authorization
If ($authHeader) {
    $authValue = $authHeader.Split(" ")

    # If Basic Authentication, Get and Decode Base64 String
    If ($authValue[0] = "Basic") {
        $decodedCreds = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($authValue[1]))
        $basicCreds = $decodedCreds.Split(":")
        Write-Host "UserName: " $basicCreds[0]
        Write-Host "Password: " $basicCreds[1]
        # Optional add logic to verify basic credentials to proceed:::
    }
}

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request for Requesting Approval for External Identities Self Service Sign-up."

# For Debugging Purpose, list the complete Request Body received by the API
$Request.Body | ConvertTo-Json

# Interact with body parameters of the request.
$email = $Request.Body.email
$displayName = $Request.Body.displayName
$givenName = $Request.Body.givenName
$surName = $Request.Body.surname
$ui_locales = $Request.Body.ui_locales
$country = $Request.Body.country
$jobTitle = $Request.Body.jobTitle
$company = $Request.Body.extension_df0dc65aa031498fb25e7a1b15c8650b_Company

$issuer = $Request.Body.identities[0].issuer
$signInType = $Request.Body.identities[0].signInType
$issuerAssignedId = $Request.Body.identities[0].issuerAssignedId

$requestApprovalBody = @"
{
    "email": "$email",
    "displayName": "$displayName",
    "givenName": "$givenName",
    "surName": "$surName",
    "issuer": "$issuer",
    "signInType": "$signInType",
    "issuerAssignedId": "$issuerAssignedId",
    "country": "$country",
    "jobTitle": "$jobTitle",
    "company": "$company",
    "ui_locales": "$ui_locales"
}
"@

# Calling Custom Approval System and get approval status returned
#$uri = "https://prod-215.westeurope.logic.azure.com:443/workflows/f43f00de59d44dd98c0c56b39b78dff2/triggers/request/paths/invoke?api-version=2016-10-01"

#$requestApprovalResponse = Invoke-RestMethod -Uri $uri -Method POST -Body $requestApprovalBody -ContentType "application/json"

$requestApprovalResponse = "Approved" # Rejected | Pending

If ($requestApprovalResponse -eq "Approved") {
    $responseBody = @"
    {
    "version": "1.0.0",
    "action": "Continue"
    }
"@
} 
elseif ($requestApprovalResponse -eq "Rejected" ) {
    $responseBody = @"
    {
        "version": "1.0.0",
        "action": "ShowBlockPage",
        "userMessage": "Your sign up request has been denied. Please contact an administrator if you believe this is an error",
    }
"@    
} 
elseif ($requestApprovalResponse -eq "Pending" ) {
    $responseBody = @"
    {
        "version": "1.0.0",
        "action": "ShowBlockPage",
        "userMessage": "Your account is now waiting for approval. You'll be notified when your request has been approved.",
    }
"@    
}
else {
    $responseBody = @"
    {
    "version": "1.0.0",
    "action": "ShowBlockPage",
    "userMessage": "Unknown error. Contact administrator."
    }
"@
}


$contentType = "application/json"

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $responseBody
    ContentType = $contentType
})
