param(
    [string]$BaseUrl = "http://127.0.0.1:8080"
)

$ErrorActionPreference = "Stop"
$ApiBase = "$BaseUrl/api/v1"

function Invoke-Json {
    param(
        [string]$Method,
        [string]$Url,
        [object]$Body = $null,
        [hashtable]$Headers = @{}
    )

    $params = @{
        Method = $Method
        Uri = $Url
        Headers = $Headers
    }
    if ($null -ne $Body) {
        $params.ContentType = "application/json"
        $params.Body = ($Body | ConvertTo-Json -Compress)
    }
    Invoke-RestMethod @params
}

Invoke-RestMethod "$BaseUrl/health" | Out-Null

$login = Invoke-Json -Method "POST" -Url "$ApiBase/auth/login" -Body @{
    identifier = "demo_user"
    password = "demo123456"
}
$token = $login.data.token
if (-not $token) {
    throw "Login did not return a token."
}

$headers = @{ Authorization = "Bearer $token" }
$me = Invoke-Json -Method "GET" -Url "$ApiBase/auth/me" -Headers $headers
if ($me.data.user.username -ne "demo_user") {
    throw "Authenticated /auth/me did not return demo_user."
}

$badPasswordFailed = $false
try {
    Invoke-Json -Method "POST" -Url "$ApiBase/auth/login" -Body @{
        identifier = "demo_user"
        password = "wrong-password"
    } | Out-Null
} catch {
    $badPasswordFailed = $_.Exception.Response.StatusCode.value__ -eq 401
}
if (-not $badPasswordFailed) {
    throw "Wrong password login did not fail with 401."
}

Invoke-Json -Method "POST" -Url "$ApiBase/auth/logout" -Headers $headers | Out-Null

$logoutRevokedToken = $false
try {
    Invoke-Json -Method "GET" -Url "$ApiBase/auth/me" -Headers $headers | Out-Null
} catch {
    $logoutRevokedToken = $_.Exception.Response.StatusCode.value__ -eq 401
}
if (-not $logoutRevokedToken) {
    throw "Revoked token still authenticated after logout."
}

Write-Host "Auth smoke test passed."
