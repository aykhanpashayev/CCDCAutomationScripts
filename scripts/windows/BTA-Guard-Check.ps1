"== BTA Guard Check (Windows) @ $(Get-Date) =="

$paths = @(
  "C:\Program Files\BTA\bta.exe",
  "C:\Program Files\BTA\bta.enc",
  "C:\Program Files\BTA\bta.status"
)

foreach ($p in $paths) {
  if (Test-Path $p) {
    "[+] Found: $p"
    Get-Item $p | Format-List Length,LastWriteTime
  } else {
    "[-] Missing: $p"
  }
}

try { Get-Service -Name BTA | Format-List Name,Status,StartType }
catch { "[-] Service BTA not found." }

"Packet reminder: DO NOT block outbound to 10.250.250.11:443 and 169.254.169.254:80."
