# v1.0.0 — Binarios originales

## Origen
Extraídos de `binaries-full.tar.gz`. Compilados para Linux (Debian/Ubuntu) con backend Vulkan.

## Contenido
```
llama-server              9.5 MB   Servidor principal
libllama.so.0.0.1         3.5 MB   Librería core llama
libllama-common.so.0.0.1  5.4 MB   Utilidades comunes
libggml.so.0.11.0          55 KB   GGML base (stub)
libggml-base.so.0.11.0   817 KB    GGML backend base
libggml-cpu.so.0.11.0    1.1 MB    Backend CPU
libggml-vulkan.so.0.11.0  39 MB    Backend Vulkan
libmtmd.so.0.0.1         1.2 MB    Memoria multi-thread
```

## Versiones
- ggml: 0.11.0
- llama.cpp: commit correspondiente a la fecha de empaquetado

## Limitaciones conocidas
- No soporta arquitecturas de modelos muy recientes (anteriores a la fecha de compilación)
- Limitado a 2 GPUs en la documentación original (aunque el backend soporta N GPUs)
- Split-mode por defecto: `row` (deprecado en versiones recientes)
- Los symlinks (.so → .so.0 → .so.X.Y.Z) los crea `ldconfig` en el sistema destino

## Instalación
```bash
./deploy/install.sh
```
El instalador detecta automáticamente la versión y configura el servicio.
