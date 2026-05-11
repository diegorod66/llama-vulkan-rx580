#!/bin/bash
# glslc wrapper — translates glslc-compatible arguments to glslangValidator.
# Installed as /usr/local/bin/glslc when glslc is not available natively.
# 
# glslc syntax:  glslc -o <out> -fshader-stage=<stage> [flags] <input>
# glslangValidator syntax: glslangValidator -V -o <out> [flags] <input>

set -euo pipefail

GLSLC_DEBUG="${GLSLC_DEBUG:-0}"

# glslangValidator path — same dir as this wrapper, or from PATH
GLSLC_WRAPPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLSLANG_VALIDATOR=""
for candidate in "$GLSLC_WRAPPER_DIR/glslangValidator" /usr/bin/glslangValidator /usr/local/bin/glslangValidator; do
    if [ -x "$candidate" ]; then
        GLSLANG_VALIDATOR="$candidate"
        break
    fi
done

if [ -z "$GLSLANG_VALIDATOR" ]; then
    echo "ERROR: glslc wrapper: glslangValidator not found" >&2
    exit 1
fi

ARGS=()
INPUT_FILE=""
SKIP_NEXT=0

for arg in "$@"; do
    if [ "$SKIP_NEXT" -eq 1 ]; then
        SKIP_NEXT=0
        ARGS+=("$arg")
        continue
    fi

    case "$arg" in
        # glslangValidator detects stage from file extension — skip -fshader-stage=
        -fshader-stage=*) ;;
        -f*) 
            # Catch other -f flags (like -fauto-bind-uniforms, etc.) — pass through
            ARGS+=("$arg")
            ;;
        # Translate = syntax to space syntax for --target-env
        --target-env=*)
            ARGS+=("--target-env" "${arg#*=}")
            ;;
        # Skip --target-env value (handled above for = syntax, or passed through)
        --target-env)
            ARGS+=("$arg")
            SKIP_NEXT=0  # Let the next arg pass through
            ;;
        # Pass -o and its value through directly
        -o)
            ARGS+=("$arg")
            SKIP_NEXT=1
            ;;
        # Other arguments like --keep-uncalled, warnings, etc.
        -*)
            ARGS+=("$arg")
            ;;
        # Positional argument = input file
        *)
            if [ -z "$INPUT_FILE" ]; then
                INPUT_FILE="$arg"
            else
                ARGS+=("$arg")
            fi
            ;;
    esac
done

if [ -z "$INPUT_FILE" ]; then
    echo "ERROR: glslc wrapper: no input file specified" >&2
    exit 1
fi

if [ "$GLSLC_DEBUG" -eq 1 ]; then
    echo "DEBUG glslc wrapper:" >&2
    echo "  input: $INPUT_FILE" >&2
    echo "  validator: $GLSLANG_VALIDATOR" >&2
    echo "  args: ${ARGS[*]}" >&2
fi

exec "$GLSLANG_VALIDATOR" -V "${ARGS[@]}" "$INPUT_FILE"
