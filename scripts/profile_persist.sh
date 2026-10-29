cd ~/duckdb-24848-v1.5.5
set -euo pipefail

BACKUP_DIR="bench24848/current_main/persist_profile_backup"

if [ -e "$BACKUP_DIR" ]; then
    echo "Backup already exists: $BACKUP_DIR"
    echo "Do not overwrite it. Inspect the directory first."
    exit 1
fi

mkdir -p "$BACKUP_DIR"
cp src/execution/index/art/art.cpp "$BACKUP_DIR/"
cp src/execution/index/fixed_size_allocator.cpp "$BACKUP_DIR/"

python3 - <<'PY'
from pathlib import Path
import re

art_path = Path("src/execution/index/art/art.cpp")
allocator_path = Path("src/execution/index/fixed_size_allocator.cpp")

art = art_path.read_text()
allocator = allocator_path.read_text()

def replace_once(text, pattern, replacement, label):
    result, count = re.subn(pattern, replacement, text, count=1)
    if count != 1:
        raise RuntimeError(
            f"{label}: expected one match, found {count}. "
            "The source files were not written."
        )
    return result

def add_headers(text):
    headers = []
    if "#include <chrono>" not in text:
        headers.append("#include <chrono>\n")
    if "#include <cstdio>" not in text:
        headers.append("#include <cstdio>\n")
    return "".join(headers) + text

# Add outer ART allocator indices so each inner persistence report is identifiable.
art = add_headers(art)

art = replace_once(
    art,
    r"(?m)^([ \t]*)new_allocator = "
    r"\(\*allocators\)\[i\]->Persist\(partial_block_manager\);",
    r'''\1std::fprintf(stderr, "ART_ALLOCATOR_PERSIST_BEGIN index=%llu\\n",
\1             static_cast<unsigned long long>(i));
\1const auto allocator_profile_start = std::chrono::steady_clock::now();
\1new_allocator = (*allocators)[i]->Persist(partial_block_manager);
\1std::fprintf(stderr, "ART_ALLOCATOR_PERSIST_END index=%llu elapsed_sec=%.6f\\n",
\1             static_cast<unsigned long long>(i),
\1             std::chrono::duration<double>(
\1                 std::chrono::steady_clock::now() - allocator_profile_start).count());''',
    "ART allocator timing"
)

# Instrument FixedSizeAllocator::Persist independently.
allocator = add_headers(allocator)

start_marker = (
    "unsafe_unique_ptr<FixedSizeAllocator> FixedSizeAllocator::Persist("
    "PartialBlockManager &partial_block_manager) {"
)
end_marker = "vector<IndexBufferInfo> FixedSizeAllocator::InitSerializationToWAL()"

start = allocator.index(start_marker)
end = allocator.index(end_marker, start)
section = allocator[start:end]

section = replace_once(
    section,
    re.escape(start_marker),
    start_marker + r'''
        const auto profile_start = std::chrono::steady_clock::now();
        idx_t profile_visited = 0;
        idx_t profile_empty = 0;
        idx_t profile_requires_persist = 0;
        idx_t profile_shared_clean = 0;
        double profile_buffer_persist_sec = 0.0;
''',
    "Allocator profile initialization"
)

section = replace_once(
    section,
    r"for \(auto &\[buffer_id, buffer\] : buffers\) \{",
    "for (auto &[buffer_id, buffer] : buffers) {\n"
    "                ++profile_visited;",
    "Buffer iteration count"
)

section = replace_once(
    section,
    r"if \(buffer->IsEmpty\(\)\) \{\s*continue;",
    "if (buffer->IsEmpty()) {\n"
    "                        ++profile_empty;\n"
    "                        continue;",
    "Empty buffer count"
)

section = replace_once(
    section,
    r"if \(buffer->RequiresPersist\(\)\) \{\s*"
    r"(result->buffers\[buffer_id\]\s*=\s*buffer->Persist\(partial_block_manager,\s*"
    r"available_segments_per_buffer,\s*segment_size,\s*bitmask_offset\);)",
    r'''if (buffer->RequiresPersist()) {
                        ++profile_requires_persist;
                        const auto buffer_profile_start = std::chrono::steady_clock::now();
                        \1
                        profile_buffer_persist_sec += std::chrono::duration<double>(
                            std::chrono::steady_clock::now() - buffer_profile_start).count();''',
    "Dirty or non-disk buffer timing"
)

section = replace_once(
    section,
    r"\} else \{\s*result->buffers\[buffer_id\] = buffer;",
    "} else {\n"
    "                        ++profile_shared_clean;\n"
    "                        result->buffers[buffer_id] = buffer;",
    "Clean buffer count"
)

section = replace_once(
    section,
    r"result->NextBufferWithFreeSpace\(\);\s*return result;",
    r'''result->NextBufferWithFreeSpace();

        std::fprintf(stderr,
                     "FIXED_SIZE_ALLOCATOR_PROFILE segment_size=%llu registered=%llu "
                     "visited=%llu empty=%llu requires_persist=%llu shared_clean=%llu "
                     "buffer_persist_sec=%.6f total_sec=%.6f\\n",
                     static_cast<unsigned long long>(segment_size),
                     static_cast<unsigned long long>(buffers.size()),
                     static_cast<unsigned long long>(profile_visited),
                     static_cast<unsigned long long>(profile_empty),
                     static_cast<unsigned long long>(profile_requires_persist),
                     static_cast<unsigned long long>(profile_shared_clean),
                     profile_buffer_persist_sec,
                     std::chrono::duration<double>(
                         std::chrono::steady_clock::now() - profile_start).count());

        return result;''',
    "Allocator profiling output"
)

allocator = allocator[:start] + section + allocator[end:]

# Write only after all expected source patterns matched.
art_path.write_text(art)
allocator_path.write_text(allocator)

print("Temporary ART and allocator instrumentation added.")
print("Backups:", "bench24848/current_main/persist_profile_backup")
PY