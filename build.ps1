# Fonction pour vérifier si un chemin Java est valide
function Test-JavaPath {
    param([string]$Path)
    
    if (Test-Path $Path) {
        $javaExe = Join-Path $Path "bin\java.exe"
        if (Test-Path $javaExe) {
            return $true
        }
    }
    return $false
}

# Fonction pour trouver le chemin Java
function Find-JavaHome {
    # Essayer le chemin spécifique fourni
    $specificPath = "C:\Program Files\Java\jdk-11"
    if (Test-JavaPath $specificPath) {
        Write-Host "Java trouvé dans le chemin spécifique: $specificPath"
        return $specificPath
    }

    # Essayer JAVA_HOME
    $javaHome = $env:JAVA_HOME
    if ($javaHome -and (Test-JavaPath $javaHome)) {
        Write-Host "Java trouvé dans JAVA_HOME: $javaHome"
        return $javaHome
    }

    # Essayer de trouver via java -version
    try {
        $javaVersion = java -version 2>&1 | Select-String -Pattern 'version "(.*)"' | ForEach-Object { $_.Matches.Groups[1].Value }
        Write-Host "Java version détectée: $javaVersion"
        
        # Construire les chemins possibles
        $programFiles = $env:ProgramFiles
        $programFilesX86 = ${env:ProgramFiles(x86)}
        $possiblePaths = @(
            "C:\Program Files\Java\jdk-11",
            "C:\Program Files\Java\jdk-11.0.21",
            "C:\Program Files\Java\jdk-11.0.20",
            "C:\Program Files\Java\jdk-11.0.19",
            "C:\Program Files\Java\jdk-11.0.18",
            "C:\Program Files\Java\jdk-11.0.17",
            "C:\Program Files\Java\jdk-11.0.16",
            "C:\Program Files\Java\jdk-11.0.15",
            "C:\Program Files\Java\jdk-11.0.14",
            "C:\Program Files\Java\jdk-11.0.13",
            "C:\Program Files\Java\jdk-11.0.12",
            "C:\Program Files\Java\jdk-11.0.11",
            "C:\Program Files\Java\jdk-11.0.10",
            "C:\Program Files\Java\jdk-11.0.9",
            "C:\Program Files\Java\jdk-11.0.8",
            "C:\Program Files\Java\jdk-11.0.7",
            "C:\Program Files\Java\jdk-11.0.6",
            "C:\Program Files\Java\jdk-11.0.5",
            "C:\Program Files\Java\jdk-11.0.4",
            "C:\Program Files\Java\jdk-11.0.3",
            "C:\Program Files\Java\jdk-11.0.2",
            "C:\Program Files\Java\jdk-11.0.1",
            "$programFilesX86\Java\jdk-11",
            "$programFilesX86\Java\jdk-11.0.21",
            "$programFilesX86\Java\jdk-11.0.20",
            "$programFilesX86\Java\jdk-11.0.19",
            "$programFilesX86\Java\jdk-11.0.18",
            "$programFilesX86\Java\jdk-11.0.17",
            "$programFilesX86\Java\jdk-11.0.16",
            "$programFilesX86\Java\jdk-11.0.15",
            "$programFilesX86\Java\jdk-11.0.14",
            "$programFilesX86\Java\jdk-11.0.13",
            "$programFilesX86\Java\jdk-11.0.12",
            "$programFilesX86\Java\jdk-11.0.11",
            "$programFilesX86\Java\jdk-11.0.10",
            "$programFilesX86\Java\jdk-11.0.9",
            "$programFilesX86\Java\jdk-11.0.8",
            "$programFilesX86\Java\jdk-11.0.7",
            "$programFilesX86\Java\jdk-11.0.6",
            "$programFilesX86\Java\jdk-11.0.5",
            "$programFilesX86\Java\jdk-11.0.4",
            "$programFilesX86\Java\jdk-11.0.3",
            "$programFilesX86\Java\jdk-11.0.2",
            "$programFilesX86\Java\jdk-11.0.1",
            "C:\Java\jdk-11",
            "C:\Java\jdk-11.0.21",
            "C:\Java\jdk-11.0.20",
            "C:\Java\jdk-11.0.19",
            "C:\Java\jdk-11.0.18",
            "C:\Java\jdk-11.0.17",
            "C:\Java\jdk-11.0.16",
            "C:\Java\jdk-11.0.15",
            "C:\Java\jdk-11.0.14",
            "C:\Java\jdk-11.0.13",
            "C:\Java\jdk-11.0.12",
            "C:\Java\jdk-11.0.11",
            "C:\Java\jdk-11.0.10",
            "C:\Java\jdk-11.0.9",
            "C:\Java\jdk-11.0.8",
            "C:\Java\jdk-11.0.7",
            "C:\Java\jdk-11.0.6",
            "C:\Java\jdk-11.0.5",
            "C:\Java\jdk-11.0.4",
            "C:\Java\jdk-11.0.3",
            "C:\Java\jdk-11.0.2",
            "C:\Java\jdk-11.0.1"
        )

        Write-Host "Recherche de Java dans les chemins suivants :"
        foreach ($path in $possiblePaths) {
            Write-Host "Vérification de : $path"
            if (Test-JavaPath $path) {
                Write-Host "Java trouvé dans: $path"
                return $path
            }
        }

        # Essayer de trouver via where.exe
        $whereOutput = where.exe java 2>&1
        if ($whereOutput -and $whereOutput -notmatch "Could not find files") {
            $javaPath = $whereOutput | Select-Object -First 1
            $javaDir = Split-Path (Split-Path $javaPath -Parent) -Parent
            if (Test-JavaPath $javaDir) {
                Write-Host "Java trouvé via where.exe: $javaDir"
                return $javaDir
            }
        }
    }
    catch {
        Write-Host "Erreur lors de la détection de Java: $_"
    }

    Write-Host "Aucun chemin Java valide trouvé"
    return $null
}

# Définir l'encodage pour l'affichage
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Trouver le chemin Java
$javaHome = Find-JavaHome
if ($javaHome) {
    $env:JAVA_HOME = $javaHome
    Write-Host "Utilisation de Java: $javaHome"
} else {
    Write-Host "Erreur: Java non trouvé. Veuillez installer Java 11"
    exit 1
}

# Nettoyer le projet
Write-Host "Nettoyage du projet..."
flutter clean

# Mettre à jour les dépendances
Write-Host "Mise à jour des dépendances..."
flutter pub get

# Construire l'APK
Write-Host "Construction de l'APK..."
flutter build apk --release

# Vérifier si le build a réussi
if ($LASTEXITCODE -eq 0) {
    Write-Host "Build réussi !"
    Write-Host "APK généré dans: build/app/outputs/flutter-apk/app-release.apk"
} else {
    Write-Host "Erreur lors du build. Code de sortie: $LASTEXITCODE"
} 