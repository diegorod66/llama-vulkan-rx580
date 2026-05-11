# llama-vulkan-rx580 v2.0.0 — Guia Rapida

**llama.cpp con backend Vulkan optimizado para AMD RX 580 (Polaris).**
Soporta de **1 a 5 GPUs** en modo `layer-split`. Escalable sin recompilar.

---

## Requisitos

- Servidor Linux (Debian 12+ / Ubuntu 24+)
- GPU AMD RX 580 con drivers Vulkan:
  ```bash
  sudo apt install mesa-vulkan-drivers vulkan-tools libvulkan1
  ```
- Un modelo en formato `.gguf` (descargar de Hugging Face)

---

## Instalacion (1 comando)

```bash
sudo ./deploy/install.sh
```

El instalador:
1. Detecta cuantas GPUs Vulkan hay disponibles
2. Calcula `ctx-size` optimo segun VRAM total
3. Configura `--split-mode layer` (2+ GPUs) o `none` (1 GPU)
4. Crea el servicio systemd
5. Te pide la ruta del modelo `.gguf`

---

## Agregar o quitar GPUs

**No necesitas recompilar ni reinstalar.**

```bash
# 1. Instala o remueve la GPU fisicamente
# 2. Solo reinicia el servicio:
sudo systemctl restart llama-server
```

El servicio detecta automaticamente las GPUs disponibles al iniciar.

---

## Cambiar de modelo

**No necesitas recompilar ni reinstalar.**

```bash
# 1. Descarga otro archivo .gguf
# 2. Edita la configuracion:
sudo vi /etc/llama-server/llama-server.env
#    Cambia MODEL_PATH=/ruta/al/nuevo-modelo.gguf

# 3. Reinicia:
sudo systemctl restart llama-server
```

---

## Comandos utiles

```bash
# Estado del servicio
sudo systemctl status llama-server

# Ver logs en vivo
sudo journalctl -u llama-server -f

# Ver GPUs detectadas
vulkaninfo --summary | grep -i deviceName

# Control manual de GPUs
export GGML_VK_VISIBLE_DEVICES=0,1,2   # usa GPUs 0,1,2
```

---

## Modelos recomendados segun # GPUs

| GPUs | VRAM  | Modelo recomendado (Q4_K_M)          | Tamano |
|------|-------|--------------------------------------|--------|
| 1    | 8 GB  | Llama 3.2 3B, Phi-3-mini             | ~2 GB  |
| 2    | 16 GB | Mistral 7B, Llama 3.1 8B, Qwen 2.5 7B | ~5 GB |
| 3    | 24 GB | Qwen 2.5 14B, CodeQwen 7B (ctx grande)| ~9 GB |
| 4    | 32 GB | Llama 3 70B (Q2_K), DeepSeek R1 32B  | ~18 GB |
| 5    | 40 GB | Llama 3 70B (Q3_K), Qwen 2.5 32B     | ~22 GB |

Donde descargar: https://huggingface.co/TheBloke o https://huggingface.co/lmstudio-community

---

## Probar el servidor

```bash
# Test rapido
curl -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model":"model",
    "messages":[{"role":"user","content":"Hola"}],
    "max_tokens":50
  }'

# Usar el script incluido
./examples/quick-test.sh
```

---

## Solucion de problemas

| Problema | Solucion |
|----------|----------|
| `VK_ERROR_DEVICE_LOST` | GPU no soportada o falta el parche cooperative_matrix |
| `ErrorOutOfDeviceMemory` | Reduce `--ctx-size` o `--batch-size` |
| `No Vulkan devices found` | Verifica drivers: `sudo apt install mesa-vulkan-drivers` |
| Servicio no inicia | `sudo journalctl -u llama-server -e` para ver el error exacto |
| Output es basura (repeticiones) | Cambia `--split-mode row` a `--split-mode layer` |

---

## Recompilar para nueva version

```bash
# Manual (en el servidor):
./scripts/build.sh

# Automatico (GitHub Actions):
#   Sube el repo a GitHub -> Actions -> Run workflow
#   Descarga el artifact en binaries-v2.0.0/
```

---

## Desinstalar

```bash
sudo ./deploy/uninstall.sh
```
