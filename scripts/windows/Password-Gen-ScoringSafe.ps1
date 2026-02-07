param([int]$Len = 16)

# Packet allowed: alphanumeric + only )(’.,@|=:;/-!
# Use ASCII apostrophe to avoid encoding issues.
$alnum = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
$spec  = ")('.,@|=:;/-!"
$chars = ($alnum + $spec).ToCharArray()

$rand = New-Object System.Random
$pw = -join (1..$Len | ForEach-Object { $chars[$rand.Next(0, $chars.Length)] })
$pw
