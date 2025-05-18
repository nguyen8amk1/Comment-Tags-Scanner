import os
import re
import argparse
import json
import pandas as pd
from collections import defaultdict
import xlsxwriter
from pathlib import Path
import fnmatch

TAGS = ["TODO", "FIXME", "HACK", "NOTE", "BUG", "OPTIMIZE", "REVIEW"]
TAG_PATTERN = re.compile(r'#?\s*({}):?(.*)'.format('|'.join(TAGS)))  # supports Python/C/JS

class GitIgnoreMatcher:
    def __init__(self, base_path):
        self.base_path = Path(base_path).resolve()
        self.ignore_patterns = []
        self._load_gitignore_rules()
    
    def _load_gitignore_rules(self):
        """Load .gitignore rules from the base directory and parent directories"""
        current = self.base_path
        while current:
            gitignore_path = current / '.gitignore'
            if gitignore_path.exists():
                with open(gitignore_path, 'r', encoding='utf-8') as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#'):
                            pattern = line
                            # Handle directory-specific patterns
                            if pattern.startswith('/'):
                                pattern = pattern[1:]
                                pattern_path = current / pattern
                            else:
                                pattern_path = current / '**' / pattern
                            self.ignore_patterns.append(str(pattern_path))
            if current == current.parent:  # Reached root directory
                break
            current = current.parent
    
    def is_ignored(self, filepath):
        """Check if a file should be ignored based on .gitignore rules"""
        filepath = Path(filepath).resolve()
        rel_path = str(filepath.relative_to(self.base_path))
        
        # Always ignore .git directory
        if '.git' in rel_path.split(os.sep):
            return True
            
        for pattern in self.ignore_patterns:
            # Convert pattern to match relative paths
            pattern_rel = pattern.replace(str(self.base_path) + os.sep, '')
            if fnmatch.fnmatch(rel_path, pattern_rel) or fnmatch.fnmatch(rel_path, os.path.join(pattern_rel, '*')):
                return True
            if fnmatch.fnmatch(rel_path, os.path.join('**', pattern_rel)) or fnmatch.fnmatch(rel_path, os.path.join('**', pattern_rel, '*')):
                return True
        
        return False

def scan_dir(base_path, exts, gitignore_matcher=None):
    for root, _, files in os.walk(base_path):
        # Skip directories that are ignored
        if gitignore_matcher and gitignore_matcher.is_ignored(root):
            continue
            
        for file in files:
            filepath = os.path.join(root, file)
            if gitignore_matcher and gitignore_matcher.is_ignored(filepath):
                continue
            if not exts or any(file.endswith(ext) for ext in exts):
                yield filepath

def collect_tags(base_path, exts, tag_filter):
    results = []
    gitignore_matcher = None
    if os.path.exists(os.path.join(base_path, '.git')):
        gitignore_matcher = GitIgnoreMatcher(base_path)
    
    for filepath in scan_dir(base_path, exts, gitignore_matcher):
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

def output_excel(results, path):
    grouped = defaultdict(list)
    for item in results:
        grouped[item['tag']].append(item)
    with pd.ExcelWriter(path, engine='xlsxwriter') as writer:
        for tag, items in grouped.items():
            df = pd.DataFrame(items)
            df = df[['file', 'line', 'comment']]
            df.columns = ['File', 'Line', 'Comment']
            df.to_excel(writer, sheet_name=tag[:31], index=False)
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
    elif fmt == 'excel':
        output_excel(results, 'output.xlsx')
        return ""  # no stdout print
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
    parser.add_argument('--format', choices=['text', 'json', 'markdown', 'excel'], default='text', help='Output format')
    parser.add_argument('--group', action='store_true', help='Group output by tag type')
    parser.add_argument('--out', help='Write output to file instead of stdout')
    parser.add_argument('--no-gitignore', action='store_true', help='Disable .gitignore filtering')

    args = parser.parse_args()
    
    # Check if we should use gitignore filtering
    use_gitignore = not args.no_gitignore and os.path.exists(os.path.join(args.directory, '.git'))
    
    results = collect_tags(args.directory, args.ext, args.tag)
    output = format_output(results, fmt=args.format, group=args.group)

    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            f.write(output)
    else:
        print(output)

if __name__ == '__main__':
    main()
