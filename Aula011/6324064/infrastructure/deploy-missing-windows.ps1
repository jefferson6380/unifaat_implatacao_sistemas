param(
  [string]$ProjectRoot = "$(Join-Path $PSScriptRoot '..')"
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Message) {
  Write-Output "==> $Message"
}

function Invoke-AwsText {
  param(
    [string]$Description,
    [string[]]$AwsArgs
  )

  $raw = & aws @AwsArgs 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "Falha em '$Description': $raw"
  }

  return (($raw | Out-String).Trim())
}

function Try-Aws {
  param([string[]]$AwsArgs)
  $raw = & aws @AwsArgs 2>&1
  return [pscustomobject]@{
    ExitCode = $LASTEXITCODE
    Output = (($raw | Out-String).Trim())
  }
}

function Get-KeyValueMap([string]$Path) {
  $map = @{}
  Get-Content $Path | ForEach-Object {
    if ($_ -match '^(.*?)=(.*)$') {
      $map[$matches[1]] = $matches[2]
    }
  }
  return $map
}

function Save-KeyValueMap([string]$Path, [hashtable]$Map) {
  $order = @(
    'AWS_ACCOUNT_ID',
    'AWS_REGION',
    'WEBSITE_BUCKET',
    'ASSETS_BUCKET',
    'LOGS_BUCKET',
    'S3_WEBSITE_URL',
    'CLOUDFRONT_DISTRIBUTION_ID',
    'CLOUDFRONT_DOMAIN',
    'CLOUDFRONT_STATUS',
    'DYNAMODB_TABLE',
    'API_GATEWAY_ID',
    'CONTACT_API_URL',
    'UPLOAD_API_URL',
    'GALLERY_API_URL',
    'LAMBDA_CONTACT',
    'LAMBDA_UPLOAD',
    'LAMBDA_IMAGE'
  )

  $lines = @()
  foreach ($k in $order) {
    if ($Map.ContainsKey($k)) {
      $lines += "$k=$($Map[$k])"
    }
  }

  Set-Content -Path $Path -Value $lines -Encoding ascii
}

function Ensure-DynamoTable([string]$TableName, [string]$Region) {
  $probe = Try-Aws -AwsArgs @('dynamodb','describe-table','--table-name',$TableName,'--region',$Region,'--query','Table.TableStatus','--output','text')
  if ($probe.ExitCode -ne 0) {
    Invoke-AwsText -Description 'create dynamodb table' -AwsArgs @(
      'dynamodb','create-table',
      '--table-name',$TableName,
      '--attribute-definitions','AttributeName=pk,AttributeType=S',
      '--key-schema','AttributeName=pk,KeyType=HASH',
      '--billing-mode','PAY_PER_REQUEST',
      '--region',$Region
    ) | Out-Null

    Invoke-AwsText -Description 'wait dynamodb table' -AwsArgs @('dynamodb','wait','table-exists','--table-name',$TableName,'--region',$Region) | Out-Null
  }

  $ttlTry = Try-Aws -AwsArgs @(
    'dynamodb','update-time-to-live',
    '--table-name',$TableName,
    '--time-to-live-specification','Enabled=true,AttributeName=ttl',
    '--region',$Region
  )
  if ($ttlTry.ExitCode -ne 0 -and $ttlTry.Output -notmatch 'already enabled') {
    throw "Falha ao habilitar TTL no DynamoDB: $($ttlTry.Output)"
  }
}

function Ensure-IamRole([string]$RoleName, [string]$Region, [string]$AccountId, [string]$AssetsBucket, [string]$TableName) {
  $roleArn = ''
  $serviceLinkedRoleName = 'AWSServiceRoleForLambda'
  $serviceLinkedRoleArn = "arn:aws:iam::${AccountId}:role/aws-service-role/lambda.amazonaws.com/AWSServiceRoleForLambda"
  $probe = Try-Aws -AwsArgs @('iam','get-role','--role-name',$RoleName,'--query','Role.Arn','--output','text')
  if ($probe.ExitCode -eq 0 -and $probe.Output -and $probe.Output -ne 'None') {
    $roleArn = $probe.Output
  } else {
    $assumePath = Join-Path $env:TEMP "$RoleName-assume.json"
    @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@ | Set-Content -Path $assumePath -Encoding ascii

    $createRoleTry = Try-Aws -AwsArgs @(
      'iam','create-role',
      '--role-name',$RoleName,
      '--assume-role-policy-document',"file://$assumePath",
      '--query','Role.Arn',
      '--output','text'
    )

    if ($createRoleTry.ExitCode -eq 0 -and $createRoleTry.Output) {
      $roleArn = $createRoleTry.Output
      Start-Sleep -Seconds 8
    } else {
      $roleArn = $serviceLinkedRoleArn
      Write-Warning "Sem permissao para criar role custom; usando ${serviceLinkedRoleName}."
    }
  }

  if ($roleArn -and ($roleArn -notmatch "/aws-service-role/lambda\.amazonaws\.com/")) {
    $policyPath = Join-Path $env:TEMP "$RoleName-inline-policy.json"
    @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["dynamodb:PutItem", "dynamodb:Query", "dynamodb:Scan"],
      "Resource": "arn:aws:dynamodb:${Region}:${AccountId}:table/${TableName}"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:CopyObject", "s3:HeadObject"],
      "Resource": "arn:aws:s3:::$AssetsBucket/*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::$AssetsBucket"
    },
    {
      "Effect": "Allow",
      "Action": ["ses:SendEmail", "ses:SendRawEmail"],
      "Resource": "*"
    }
  ]
}
"@ | Set-Content -Path $policyPath -Encoding ascii

    $putPolicyTry = Try-Aws -AwsArgs @(
      'iam','put-role-policy',
      '--role-name',$RoleName,
      '--policy-name',"$RoleName-inline",
      '--policy-document',"file://$policyPath"
    )

    if ($putPolicyTry.ExitCode -ne 0) {
      $roleArn = $serviceLinkedRoleArn
      Write-Warning "Sem permissao para anexar policy inline; usando ${serviceLinkedRoleName}."
    }
  }

  return $roleArn
}

function New-LambdaZip([string]$SourceFile, [string]$ZipPath) {
  $workDir = Join-Path $env:TEMP ("zipwork-" + [Guid]::NewGuid().ToString('N'))
  New-Item -Path $workDir -ItemType Directory | Out-Null
  Copy-Item -Path $SourceFile -Destination (Join-Path $workDir 'index.py') -Force
  if (Test-Path $ZipPath) {
    Remove-Item -Path $ZipPath -Force
  }
  Compress-Archive -Path (Join-Path $workDir '*') -DestinationPath $ZipPath -Force
  Remove-Item -Path $workDir -Recurse -Force
}

function Ensure-LambdaFunction {
  param(
    [string]$FunctionName,
    [string]$ZipPath,
    [string]$RoleArn,
    [string]$Region,
    [hashtable]$EnvVars,
    [int]$Timeout = 30,
    [int]$MemorySize = 256
  )

  $pairs = @()
  foreach ($kv in $EnvVars.GetEnumerator()) {
    $pairs += "$($kv.Key)=$($kv.Value)"
  }
  $hasEnvVars = $EnvVars -and $EnvVars.Count -gt 0
  $envArg = 'Variables={' + ($pairs -join ',') + '}'

  $exists = Try-Aws -AwsArgs @('lambda','get-function','--function-name',$FunctionName,'--region',$Region)
  if ($exists.ExitCode -eq 0) {
    Invoke-AwsText -Description "update lambda code $FunctionName" -AwsArgs @('lambda','update-function-code','--function-name',$FunctionName,'--zip-file',"fileb://$ZipPath",'--region',$Region) | Out-Null
    Invoke-AwsText -Description "wait lambda updated after code $FunctionName" -AwsArgs @('lambda','wait','function-updated','--function-name',$FunctionName,'--region',$Region) | Out-Null

    $updateArgs = @(
      'lambda','update-function-configuration',
      '--function-name',$FunctionName,
      '--runtime','python3.12',
      '--handler','index.handler',
      '--role',$RoleArn,
      '--timeout',"$Timeout",
      '--memory-size',"$MemorySize",
      '--region',$Region
    )

    if ($hasEnvVars) {
      $updateArgs += @('--environment', $envArg)
    }

    Invoke-AwsText -Description "update lambda config $FunctionName" -AwsArgs $updateArgs | Out-Null
  } else {
    $createArgs = @(
      'lambda','create-function',
      '--function-name',$FunctionName,
      '--runtime','python3.12',
      '--handler','index.handler',
      '--role',$RoleArn,
      '--zip-file',"fileb://$ZipPath",
      '--timeout',"$Timeout",
      '--memory-size',"$MemorySize",
      '--region',$Region
    )

    if ($hasEnvVars) {
      $createArgs += @('--environment', $envArg)
    }

    Invoke-AwsText -Description "create lambda $FunctionName" -AwsArgs $createArgs | Out-Null
  }

  Invoke-AwsText -Description "wait lambda active $FunctionName" -AwsArgs @('lambda','wait','function-active-v2','--function-name',$FunctionName,'--region',$Region) | Out-Null
  return (Invoke-AwsText -Description "get lambda arn $FunctionName" -AwsArgs @('lambda','get-function','--function-name',$FunctionName,'--region',$Region,'--query','Configuration.FunctionArn','--output','text'))
}

function Ensure-ApiGateway([string]$ApiName, [string]$Region) {
  $apiId = Invoke-AwsText -Description 'get rest apis' -AwsArgs @('apigateway','get-rest-apis','--query',"items[?name=='$ApiName'].id | [0]",'--output','text','--region',$Region)
  if (-not $apiId -or $apiId -eq 'None') {
    $apiId = Invoke-AwsText -Description 'create rest api' -AwsArgs @('apigateway','create-rest-api','--name',$ApiName,'--endpoint-configuration','types=REGIONAL','--query','id','--output','text','--region',$Region)
  }
  return $apiId
}

function Ensure-ApiResource([string]$ApiId, [string]$Region, [string]$RootId, [string]$PathPart) {
  $rid = Invoke-AwsText -Description "get api resource $PathPart" -AwsArgs @('apigateway','get-resources','--rest-api-id',$ApiId,'--query',"items[?pathPart=='$PathPart'].id | [0]",'--output','text','--region',$Region)
  if (-not $rid -or $rid -eq 'None') {
    $rid = Invoke-AwsText -Description "create api resource $PathPart" -AwsArgs @('apigateway','create-resource','--rest-api-id',$ApiId,'--parent-id',$RootId,'--path-part',$PathPart,'--query','id','--output','text','--region',$Region)
  }
  return $rid
}

function Ensure-ApiLambdaIntegration {
  param(
    [string]$ApiId,
    [string]$Region,
    [string]$ResourceId,
    [string]$PathPart,
    [string]$LambdaArn,
    [string]$LambdaName,
    [string]$AccountId
  )

  $null = Try-Aws -AwsArgs @('apigateway','put-method','--rest-api-id',$ApiId,'--resource-id',$ResourceId,'--http-method','ANY','--authorization-type','NONE','--region',$Region)

  $uri = "arn:aws:apigateway:${Region}:lambda:path/2015-03-31/functions/${LambdaArn}/invocations"
  Invoke-AwsText -Description "put integration $PathPart" -AwsArgs @(
    'apigateway','put-integration',
    '--rest-api-id',$ApiId,
    '--resource-id',$ResourceId,
    '--http-method','ANY',
    '--type','AWS_PROXY',
    '--integration-http-method','POST',
    '--uri',$uri,
    '--region',$Region
  ) | Out-Null

  $statementId = "apigw-$ApiId-$PathPart"
  $sourceArn = "arn:aws:execute-api:${Region}:${AccountId}:${ApiId}/*/*/${PathPart}"
  $perm = Try-Aws -AwsArgs @('lambda','add-permission','--function-name',$LambdaName,'--statement-id',$statementId,'--action','lambda:InvokeFunction','--principal','apigateway.amazonaws.com','--source-arn',$sourceArn,'--region',$Region)
  if ($perm.ExitCode -ne 0 -and $perm.Output -notmatch 'ResourceConflictException') {
    throw "Falha ao adicionar permissao API Gateway em ${LambdaName}: $($perm.Output)"
  }
}

function Ensure-S3ImageTrigger([string]$ImageFunctionName, [string]$ImageFunctionArn, [string]$AssetsBucket, [string]$Region) {
  $perm = Try-Aws -AwsArgs @('lambda','add-permission','--function-name',$ImageFunctionName,'--statement-id',"s3invoke-$AssetsBucket",'--action','lambda:InvokeFunction','--principal','s3.amazonaws.com','--source-arn',"arn:aws:s3:::$AssetsBucket",'--region',$Region)
  if ($perm.ExitCode -ne 0 -and $perm.Output -notmatch 'ResourceConflictException') {
    throw "Falha ao adicionar permissao S3->Lambda: $($perm.Output)"
  }

  $notifPath = Join-Path $env:TEMP "tf11-s3-notification.json"
  @"
{
  "LambdaFunctionConfigurations": [
    {
      "Id": "tf11ImageProcessor",
      "LambdaFunctionArn": "$ImageFunctionArn",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            { "Name": "prefix", "Value": "uploads/raw/" }
          ]
        }
      }
    }
  ]
}
"@ | Set-Content -Path $notifPath -Encoding ascii

  Invoke-AwsText -Description 'put s3 notification' -AwsArgs @('s3api','put-bucket-notification-configuration','--bucket',$AssetsBucket,'--notification-configuration',"file://$notifPath") | Out-Null
}

function Ensure-LogsBucket([string]$LogsBucket, [string]$Region, [string]$WebsiteBucket, [string]$AssetsBucket) {
  $probe = Try-Aws -AwsArgs @('s3api','head-bucket','--bucket',$LogsBucket)
  if ($probe.ExitCode -ne 0) {
    if ($Region -eq 'us-east-1') {
      $create = Try-Aws -AwsArgs @('s3api','create-bucket','--bucket',$LogsBucket,'--object-ownership','BucketOwnerPreferred')
      if ($create.ExitCode -ne 0) {
        Invoke-AwsText -Description 'create logs bucket fallback us-east-1' -AwsArgs @('s3api','create-bucket','--bucket',$LogsBucket) | Out-Null
      }
    } else {
      $create = Try-Aws -AwsArgs @('s3api','create-bucket','--bucket',$LogsBucket,'--region',$Region,'--object-ownership','BucketOwnerPreferred','--create-bucket-configuration',"LocationConstraint=$Region")
      if ($create.ExitCode -ne 0) {
        Invoke-AwsText -Description 'create logs bucket fallback' -AwsArgs @('s3api','create-bucket','--bucket',$LogsBucket,'--region',$Region,'--create-bucket-configuration',"LocationConstraint=$Region") | Out-Null
      }
    }
  }

  $null = Try-Aws -AwsArgs @('s3api','put-bucket-acl','--bucket',$LogsBucket,'--acl','log-delivery-write')

  $policyPath = Join-Path $env:TEMP "$LogsBucket-policy.json"
  @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ServerAccessLogs",
      "Effect": "Allow",
      "Principal": { "Service": "logging.s3.amazonaws.com" },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::$LogsBucket/s3-access/*",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": [
            "arn:aws:s3:::$WebsiteBucket",
            "arn:aws:s3:::$AssetsBucket"
          ]
        }
      }
    }
  ]
}
"@ | Set-Content -Path $policyPath -Encoding ascii

  Invoke-AwsText -Description 'put logs bucket policy' -AwsArgs @('s3api','put-bucket-policy','--bucket',$LogsBucket,'--policy',"file://$policyPath") | Out-Null
}

function Enable-CloudFrontLogging([string]$DistributionId, [string]$LogsBucket) {
  $raw = Invoke-AwsText -Description 'get cloudfront distribution config' -AwsArgs @('cloudfront','get-distribution-config','--id',$DistributionId,'--output','json')
  $obj = $raw | ConvertFrom-Json
  $etag = $obj.ETag
  $distConfig = $obj.DistributionConfig

  if (-not $distConfig.PSObject.Properties['Logging']) {
    $distConfig | Add-Member -NotePropertyName Logging -NotePropertyValue ([pscustomobject]@{
      Enabled = $true
      IncludeCookies = $false
      Bucket = "$LogsBucket.s3.amazonaws.com"
      Prefix = 'cloudfront/'
    })
  } else {
    $distConfig.Logging.Enabled = $true
    $distConfig.Logging.IncludeCookies = $false
    $distConfig.Logging.Bucket = "$LogsBucket.s3.amazonaws.com"
    $distConfig.Logging.Prefix = 'cloudfront/'
  }

  $cfgPath = Join-Path $env:TEMP "tf11-cf-dist-config.json"
  ($distConfig | ConvertTo-Json -Depth 100) | Set-Content -Path $cfgPath -Encoding utf8

  $update = Try-Aws -AwsArgs @('cloudfront','update-distribution','--id',$DistributionId,'--if-match',$etag,'--distribution-config',"file://$cfgPath")
  if ($update.ExitCode -ne 0) {
    Write-Output "Aviso: falha ao habilitar logging do CloudFront automaticamente: $($update.Output)"
  }
}

function Put-CloudWatchAssets([string]$Region, [string]$DistributionId, [string]$Prefix) {
  Invoke-AwsText -Description 'put billing alarm' -AwsArgs @(
    'cloudwatch','put-metric-alarm',
    '--alarm-name',"$Prefix-billing-usd-5",
    '--alarm-description','TF11 billing threshold',
    '--namespace','AWS/Billing',
    '--metric-name','EstimatedCharges',
    '--dimensions','Name=Currency,Value=USD',
    '--statistic','Maximum',
    '--period','21600',
    '--evaluation-periods','1',
    '--threshold','5',
    '--comparison-operator','GreaterThanThreshold',
    '--treat-missing-data','notBreaching',
    '--region','us-east-1'
  ) | Out-Null

  Invoke-AwsText -Description 'put cloudfront 4xx alarm' -AwsArgs @(
    'cloudwatch','put-metric-alarm',
    '--alarm-name',"$Prefix-cloudfront-4xx",
    '--alarm-description','TF11 cloudfront 4xx',
    '--namespace','AWS/CloudFront',
    '--metric-name','4xxErrorRate',
    '--dimensions',"Name=DistributionId,Value=$DistributionId",'Name=Region,Value=Global',
    '--statistic','Average',
    '--period','300',
    '--evaluation-periods','1',
    '--threshold','5',
    '--comparison-operator','GreaterThanThreshold',
    '--treat-missing-data','notBreaching',
    '--region',$Region
  ) | Out-Null

  Invoke-AwsText -Description 'put cache hit alarm' -AwsArgs @(
    'cloudwatch','put-metric-alarm',
    '--alarm-name',"$Prefix-cache-hit-low",
    '--alarm-description','TF11 cloudfront cache hit low',
    '--namespace','AWS/CloudFront',
    '--metric-name','CacheHitRate',
    '--dimensions',"Name=DistributionId,Value=$DistributionId",'Name=Region,Value=Global',
    '--statistic','Average',
    '--period','300',
    '--evaluation-periods','1',
    '--threshold','60',
    '--comparison-operator','LessThanThreshold',
    '--treat-missing-data','notBreaching',
    '--region',$Region
  ) | Out-Null

  $dashboardName = "$Prefix-dashboard"
  $body = @{
    widgets = @(
      @{
        type = 'metric'
        x = 0
        y = 0
        width = 12
        height = 6
        properties = @{
          title = 'CloudFront Requests'
          region = $Region
          stat = 'Sum'
          period = 300
          metrics = ,@('AWS/CloudFront','Requests','DistributionId',$DistributionId,'Region','Global')
        }
      },
      @{
        type = 'metric'
        x = 12
        y = 0
        width = 12
        height = 6
        properties = @{
          title = 'CloudFront CacheHitRate'
          region = $Region
          stat = 'Average'
          period = 300
          metrics = ,@('AWS/CloudFront','CacheHitRate','DistributionId',$DistributionId,'Region','Global')
        }
      }
    )
  } | ConvertTo-Json -Depth 20 -Compress

  Invoke-AwsText -Description 'put cloudwatch dashboard' -AwsArgs @('cloudwatch','put-dashboard','--dashboard-name',$dashboardName,'--dashboard-body',$body,'--region',$Region) | Out-Null
}

function Write-EvidenceFiles {
  param(
    [string]$ProjectRoot,
    [string]$Region,
    [string]$WebsiteBucket,
    [string]$DistributionId,
    [string]$ContactApiUrl,
    [string]$UploadApiUrl
  )

  $dir = Join-Path $ProjectRoot 'docs\evidencias'
  if (-not (Test-Path $dir)) {
    New-Item -Path $dir -ItemType Directory | Out-Null
  }

  Invoke-AwsText -Description 'evidence s3 website' -AwsArgs @('s3api','get-bucket-website','--bucket',$WebsiteBucket,'--output','json') | Set-Content -Path (Join-Path $dir '01-s3-website-config.json') -Encoding utf8
  Invoke-AwsText -Description 'evidence s3 policy' -AwsArgs @('s3api','get-bucket-policy','--bucket',$WebsiteBucket,'--output','json') | Set-Content -Path (Join-Path $dir '02-s3-bucket-policy.json') -Encoding utf8
  Invoke-AwsText -Description 'evidence cloudfront' -AwsArgs @('cloudfront','get-distribution','--id',$DistributionId,'--output','json') | Set-Content -Path (Join-Path $dir '03-cloudfront-distribution.json') -Encoding utf8
  Invoke-AwsText -Description 'evidence alarms' -AwsArgs @('cloudwatch','describe-alarms','--alarm-name-prefix','tf11-6324064','--region',$Region,'--output','json') | Set-Content -Path (Join-Path $dir '04-cloudwatch-alarms.json') -Encoding utf8
  Invoke-AwsText -Description 'evidence dashboard' -AwsArgs @('cloudwatch','get-dashboard','--dashboard-name','tf11-6324064-dashboard','--region',$Region,'--output','json') | Set-Content -Path (Join-Path $dir '05-cloudwatch-dashboard.json') -Encoding utf8

  $start = (Get-Date).ToUniversalTime().AddHours(-24).ToString('yyyy-MM-ddTHH:mm:ssZ')
  $end = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  Invoke-AwsText -Description 'evidence cache stats' -AwsArgs @(
    'cloudwatch','get-metric-statistics',
    '--namespace','AWS/CloudFront',
    '--metric-name','CacheHitRate',
    '--dimensions',"Name=DistributionId,Value=$DistributionId",'Name=Region,Value=Global',
    '--statistics','Average',
    '--period','300',
    '--start-time',$start,
    '--end-time',$end,
    '--region',$Region,
    '--output','json'
  ) | Set-Content -Path (Join-Path $dir '06-cache-hit-rate.json') -Encoding utf8

  $contactStatus = 'n/a'
  $uploadStatus = 'n/a'
  $galleryStatus = 'n/a'
  $uploadBody = ''
  $contactBody = ''

  try {
    $payload = '{"name":"Teste TF11","email":"teste@example.com","subject":"Teste","message":"Mensagem de teste automatizada do deploy."}'
    $resp = Invoke-WebRequest -Uri $ContactApiUrl -Method Post -UseBasicParsing -ContentType 'application/json' -Body $payload -TimeoutSec 25
    $contactStatus = [string]$resp.StatusCode
    $contactBody = $resp.Content
  } catch {
    $contactStatus = 'error'
    $contactBody = $_.Exception.Message
  }

  try {
    $u = Invoke-WebRequest -Uri $UploadApiUrl -Method Post -UseBasicParsing -ContentType 'application/json' -Body '{"fileName":"amostra.webp","contentType":"image/webp"}' -TimeoutSec 25
    $uploadStatus = [string]$u.StatusCode
    $uploadBody = $u.Content
  } catch {
    $uploadStatus = 'error'
    $uploadBody = $_.Exception.Message
  }

  try {
    $g = Invoke-WebRequest -Uri $UploadApiUrl -Method Get -UseBasicParsing -TimeoutSec 25
    $galleryStatus = [string]$g.StatusCode
  } catch {
    $galleryStatus = 'error'
  }

  $s3Url = "http://$WebsiteBucket.s3-website-$Region.amazonaws.com"
  $cfUrl = (Invoke-AwsText -Description 'get cloudfront domain' -AwsArgs @('cloudfront','get-distribution','--id',$DistributionId,'--query','Distribution.DomainName','--output','text'))
  $cfUrl = "https://$cfUrl"

  function Measure-Samples([string]$Url) {
    $samples = @()
    foreach ($i in 1..5) {
      $sw = [System.Diagnostics.Stopwatch]::StartNew()
      Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 25 | Out-Null
      $sw.Stop()
      $samples += [Math]::Round($sw.Elapsed.TotalMilliseconds, 2)
    }
    return $samples
  }

  $s3Samples = Measure-Samples $s3Url
  $cfSamples = Measure-Samples $cfUrl

  $report = @(
    "CONTACT_STATUS=$contactStatus",
    "UPLOAD_STATUS=$uploadStatus",
    "GALLERY_STATUS=$galleryStatus",
    "CONTACT_BODY=$contactBody",
    "UPLOAD_BODY=$uploadBody",
    "S3_URL=$s3Url",
    "S3_MS_SAMPLES=$($s3Samples -join ',')",
    "CF_URL=$cfUrl",
    "CF_MS_SAMPLES=$($cfSamples -join ',')"
  )
  Set-Content -Path (Join-Path $dir '07-functional-performance-check.txt') -Value $report -Encoding ascii
}

$ProjectRoot = (Resolve-Path $ProjectRoot).Path
$outputPath = Join-Path $ProjectRoot 'docs\deployment-output.txt'
if (-not (Test-Path $outputPath)) {
  throw 'deployment-output.txt nao encontrado'
}

Write-Step 'Lendo configuracao atual'
$map = Get-KeyValueMap $outputPath
$region = $map['AWS_REGION']
$accountId = $map['AWS_ACCOUNT_ID']
$websiteBucket = $map['WEBSITE_BUCKET']
$assetsBucket = $map['ASSETS_BUCKET']
$distributionId = $map['CLOUDFRONT_DISTRIBUTION_ID']
$cloudfrontDomain = $map['CLOUDFRONT_DOMAIN']
if (-not $region) { $region = 'us-east-1' }
if (-not $cloudfrontDomain) { $cloudfrontDomain = '' }

$prefix = 'tf11-6324064'
$tableName = 'tf11-contacts-6324064'
$roleName = "$prefix-lambda-role"

Write-Step 'Garantindo DynamoDB'
Ensure-DynamoTable -TableName $tableName -Region $region

Write-Step 'Garantindo IAM role'
$roleArn = Ensure-IamRole -RoleName $roleName -Region $region -AccountId $accountId -AssetsBucket $assetsBucket -TableName $tableName

Write-Step 'Empacotando lambdas'
$contactZip = Join-Path $env:TEMP "$prefix-contact.zip"
$uploadZip = Join-Path $env:TEMP "$prefix-upload.zip"
$imageZip = Join-Path $env:TEMP "$prefix-image.zip"

New-LambdaZip -SourceFile (Join-Path $ProjectRoot 'lambda\contact-form\index.py') -ZipPath $contactZip
New-LambdaZip -SourceFile (Join-Path $ProjectRoot 'lambda\upload-url\index.py') -ZipPath $uploadZip
New-LambdaZip -SourceFile (Join-Path $ProjectRoot 'lambda\image-processor\index.py') -ZipPath $imageZip

$contactFn = "$prefix-contact-form"
$uploadFn = "$prefix-upload-url"
$imageFn = "$prefix-image-processor"

Write-Step 'Criando/atualizando lambdas'
$contactArn = Ensure-LambdaFunction -FunctionName $contactFn -ZipPath $contactZip -RoleArn $roleArn -Region $region -EnvVars @{
  CONTACTS_TABLE = $tableName
  ALLOWED_ORIGIN = $cloudfrontDomain
} -Timeout 30 -MemorySize 256

$uploadArn = Ensure-LambdaFunction -FunctionName $uploadFn -ZipPath $uploadZip -RoleArn $roleArn -Region $region -EnvVars @{
  ASSETS_BUCKET = $assetsBucket
  ALLOWED_ORIGIN = $cloudfrontDomain
  MAX_RESULTS = '30'
} -Timeout 30 -MemorySize 256

$imageArn = Ensure-LambdaFunction -FunctionName $imageFn -ZipPath $imageZip -RoleArn $roleArn -Region $region -EnvVars @{
} -Timeout 60 -MemorySize 512

Write-Step 'Configurando trigger S3 -> Lambda imagem'
Ensure-S3ImageTrigger -ImageFunctionName $imageFn -ImageFunctionArn $imageArn -AssetsBucket $assetsBucket -Region $region

Write-Step 'Configurando API Gateway'
$apiName = "$prefix-api"
$apiId = Ensure-ApiGateway -ApiName $apiName -Region $region
$rootId = Invoke-AwsText -Description 'get api root' -AwsArgs @('apigateway','get-resources','--rest-api-id',$apiId,'--query','items[?path==`/`].id | [0]','--output','text','--region',$region)
$contactResourceId = Ensure-ApiResource -ApiId $apiId -Region $region -RootId $rootId -PathPart 'contact'
$uploadResourceId = Ensure-ApiResource -ApiId $apiId -Region $region -RootId $rootId -PathPart 'upload'

Ensure-ApiLambdaIntegration -ApiId $apiId -Region $region -ResourceId $contactResourceId -PathPart 'contact' -LambdaArn $contactArn -LambdaName $contactFn -AccountId $accountId
Ensure-ApiLambdaIntegration -ApiId $apiId -Region $region -ResourceId $uploadResourceId -PathPart 'upload' -LambdaArn $uploadArn -LambdaName $uploadFn -AccountId $accountId

Invoke-AwsText -Description 'create api deployment' -AwsArgs @('apigateway','create-deployment','--rest-api-id',$apiId,'--stage-name','prod','--description','tf11 deployment','--region',$region) | Out-Null

$apiBase = "https://$apiId.execute-api.$region.amazonaws.com/prod"
$contactApiUrl = "$apiBase/contact"
$uploadApiUrl = "$apiBase/upload"
$galleryApiUrl = "$apiBase/upload"

Write-Step 'Atualizando config.js e publicando site'
$configPath = Join-Path $ProjectRoot 'website\js\config.js'
$configContent = Get-Content -Path $configPath -Raw
$configContent = $configContent -replace 'CONTACT_API_URL:\s*".*?"', ('CONTACT_API_URL: "' + $contactApiUrl + '"')
$configContent = $configContent -replace 'UPLOAD_API_URL:\s*".*?"', ('UPLOAD_API_URL: "' + $uploadApiUrl + '"')
$configContent = $configContent -replace 'GALLERY_API_URL:\s*".*?"', ('GALLERY_API_URL: "' + $galleryApiUrl + '"')
$configContent = $configContent -replace 'CLOUDFRONT_URL:\s*".*?"', ('CLOUDFRONT_URL: "' + $cloudfrontDomain + '"')
Set-Content -Path $configPath -Value $configContent -Encoding ascii

Invoke-AwsText -Description 'sync website bucket' -AwsArgs @('s3','sync',(Join-Path $ProjectRoot 'website'),"s3://$websiteBucket",'--delete') | Out-Null
Invoke-AwsText -Description 'invalidate cloudfront' -AwsArgs @('cloudfront','create-invalidation','--distribution-id',$distributionId,'--paths','/*') | Out-Null

Write-Step 'Ativando logs e monitoramento'
$logsBucket = $map['LOGS_BUCKET']
if (-not $logsBucket) {
  $logsBucket = "$prefix-logs-$(Get-Date -Format yyyyMMddHHmmss)"
}

Ensure-LogsBucket -LogsBucket $logsBucket -Region $region -WebsiteBucket $websiteBucket -AssetsBucket $assetsBucket
Invoke-AwsText -Description 'enable website access logs' -AwsArgs @('s3api','put-bucket-logging','--bucket',$websiteBucket,'--bucket-logging-status',"LoggingEnabled={TargetBucket=$logsBucket,TargetPrefix=s3-access/$websiteBucket/}") | Out-Null
Invoke-AwsText -Description 'enable assets access logs' -AwsArgs @('s3api','put-bucket-logging','--bucket',$assetsBucket,'--bucket-logging-status',"LoggingEnabled={TargetBucket=$logsBucket,TargetPrefix=s3-access/$assetsBucket/}") | Out-Null
Enable-CloudFrontLogging -DistributionId $distributionId -LogsBucket $logsBucket
Put-CloudWatchAssets -Region $region -DistributionId $distributionId -Prefix $prefix

Write-Step 'Gerando evidencias tecnicas'
Write-EvidenceFiles -ProjectRoot $ProjectRoot -Region $region -WebsiteBucket $websiteBucket -DistributionId $distributionId -ContactApiUrl $contactApiUrl -UploadApiUrl $uploadApiUrl

Write-Step 'Atualizando deployment-output'
$map['LOGS_BUCKET'] = $logsBucket
$map['DYNAMODB_TABLE'] = $tableName
$map['API_GATEWAY_ID'] = $apiId
$map['CONTACT_API_URL'] = $contactApiUrl
$map['UPLOAD_API_URL'] = $uploadApiUrl
$map['GALLERY_API_URL'] = $galleryApiUrl
$map['LAMBDA_CONTACT'] = $contactFn
$map['LAMBDA_UPLOAD'] = $uploadFn
$map['LAMBDA_IMAGE'] = $imageFn
$map['CLOUDFRONT_STATUS'] = Invoke-AwsText -Description 'get cloudfront status' -AwsArgs @('cloudfront','get-distribution','--id',$distributionId,'--query','Distribution.Status','--output','text')

Save-KeyValueMap -Path $outputPath -Map $map

Write-Output 'DONE'
Write-Output "CONTACT_API_URL=$contactApiUrl"
Write-Output "UPLOAD_API_URL=$uploadApiUrl"
Write-Output "LOGS_BUCKET=$logsBucket"
Write-Output "API_GATEWAY_ID=$apiId"

