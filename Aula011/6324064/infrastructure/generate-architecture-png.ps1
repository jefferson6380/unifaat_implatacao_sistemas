param(
  [string]$ProjectRoot = "$(Join-Path $PSScriptRoot '..')"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$ProjectRoot = (Resolve-Path $ProjectRoot).Path
$outPath = Join-Path $ProjectRoot 'docs\architecture-diagram.png'

$w = 1400
$h = 820
$bmp = New-Object System.Drawing.Bitmap($w, $h)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(244, 249, 255))

$fontTitle = New-Object System.Drawing.Font('Segoe UI', 24, [System.Drawing.FontStyle]::Bold)
$fontLabel = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$fontBody = New-Object System.Drawing.Font('Segoe UI', 10)
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(47, 89, 146), 2)
$arrowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(47, 89, 146))

function Draw-Node {
  param(
    [System.Drawing.Graphics]$Canvas,
    [int]$X,
    [int]$Y,
    [int]$W,
    [int]$H,
    [string]$Title,
    [string]$Text,
    [System.Drawing.Color]$Color
  )

  $rect = New-Object System.Drawing.Rectangle($X, $Y, $W, $H)
  $bg = New-Object System.Drawing.SolidBrush($Color)
  $Canvas.FillRoundedRectangle($bg, $rect, 16)
  $Canvas.DrawRoundedRectangle($pen, $rect, 16)
  $Canvas.DrawString($Title, $fontLabel, [System.Drawing.Brushes]::Black, ($X + 14), ($Y + 12))
  $Canvas.DrawString($Text, $fontBody, [System.Drawing.Brushes]::Black, ($X + 14), ($Y + 42))
}

# Rounded rectangle helpers for .NET without direct API
Update-TypeData -TypeName System.Drawing.Graphics -MemberName FillRoundedRectangle -MemberType ScriptMethod -Value {
  param($brush, $rect, $radius)
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $radius * 2
  $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
  $path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
  $path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
  $path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  $this.FillPath($brush, $path)
  $path.Dispose()
} -Force

Update-TypeData -TypeName System.Drawing.Graphics -MemberName DrawRoundedRectangle -MemberType ScriptMethod -Value {
  param($pen, $rect, $radius)
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $radius * 2
  $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
  $path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
  $path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
  $path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  $this.DrawPath($pen, $path)
  $path.Dispose()
} -Force

$g.DrawString('TF11 - Arquitetura S3 + CloudFront + Serverless', $fontTitle, [System.Drawing.Brushes]::Black, 26, 20)

Draw-Node -Canvas $g -X 70 -Y 150 -W 220 -H 110 -Title 'Usuario' -Text 'Browser desktop/mobile' -Color ([System.Drawing.Color]::FromArgb(227, 242, 253))
Draw-Node -Canvas $g -X 360 -Y 130 -W 250 -H 130 -Title 'CloudFront CDN' -Text 'HTTPS + cache + headers' -Color ([System.Drawing.Color]::FromArgb(225, 245, 254))
Draw-Node -Canvas $g -X 690 -Y 70 -W 280 -H 130 -Title 'S3 Website Bucket' -Text 'index/projetos/contato/error' -Color ([System.Drawing.Color]::FromArgb(232, 245, 233))
Draw-Node -Canvas $g -X 690 -Y 240 -W 280 -H 130 -Title 'S3 Assets Bucket' -Text 'uploads/raw e uploads/optimized' -Color ([System.Drawing.Color]::FromArgb(232, 245, 233))
Draw-Node -Canvas $g -X 1010 -Y 240 -W 300 -H 130 -Title 'Lambda Image Processor' -Text 'trigger S3 em uploads/raw/' -Color ([System.Drawing.Color]::FromArgb(255, 243, 224))
Draw-Node -Canvas $g -X 360 -Y 420 -W 250 -H 130 -Title 'API Gateway' -Text 'rotas /contact e /upload' -Color ([System.Drawing.Color]::FromArgb(243, 229, 245))
Draw-Node -Canvas $g -X 690 -Y 420 -W 280 -H 130 -Title 'Lambda Contact + Upload' -Text 'presigned URL e persiste contato' -Color ([System.Drawing.Color]::FromArgb(255, 243, 224))
Draw-Node -Canvas $g -X 1010 -Y 420 -W 300 -H 130 -Title 'DynamoDB' -Text 'tabela tf11-contacts-6324064' -Color ([System.Drawing.Color]::FromArgb(239, 235, 233))

function Draw-Arrow {
  param([int]$x1,[int]$y1,[int]$x2,[int]$y2)
  $g.DrawLine($pen, $x1, $y1, $x2, $y2)
  $size = 8
  $p1 = [System.Drawing.Point]::new($x2, $y2)
  $p2 = [System.Drawing.Point]::new(($x2 - $size), ($y2 - $size))
  $p3 = [System.Drawing.Point]::new(($x2 - $size), ($y2 + $size))
  $g.FillPolygon($arrowBrush, [System.Drawing.Point[]]@($p1, $p2, $p3))
}

Draw-Arrow 290 205 360 195
Draw-Arrow 610 170 690 135
Draw-Arrow 610 210 690 290
Draw-Arrow 970 305 1010 305
Draw-Arrow 610 485 690 485
Draw-Arrow 970 485 1010 485
Draw-Arrow 180 260 420 420

$legend = @(
  'Fluxo principal: Usuario -> CloudFront -> S3 Website',
  'Upload: Usuario -> API Gateway -> Lambda Upload -> S3 Assets (raw)',
  'Processamento: S3 event -> Lambda Image Processor -> assets optimized',
  'Contato: API Gateway -> Lambda Contact -> DynamoDB'
)

$y = 620
foreach ($line in $legend) {
  $g.DrawString($line, $fontBody, [System.Drawing.Brushes]::Black, 80, $y)
  $y += 30
}

$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
$pen.Dispose()
$arrowBrush.Dispose()
$fontTitle.Dispose()
$fontLabel.Dispose()
$fontBody.Dispose()

Write-Output "ARQ_PNG=$outPath"
