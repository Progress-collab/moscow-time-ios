# Скрипт для быстрого обновления iOS приложения
# Автоматизирует процесс: git add, commit, push

param(
    [string]$Message = "",
    [switch]$OpenActions = $false
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 MoscowTime App Update Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Проверка, что мы в git репозитории
if (-not (Test-Path .git)) {
    Write-Host "❌ Ошибка: Это не git репозиторий!" -ForegroundColor Red
    exit 1
}

# Проверка изменений
Write-Host "📋 Проверка изменений..." -ForegroundColor Yellow
$status = git status --porcelain

if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "ℹ️  Нет изменений для коммита." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Хотите запустить сборку существующего кода? (y/n): " -NoNewline
    $response = Read-Host
    if ($response -ne "y" -and $response -ne "Y") {
        exit 0
    }
} else {
    Write-Host "✅ Найдены изменения:" -ForegroundColor Green
    git status --short
    Write-Host ""
    
    # Добавление всех изменений
    Write-Host "➕ Добавление изменений..." -ForegroundColor Yellow
    git add .
    
    # Запрос сообщения коммита
    if ([string]::IsNullOrWhiteSpace($Message)) {
        Write-Host ""
        Write-Host "💬 Введите сообщение коммита (или нажмите Enter для автоматического): " -NoNewline
        $Message = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($Message)) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $Message = "Update: $timestamp"
        }
    }
    
    # Создание коммита
    Write-Host ""
    Write-Host "💾 Создание коммита: $Message" -ForegroundColor Yellow
    git commit -m $Message
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Ошибка при создании коммита!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Коммит создан успешно!" -ForegroundColor Green
}

# Push в GitHub
Write-Host ""
Write-Host "📤 Отправка изменений в GitHub..." -ForegroundColor Yellow
git push

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка при отправке в GitHub!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Изменения отправлены успешно!" -ForegroundColor Green

# Получение информации о репозитории
$remoteUrl = git config --get remote.origin.url
if ($remoteUrl -match "github.com[:/]([^/]+)/([^/]+?)(?:\.git)?$") {
    $owner = $matches[1]
    $repo = $matches[2]
    $actionsUrl = "https://github.com/$owner/$repo/actions"
    $releasesUrl = "https://github.com/$owner/$repo/releases"
    
    Write-Host ""
    Write-Host "🎉 Готово!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 GitHub Actions: $actionsUrl" -ForegroundColor Cyan
    Write-Host "📦 Releases: $releasesUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⏳ Сборка начнется автоматически через несколько секунд..." -ForegroundColor Yellow
    Write-Host "   Обычно сборка занимает 5-10 минут." -ForegroundColor Yellow
    
    # Опционально открыть страницу Actions
    if ($OpenActions) {
        Write-Host ""
        Write-Host "🌐 Открываю страницу GitHub Actions..." -ForegroundColor Yellow
        Start-Process $actionsUrl
    } else {
        Write-Host ""
        Write-Host "💡 Совет: Используйте -OpenActions для автоматического открытия страницы Actions" -ForegroundColor Gray
    }
} else {
    Write-Host ""
    Write-Host "✅ Готово! Проверьте GitHub Actions вручную." -ForegroundColor Green
}

Write-Host ""

