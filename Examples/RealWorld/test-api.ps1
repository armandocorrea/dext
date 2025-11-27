# DextStore API Test Script
# Tests all endpoints of the DextStore API

$baseUrl = "http://localhost:9000"
$token = ""

Write-Host "🧪 DextStore API Test Suite" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Test 1: Health Check
Write-Host "1️⃣  Testing Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "✅ Health Check: " -ForegroundColor Green -NoNewline
    Write-Host ($response | ConvertTo-Json -Compress)
}
catch {
    Write-Host "❌ Health Check Failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 2: Login
Write-Host "2️⃣  Testing Login..." -ForegroundColor Yellow
try {
    $loginBody = @{
        username = "user"
        password = "password"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody
    
    $token = $response.token
    Write-Host "✅ Login Successful!" -ForegroundColor Green
    Write-Host "   Token: $($token.Substring(0, 20))..." -ForegroundColor Gray
}
catch {
    Write-Host "❌ Login Failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 3: Get All Products
Write-Host "3️⃣  Testing Get All Products..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/products/" -Method Get
    Write-Host "✅ Products Retrieved: $($response.Count) items" -ForegroundColor Green
    $response | ForEach-Object {
        Write-Host "   - $($_.Name): `$$($_.Price)" -ForegroundColor Gray
    }
}
catch {
    Write-Host "❌ Get Products Failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 4: Get Product by ID
Write-Host "4️⃣  Testing Get Product by ID..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/products/1" -Method Get
    Write-Host "✅ Product Retrieved: $($response.Name)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Get Product by ID Failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 5: Add Item to Cart
Write-Host "5️⃣  Testing Add Item to Cart..." -ForegroundColor Yellow
try {
    $cartBody = @{
        productId = 1
        quantity  = 2
    } | ConvertTo-Json

    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }

    $response = Invoke-RestMethod -Uri "$baseUrl/api/cart/items" `
        -Method Post `
        -Headers $headers `
        -Body $cartBody
    
    Write-Host "✅ Item Added to Cart!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Add to Cart Failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 6: Get Cart
Write-Host "6️⃣  Testing Get Cart..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }

    $response = Invoke-RestMethod -Uri "$baseUrl/api/cart/" `
        -Method Get `
        -Headers $headers
    
    Write-Host "✅ Cart Retrieved!" -ForegroundColor Green
    Write-Host "   Total: `$$($response.totalAmount)" -ForegroundColor Gray
    Write-Host "   Items: $($response.items.Count)" -ForegroundColor Gray
}
catch {
    Write-Host "❌ Get Cart Failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 7: Checkout
Write-Host "7️⃣  Testing Checkout..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }

    $response = Invoke-RestMethod -Uri "$baseUrl/api/orders/checkout" `
        -Method Post `
        -Headers $headers
    
    Write-Host "✅ Order Placed!" -ForegroundColor Green
    Write-Host "   Order ID: $($response.orderId)" -ForegroundColor Gray
    Write-Host "   Total: `$$($response.total)" -ForegroundColor Gray
    Write-Host "   Status: $($response.status)" -ForegroundColor Gray
}
catch {
    Write-Host "❌ Checkout Failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 8: Get Orders
Write-Host "8️⃣  Testing Get Orders..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }

    $response = Invoke-RestMethod -Uri "$baseUrl/api/orders/" `
        -Method Get `
        -Headers $headers
    
    Write-Host "✅ Orders Retrieved: $($response.Count) orders" -ForegroundColor Green
}
catch {
    Write-Host "❌ Get Orders Failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ Test Suite Completed!" -ForegroundColor Green
