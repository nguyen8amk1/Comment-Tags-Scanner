import os
import re
import argparse
import json
from collections import defaultdict

TAGS = ["TODO", "FIXME", "HACK", "NOTE", "BUG", "OPTIMIZE", "REVIEW"]
TAG_PATTERN = re.compile(r'#?\s*({}):?(.*)'.format('|'.join(TAGS)))  # supports Python/C/JS

def scan_dir(base_path, exts):
    for root, _, files in os.walk(base_path):
        for file in files:
            if not exts or any(file.endswith(ext) for ext in exts):
                yield os.path.join(root, file)

def collect_tags(base_path, exts, tag_filter):
    results = []
    for filepath in scan_dir(base_path, exts):
        try:
            with open(filepath, encoding='utf-8', errors='ignore') as f:
                for i, line in enumerate(f, 1):
                    match = TAG_PATTERN.search(line)
                    if match:
                        tag, comment = match.groups()
                        tag = tag.strip()
                        if not tag_filter or tag in tag_filter:
                            results.append({
                                'file': os.path.relpath(filepath, base_path),
                                'line': i,
                                'tag': tag,
                                'comment': comment.strip()
                            })
        except Exception as e:
            print(f"Warning: Could not read {filepath}: {e}")
    return results

def format_output(results, fmt='text', group=False):
    if group:
        grouped = defaultdict(list)
        for item in results:
            grouped[item['tag']].append(item)
    else:
        grouped = {'ALL': results}

    if fmt == 'json':
        return json.dumps(results, indent=2)

    elif fmt == 'markdown':
        output = []
        for tag, items in grouped.items():
            output.append(f"## {tag} ({len(items)})\n")
            for item in items:
                output.append(f"- `{item['file']}:{item['line']}`: {item['comment']}")
            output.append("")
        return "\n".join(output)

    else:  # plain text
        output = []
        for tag, items in grouped.items():
            if group:
                output.append(f"\n=== {tag} ===")
            for item in items:
                output.append(f"{item['file']}:{item['line']} [{item['tag']}] {item['comment']}")
        return "\n".join(output)

def main():
    parser = argparse.ArgumentParser(description='Scan code for TODO/FIXME/HACK/etc. tags')
    parser.add_argument('directory', help='Project directory to scan')
    parser.add_argument('--tag', nargs='*', help='Filter by specific tags (e.g. TODO FIXME)')
    parser.add_argument('--ext', nargs='*', help='File extensions to include (e.g. .py .js)')
    parser.add_argument('--format', choices=['text', 'json', 'markdown'], default='text', help='Output format')
    parser.add_argument('--group', action='store_true', help='Group output by tag type')
    parser.add_argument('--out', help='Write output to file instead of stdout')

    args = parser.parse_args()
    results = collect_tags(args.directory, args.ext, args.tag)
    output = format_output(results, fmt=args.format, group=args.group)

    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            f.write(output)
    else:
        print(output)

if __name__ == '__main__':
    main()
