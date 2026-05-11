# llama-vulkan-rx580

**llama.cpp con backend Vulkan optimizado para AMD RX 580 (Polaris).**
Soporta de 1 a 5 GPUs. Escalable sin recompilar.

> Version actual: **2.0.0** · [CHANGELOG](CHANGELOG.md) · [Guia Rapida](GUIA_RAPIDA.md)

---

## Estructura del proyecto

```
llama-vulkan-rx580/
├── VERSION                  Numero de version actual
├── CHANGELOG.md             Registro de cambios por version
├── README.md                Este archivo
├── GUIA_RAPIDA.md           Guia rapida de 1 pagina (espanol)
│
├── binaries-v1.0.0/         Binarios originales (ggml 0.11.0)
│   ├── llama-server         Servidor principal
│   ├── libggml-vulkan.so    Backend Vulkan (39 MB)
│   └── ...
│
├── binaries-v2.0.0/         Binarios compilados desde fuente
│   └── (generar con scripts/build.sh o GitHub Actions)
│
├── deploy/
│   ├── install.sh           Instalador automatico
│   └── uninstall.sh         Desinstalador
│
├── scripts/
│   ├── build.sh             Compila llama.cpp con parche Polaris
│   └── package.sh           Empaqueta release para distribuir
│
├── systemd/
│   └── llama-server.service Template del servicio systemd
│
├── source/                  Parches originales (ggml-vulkan CMakeLists)
│
├── .github/workflows/
│   └── build.yml            GitHub Actions CI para compilar v2.0.0
│
└── examples/
    └── quick-test.sh         Prueba rapida del servidor
```

---

## Instalacion rapida

```bash
sudo ./deploy/install.sh
```

El instalador detecta automaticamente:
- Cuantas GPUs Vulkan hay disponibles
- La VRAM total estimada
- Los parametros optimos (ctx-size, split-mode, batch-size)

[Ver guia rapida completa →](GUIA_RAPIDA.md)

---

## Compilar desde fuente (v2.0.0+)

### Opcion A: GitHub Actions (recomendada)
1. Sube este repositorio a tu cuenta de GitHub
2. Ve a **Actions** → **Build llama.cpp Vulkan** → **Run workflow**
3. Descarga el artifact `binaries-v2.0.0.zip`
4. Extrae el contenido en `binaries-v2.0.0/`

### Opcion B: Compilacion manual en el servidor
```bash
sudo apt install build-essential cmake git libvulkan-dev vulkan-tools lld
./scripts/build.sh
```

Compila desde el ultimo llama.cpp master con el parche `cooperative_matrix=OFF`.

---

## Versionado

Este proyecto usa [Versionado Semantico](https://semver.org/):

| Version | Binarios | Modelos soportados | Split-mode |
|---------|----------|--------------------|------------|
| 1.0.0   | Originales (tar.gz) | Hasta fecha de compilacion | row |
| 2.0.0   | Compilados de master | Ultimas arquitecturas | layer |

Ver [CHANGELOG.md](CHANGELOG.md) para cambios detallados.

---

## Creditos

- [llama.cpp](https://github.com/ggml-org/llama.cpp) por el motor de inferencia
- [0cc4m](https://github.com/0cc4m) por el backend Vulkan multi-GPU
- Guia original de compilacion para Polaris incluida en `source/`
