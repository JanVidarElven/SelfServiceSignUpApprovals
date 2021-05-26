using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request for Checking Approval Status for External Identities Self Service Sign-up."


# For Debugging Purpose, list the complete Request Body received by the API
$Request.Body | ConvertTo-Json

# Interact with body parameters of the request.
$email = $Request.Body.email
$givenName = $Request.Body.givenName
$surName = $Request.Body.surName
$displayName = $Request.Body.displayName
$ui_locales = $Request.Body.ui_locales
$issuer = $Request.Body.identities.issuer
$signInType = $Request.Body.identities.signInType
$issuerAssignedId = $Request.Body.identities.issuerAssignedId

# Build the check approval status body
$checkApprovalStatusBody = @"
{
    "email": "$email",
    "displayName": "$displayName",
    "givenName": "$givenName",
    "surName": "$surName",
    "issuer": "$issuer",
    "signInType": "$signInType",
    "issuerAssignedId": "$issuerAssignedId",
    "ui_locales": "$ui_locales"
}
"@

# Calling Custom Approval System and get approval status returned
#$uri = "https://prod-77.westeurope.logic.azure.com:443/workflows/99bc48ad76bd4d4fbd88674a3a5ed52c/triggers/request/paths/invoke?api-version=2016-10-01"

#$approvalStatus = Invoke-RestMethod -Uri $uri -Method POST -Body $checkApprovalStatusBody -ContentType "application/json"

$approvalStatus = "Accepted" # Rejected | Pending

If ($approvalStatus -eq "Accepted") {
    $responseBody = @"
    {
        "version": "1.0.0",
        "action": "Continue"
    }
"@
} 
elseif ($approvalStatus -eq "Rejected" ) {
    $responseBody = @"
    {
        "version": "1.0.0",
        "action": "ShowBlockPage",
        "userMessage": "Your sign up request has been denied. Please contact an administrator if you believe this is an error."
    }
"@    
} 
elseif ($approvalStatus -eq "Pending" ) {
    $responseBody = @"
    {
        "version": "1.0.0",
        "action": "ShowBlockPage",
        "userMessage": "Your access request is already processing. You'll be notified when your request has been approved."
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

