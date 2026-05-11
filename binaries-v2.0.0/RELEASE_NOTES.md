# v2.0.0 — Binarios compilados desde fuente

## Estado: PENDIENTE DE COMPILAR

Esta carpeta contiene los binarios compilados desde la última versión de llama.cpp.
Se genera automáticamente mediante:

### Opción A: GitHub Actions (recomendada)
1. Sube este repositorio a GitHub
2. Ve a Actions → `Build llama.cpp Vulkan` → Run workflow
3. Descarga el artifact `binaries-v2.0.0.zip`
4. Extrae el contenido aquí

### Opción B: Compilación manual
```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

## Mejoras respecto a v1.0.0
- Binarios del **último llama.cpp master** (no limitados a la versión empaquetada)
- Soporte para modelos recién lanzados (DeepSeek, Qwen 2.5, etc.)
- Últimas optimizaciones del backend Vulkan
- Split-mode por defecto: `layer` (mejor rendimiento en PCIe)
- Correcciones de bugs posteriores a ggml 0.11.0

## Requisitos de compilación
- Ubuntu 24.04 / Debian 13 (o superior)
- CMake ≥ 3.14
- Vulkan SDK (glslc, libvulkan-dev)
- 8 GB RAM mínimo para compilar

## Versiones esperadas
- ggml: última disponible
- llama.cpp: última disponible
