# Changelog

## [2.0.0] — 2026-05-11

### Added
- Compilación automatizada via GitHub Actions (`.github/workflows/build.yml`)
- Binarios compilados desde el último llama.cpp master
- Soporte para arquitecturas de modelos más recientes (DeepSeek, Qwen 2.5, etc.)
- Script `deploy/install.sh` con detección dinámica de GPUs
- Script `deploy/uninstall.sh` para limpieza completa
- Guía rápida `GUIA_RAPIDA.md` en español
- Script `examples/quick-test.sh` para pruebas con curl

### Changed
- Split mode actualizado de `row` (deprecado) a `layer` (recomendado)
- Ctx-size se calcula automáticamente según VRAM total disponible
- Documentación reestructurada con versionado semántico

### Fixed
- El parche `cooperative_matrix=OFF` se mantiene para compatibilidad Polaris
- Mejores valores por defecto para batch-size y context-size

## [1.0.0] — 2026-05-10

### Added
- Guía original de compilación para llama.cpp + Vulkan + AMD RX 580
- Parche crítico `cooperative_matrix=OFF` para Polaris
- Binarios precompilados (ggml v0.11.0, llama-server funcional)
- Soporte para 2 GPUs en modo row-split
- Systemd service para arranque automático
- Integración con OpenClaw Gateway
