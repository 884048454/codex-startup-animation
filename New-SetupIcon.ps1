param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$bitmap = [System.Drawing.Bitmap]::new(256, 256)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::Transparent)

$shape = New-Object System.Drawing.Drawing2D.GraphicsPath
$shape.AddArc(20, 20, 216, 216, 180, 90)
$shape.AddArc(20, 20, 216, 216, 270, 90)
$shape.AddArc(20, 20, 216, 216, 0, 90)
$shape.AddArc(20, 20, 216, 216, 90, 90)
$shape.CloseFigure()
$background = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(22, 39, 59))
$graphics.FillPath($background, $shape)

$ring = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(64, 153, 220), 17)
$ring.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$ring.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$graphics.DrawArc($ring, 57, 57, 142, 142, 210, 285)

$spark = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
$graphics.FillEllipse($spark, 157, 70, 28, 28)
$accent = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(122, 205, 255))
$graphics.FillEllipse($accent, 178, 55, 14, 14)

$png = [System.IO.MemoryStream]::new()
$bitmap.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
$pngBytes = $png.ToArray()
$fullPath = [System.IO.Path]::GetFullPath($OutputPath)
$parent = [System.IO.Path]::GetDirectoryName($fullPath)
if (-not [System.IO.Directory]::Exists($parent)) { [System.IO.Directory]::CreateDirectory($parent) | Out-Null }

$stream = [System.IO.File]::Open($fullPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
$writer = [System.IO.BinaryWriter]::new($stream)
$writer.Write([UInt16]0)
$writer.Write([UInt16]1)
$writer.Write([UInt16]1)
$writer.Write([Byte]0)
$writer.Write([Byte]0)
$writer.Write([Byte]0)
$writer.Write([Byte]0)
$writer.Write([UInt16]1)
$writer.Write([UInt16]32)
$writer.Write([UInt32]$pngBytes.Length)
$writer.Write([UInt32]22)
$writer.Write($pngBytes)
$writer.Dispose()
$png.Dispose()
$graphics.Dispose()
$bitmap.Dispose()
$shape.Dispose()
$background.Dispose()
$ring.Dispose()
$spark.Dispose()
$accent.Dispose()
Write-Host "Setup icon created: $fullPath"
