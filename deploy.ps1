# PowerShell deployment script for chatProxy Google Cloud Function
# Usage: .\deploy.ps1 -ApiKey "your-api-key" -Model "deepseek-r1"

param(
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    
    [Parameter(Mandatory=$true)]
    [string]$Model
)

Write-Host "Deploying chatProxy Google Cloud Function..." -ForegroundColor Green
Write-Host "Model: $Model" -ForegroundColor Yellow

# Deploy the function
$deployCommand = @"
gcloud functions deploy chatProxy --runtime nodejs18 --trigger-http --allow-unauthenticated --memory 256MB --timeout 540s --set-env-vars "OPENROUTER_API_KEY=$ApiKey,DEFAULT_MODEL=$Model" --source . --entry-point chatProxy
"@

Write-Host "Executing deployment command..." -ForegroundColor Blue
Invoke-Expression $deployCommand

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your function is now available at:" -ForegroundColor Yellow
    
    # Get the function URL
    $functionUrl = gcloud functions describe chatProxy --format="value(httpsTrigger.url)"
    Write-Host $functionUrl -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "Test with PowerShell:" -ForegroundColor Yellow
    Write-Host "Invoke-RestMethod -Uri '$functionUrl' -Method POST -ContentType 'application/json' -Body '{\"history\":[],\"prompt\":\"Hello!\"}'" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Test with curl:" -ForegroundColor Yellow
    Write-Host "curl -X POST $functionUrl -H 'Content-Type: application/json' -d '{\"history\":[],\"prompt\":\"Hello!\"}'" -ForegroundColor Gray
} else {
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
    exit 1
}
