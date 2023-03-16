<# 
.SYNOPSIS
    RingCentral API Query using "JWT auth flow" in Powershell

.DESCRIPTION 
    This script gets an authorization token that you use with API Queries
 
.NOTES 
    This requires an App on https://developers.ringcentral.com with the authentication method "JWT auth flow"

.LINK 
    Useful Link to ressources or others.

.Parameter JWT
    JWT Credential from https://developers.ringcentral.com/console/my-credentials

.Parameter Server 
    API Server URL. Used to switch between the Sandbox and Production Environment.
#>

#RingCentrals "JWT auth flow"
#Change these values 
$clientID     = ''
$clientSecret = ''
$JWT          = ''
$server       = 'https://platform.devtest.ringcentral.com/'
###################################################################################################################
#Gets authorization token that you use with API Queries
$clientCredsPlainText = '{0}:{1}' -f $clientID,$clientSecret
$clientCredsBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($clientCredsPlainText))

$invokeRestMethodSplat = @{
    Uri         = '{0}/restapi/oauth/token' -f $server 
    ContentType = 'application/x-www-form-urlencoded'
    Body        = @{
                    grant_type = 'urn:ietf:params:oauth:grant-type:jwt-bearer'
                    assertion = $JWT
    }
    Headers     = @{
                    Authorization = 'Basic {0}' -f $ClientCredsBase64
    }
    Method      = 'Post'
}
$token = Invoke-RestMethod @invokeRestMethodSplat
$authorizationToken = '{0} {1}' -f $token.token_type,$token.access_token
###################################################################################################################
Function Get-APIQuery{
    param(
        $URI, 
        $Parameters,
        $authorization
    )
    $RequestParameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    ForEach($Key in $Parameters.Keys){
        $RequestParameters.Add($Key,$Parameters[$Key])
    }
    $Request = [System.UriBuilder]$URI
    $Request.Query = $RequestParameters.ToString()
    $query = Invoke-RestMethod -Uri $Request.uri -Headers @{'Authorization' = $authorization}

    $RequestParameters.Add('page',0)
    $totalPages = $query.paging.totalPages
    For ($page=1; $page -le $totalPages; $page++) {
        $RequestParameters['page'] = $page
        $Request.Query = $RequestParameters.ToString()
	    $query = Invoke-RestMethod -Uri $Request.uri -Headers @{'Authorization' = $authorization}
        $query.records
    }
}
###################################################################################################################
#Query Example
$getAPIQuerySplat= @{
    URI = '{0}/restapi/v1.0/account/~/extension' -f $server
    #Parameters = @{'view'='Detailed'} #Example of Parameters
    Authorization = $authorizationToken
}
$extensionRecords = Get-APIQuery @getAPIQuerySplat

#Output Example
$extensionRecords | Select-Object name,type,@{n='extension';e='extensionNumber'},@{n='email';e={$_.contact.email}} | Sort-Object type,name
