#!/usr/bin/env python3
"""patch-cooperative-matrix.py :: v2.0.0
Forces cooperative_matrix=OFF in llama.cpp's Vulkan CMakeLists.txt.
Needed for AMD Polaris GPUs (RX 580) which lack cooperative matrix support.

Usage: python3 scripts/patch-cooperative-matrix.py <path-to-llama.cpp>
"""

import re
import sys


def patch_cmakelists(cmakelists_path: str) -> bool:
    with open(cmakelists_path, "r") as f:
        content = f.read()

    if "cooperative_matrix.*forced OFF" in content or "cooperative_matrix forced OFF" in content:
        print("Patch already applied, skipping.")
        return True

    pattern = (
        r"(function\(test_shader_extension_support\s+"
        r"EXTENSION_NAME\s+TEST_SHADER_FILE\s+"
        r"RESULT_VARIABLE\))"
    )

    replacement = (
        r"\1\n"
        r'    if(EXTENSION_NAME MATCHES "cooperative_matrix")\n'
        r"        set(\${RESULT_VARIABLE} OFF PARENT_SCOPE)\n"
        r'        message(STATUS "\${EXTENSION_NAME} forced OFF")\n'
        r"        return()\n"
        r"    endif()"
    )

    new_content = re.sub(pattern, replacement, content)
    if new_content == content:
        print("ERROR: Pattern not found in CMakeLists.txt", file=sys.stderr)
        return False

    with open(cmakelists_path, "w") as f:
        f.write(new_content)

    print("Patch applied successfully.")
    return True


def main() -> None:
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <path-to-llama.cpp>", file=sys.stderr)
        sys.exit(1)

    base_dir = sys.argv[1]
    cmakelists_path = f"{base_dir}/ggml/src/ggml-vulkan/CMakeLists.txt"

    if not patch_cmakelists(cmakelists_path):
        sys.exit(1)


if __name__ == "__main__":
    main()
