param(
  [string]$RootDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
$env:AWS_PAGER = ''

function Invoke-AwsText {
  param(
    [string]$Description,
    [string[]]$AwsArgs
  )

  $raw = (& aws @AwsArgs 2>&1 | Out-String).Trim()
  if ($LASTEXITCODE -ne 0) {
    throw "Falha em '$Description': $raw"
  }

  return $raw
}

function Try-Aws {
  param([string[]]$AwsArgs)

  $raw = (& aws @AwsArgs 2>&1 | Out-String).Trim()
  return @{
    ExitCode = $LASTEXITCODE
    Output = $raw
  }
}

function Parse-KeyValueFile([string]$Path) {
  $map = @{}
  Get-Content -Path $Path | ForEach-Object {
    if ($_ -match '^(.*?)=(.*)$') {
      $map[$matches[1]] = $matches[2]
    }
  }
  return $map
}

function Write-KeyValueFile([string]$Path, [hashtable]$Map) {
  $orderedKeys = @(
    'AWS_ACCOUNT_ID',
    'AWS_REGION',
    'WEBSITE_BUCKET',
    'ASSETS_BUCKET',
    'LOGS_BUCKET',
    'S3_WEBSITE_URL',
    'CLOUDFRONT_DISTRIBUTION_ID',
    'CLOUDFRONT_DOMAIN',
    'CLOUDFRONT_STATUS',
    'CONTACT_API_URL',
    'UPLOAD_API_URL',
    'GALLERY_API_URL',
    'DYNAMODB_TABLE',
    'API_GATEWAY_ID',
    'LAMBDA_CONTACT',
    'LAMBDA_UPLOAD',
    'LAMBDA_IMAGE'
  )

  $lines = @()
  foreach ($key in $orderedKeys) {
    if ($Map.ContainsKey($key)) {
      $lines += "$key=$($Map[$key])"
    }
  }

  Set-Content -Path $Path -Value $lines -Encoding ascii
}

function Ensure-LogsBucket {
  param(
    [string]$BucketName,
    [string]$Region,
    [string]$WebsiteBucket,
    [string]$AssetsBucket
  )

  $head = Try-Aws -AwsArgs @('s3api','head-bucket','--bucket',$BucketName)
  if ($head.ExitCode -ne 0) {
    if ($Region -eq 'us-east-1') {
      Invoke-AwsText -Description 'create logs bucket us-east-1' -AwsArgs @('s3api','create-bucket','--bucket',$BucketName,'--object-ownership','BucketOwnerPreferred') | Out-Null
    } else {
      Invoke-AwsText -Description 'create logs bucket regional' -AwsArgs @('s3api','create-bucket','--bucket',$BucketName,'--region',$Region,'--object-ownership','BucketOwnerPreferred','--create-bucket-configuration',"LocationConstraint=$Region") | Out-Null
    }
  }

  # S3 server access logs still use ACL delivery in many accounts.
  $aclTry = Try-Aws -AwsArgs @('s3api','put-bucket-acl','--bucket',$BucketName,'--acl','log-delivery-write')
  if ($aclTry.ExitCode -ne 0 -and $aclTry.Output -notmatch 'AccessControlListNotSupported') {
    throw "Falha ao configurar ACL de logs: $($aclTry.Output)"
  }

  $policyPath = Join-Path $env:TEMP 'tf11-logs-bucket-policy.json'
  @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ServerAccessLogs",
      "Effect": "Allow",
      "Principal": { "Service": "logging.s3.amazonaws.com" },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::$BucketName/s3-access/*",
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

  Invoke-AwsText -Description 'put logs bucket policy' -AwsArgs @('s3api','put-bucket-policy','--bucket',$BucketName,'--policy',"file://$policyPath") | Out-Null
}

function Enable-S3AccessLogging {
  param(
    [string]$SourceBucket,
    [string]$TargetBucket,
    [string]$Prefix
  )

  Invoke-AwsText -Description "enable s3 access logging $SourceBucket" -AwsArgs @(
    's3api','put-bucket-logging',
    '--bucket',$SourceBucket,
    '--bucket-logging-status',"LoggingEnabled={TargetBucket=$TargetBucket,TargetPrefix=$Prefix}"
  ) | Out-Null
}

function Enable-CloudFrontLogging {
  param(
    [string]$DistributionId,
    [string]$LogsBucket
  )

  $rawConfigPath = Join-Path $env:TEMP 'tf11-cf-get-config.json'
  $updatedConfigPath = Join-Path $env:TEMP 'tf11-cf-updated-config.json'

  Invoke-AwsText -Description 'get cloudfront config' -AwsArgs @('cloudfront','get-distribution-config','--id',$DistributionId,'--output','json') | Set-Content -Path $rawConfigPath -Encoding utf8

  $raw = Get-Content -Path $rawConfigPath -Raw | ConvertFrom-Json
  $etag = $raw.ETag
  $distributionConfig = $raw.DistributionConfig

  $distributionConfig.Logging.Enabled = $true
  $distributionConfig.Logging.IncludeCookies = $false
  $distributionConfig.Logging.Bucket = "$LogsBucket.s3.amazonaws.com"
  $distributionConfig.Logging.Prefix = 'cloudfront/'

  $distributionConfig | ConvertTo-Json -Depth 100 | Set-Content -Path $updatedConfigPath -Encoding utf8

  $updateTry = Try-Aws -AwsArgs @('cloudfront','update-distribution','--id',$DistributionId,'--if-match',$etag,'--distribution-config',"file://$updatedConfigPath")
  if ($updateTry.ExitCode -ne 0) {
    Write-Warning "CloudFront logging nao foi habilitado automaticamente: $($updateTry.Output)"
  }
}

function Put-CloudWatchAssets {
  param(
    [string]$Region,
    [string]$DistributionId
  )

  Invoke-AwsText -Description 'put billing alarm' -AwsArgs @(
    'cloudwatch','put-metric-alarm',
    '--alarm-name','tf11-6324064-billing-usd-5',
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
    '--alarm-name','tf11-6324064-cloudfront-4xx',
    '--alarm-description','TF11 cloudfront 4xx > 5%',
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

  Invoke-AwsText -Description 'put cloudfront cache-hit alarm' -AwsArgs @(
    'cloudwatch','put-metric-alarm',
    '--alarm-name','tf11-6324064-cache-hit-low',
    '--alarm-description','TF11 cache hit < 60%',
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

  $dashboardPath = Join-Path $env:TEMP 'tf11-dashboard-body.json'
  @"
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "title": "CloudFront Requests",
        "region": "$Region",
        "stat": "Sum",
        "period": 300,
        "metrics": [
          ["AWS/CloudFront", "Requests", "DistributionId", "$DistributionId", "Region", "Global"]
        ]
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "title": "CloudFront Cache Hit Rate",
        "region": "$Region",
        "stat": "Average",
        "period": 300,
        "metrics": [
          ["AWS/CloudFront", "CacheHitRate", "DistributionId", "$DistributionId", "Region", "Global"]
        ]
      }
    }
  ]
}
"@ | Set-Content -Path $dashboardPath -Encoding ascii

  Invoke-AwsText -Description 'put cloudwatch dashboard' -AwsArgs @(
    'cloudwatch','put-dashboard',
    '--dashboard-name','tf11-6324064-dashboard',
    '--dashboard-body',"file://$dashboardPath",
    '--region',$Region
  ) | Out-Null
}

function Measure-Url([string]$Url) {
  $samples = @()
  $attempt = 0
  while ($samples.Count -lt 5 -and $attempt -lt 12) {
    $attempt++
    try {
      $sw = [System.Diagnostics.Stopwatch]::StartNew()
      Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 30 | Out-Null
      $sw.Stop()
      $samples += [math]::Round($sw.Elapsed.TotalMilliseconds, 2)
    } catch {
      Write-Warning "Falha de medicao para $Url na tentativa $attempt."
    }
  }

  if ($samples.Count -eq 0) {
    return @(0)
  }

  return $samples
}

function Write-Evidences {
  param(
    [string]$Root,
    [string]$Region,
    [string]$WebsiteBucket,
    [string]$DistributionId,
    [string]$CloudFrontUrl
  )

  $evidenceDir = Join-Path $Root 'docs\\evidencias'
  if (-not (Test-Path $evidenceDir)) {
    New-Item -Path $evidenceDir -ItemType Directory | Out-Null
  }

  Invoke-AwsText -Description 'evidence s3 website config' -AwsArgs @('s3api','get-bucket-website','--bucket',$WebsiteBucket,'--output','json') | Set-Content -Path (Join-Path $evidenceDir '01-s3-website-config.json') -Encoding utf8
  Invoke-AwsText -Description 'evidence s3 bucket policy' -AwsArgs @('s3api','get-bucket-policy','--bucket',$WebsiteBucket,'--output','json') | Set-Content -Path (Join-Path $evidenceDir '02-s3-bucket-policy.json') -Encoding utf8
  Invoke-AwsText -Description 'evidence cloudfront distribution' -AwsArgs @('cloudfront','get-distribution','--id',$DistributionId,'--output','json') | Set-Content -Path (Join-Path $evidenceDir '03-cloudfront-distribution.json') -Encoding utf8
  Invoke-AwsText -Description 'evidence cloudwatch alarms' -AwsArgs @('cloudwatch','describe-alarms','--alarm-name-prefix','tf11-6324064','--region',$Region,'--output','json') | Set-Content -Path (Join-Path $evidenceDir '04-cloudwatch-alarms.json') -Encoding utf8
  Invoke-AwsText -Description 'evidence cloudwatch dashboard' -AwsArgs @('cloudwatch','get-dashboard','--dashboard-name','tf11-6324064-dashboard','--region',$Region,'--output','json') | Set-Content -Path (Join-Path $evidenceDir '05-cloudwatch-dashboard.json') -Encoding utf8

  $start = (Get-Date).ToUniversalTime().AddHours(-24).ToString('yyyy-MM-ddTHH:mm:ssZ')
  $end = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  Invoke-AwsText -Description 'evidence cache hit metric' -AwsArgs @(
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
  ) | Set-Content -Path (Join-Path $evidenceDir '06-cache-hit-rate.json') -Encoding utf8

  $s3Url = "http://$WebsiteBucket.s3-website-$Region.amazonaws.com"
  $s3Times = Measure-Url -Url $s3Url
  $cfTimes = Measure-Url -Url $CloudFrontUrl

  $inv = [System.Globalization.CultureInfo]::InvariantCulture
  $s3SampleText = ($s3Times | ForEach-Object { [string]::Format($inv, '{0:0.00}', [double]$_) }) -join ';'
  $cfSampleText = ($cfTimes | ForEach-Object { [string]::Format($inv, '{0:0.00}', [double]$_) }) -join ';'
  $s3Avg = [string]::Format($inv, '{0:0.00}', (($s3Times | Measure-Object -Average).Average))
  $cfAvg = [string]::Format($inv, '{0:0.00}', (($cfTimes | Measure-Object -Average).Average))

  @(
    "S3_URL=$s3Url",
    "S3_MS_SAMPLES=$s3SampleText",
    "CLOUDFRONT_URL=$CloudFrontUrl",
    "CLOUDFRONT_MS_SAMPLES=$cfSampleText",
    "S3_AVG_MS=$s3Avg",
    "CLOUDFRONT_AVG_MS=$cfAvg"
  ) | Set-Content -Path (Join-Path $evidenceDir '07-performance-check.txt') -Encoding ascii
}

Write-Output '==> Lendo configuracao atual'
$outputFile = Join-Path $RootDir 'docs\\deployment-output.txt'
if (-not (Test-Path $outputFile)) {
  throw "Arquivo nao encontrado: $outputFile"
}

$cfg = Parse-KeyValueFile -Path $outputFile
$region = $cfg['AWS_REGION']
$websiteBucket = $cfg['WEBSITE_BUCKET']
$assetsBucket = $cfg['ASSETS_BUCKET']
$distributionId = $cfg['CLOUDFRONT_DISTRIBUTION_ID']
$cloudfrontUrl = $cfg['CLOUDFRONT_DOMAIN']

if (-not $region -or -not $websiteBucket -or -not $assetsBucket -or -not $distributionId -or -not $cloudfrontUrl) {
  throw 'deployment-output.txt incompleto para observabilidade.'
}

$logsBucket = $cfg['LOGS_BUCKET']
if (-not $logsBucket) {
  $logsBucket = "tf11-6324064-logs-$(Get-Date -Format yyyyMMddHHmmss)"
}

Write-Output '==> Garantindo bucket de logs'
Ensure-LogsBucket -BucketName $logsBucket -Region $region -WebsiteBucket $websiteBucket -AssetsBucket $assetsBucket

Write-Output '==> Habilitando logs S3'
Enable-S3AccessLogging -SourceBucket $websiteBucket -TargetBucket $logsBucket -Prefix "s3-access/$websiteBucket/"
Enable-S3AccessLogging -SourceBucket $assetsBucket -TargetBucket $logsBucket -Prefix "s3-access/$assetsBucket/"

Write-Output '==> Habilitando logs CloudFront'
Enable-CloudFrontLogging -DistributionId $distributionId -LogsBucket $logsBucket

Write-Output '==> Criando alarmes e dashboard'
Put-CloudWatchAssets -Region $region -DistributionId $distributionId

Write-Output '==> Gerando evidencias'
Write-Evidences -Root $RootDir -Region $region -WebsiteBucket $websiteBucket -DistributionId $distributionId -CloudFrontUrl $cloudfrontUrl

$cfg['LOGS_BUCKET'] = $logsBucket
$cfg['CLOUDFRONT_STATUS'] = Invoke-AwsText -Description 'get cloudfront status' -AwsArgs @('cloudfront','get-distribution','--id',$distributionId,'--query','Distribution.Status','--output','text')
Write-KeyValueFile -Path $outputFile -Map $cfg

Write-Output '==> Observabilidade concluida'
Write-Output "LOGS_BUCKET=$logsBucket"
Write-Output "OUTPUT_FILE=$outputFile"
