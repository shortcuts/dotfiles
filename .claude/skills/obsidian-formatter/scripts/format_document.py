#!/usr/bin/env python3
"""
Obsidian Document Formatter - Utility Library

This module provides optional utilities agents may use when executing SKILL.md.
Agents are NOT required to use these utilities; they can implement steps independently.
Primary workflow is defined in SKILL.md; agents own the execution.

Available helper functions:
- extract_title_and_content(): Parse YAML frontmatter
- strip_html(): Remove HTML tags
- clean_content(): Remove navigation cruft
- generate_concise_title(): Generate 1-4 word titles
- standardize_tags(): Generate source and topic tags
- build_frontmatter(): Create YAML frontmatter block
- embed_images(): Convert image URLs to markdown
- validate_markdown(): Run markdownlint validation
"""

import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional, Tuple, List, Dict
import collections
import string


def extract_title_and_content(file_path: str) -> Tuple[Optional[Dict], str]:
    """
    Utility function for agents (optional).
    
    Extract YAML frontmatter and separate content cleanly.
    Agents may use this or parse YAML independently.
    
    Returns:
        Tuple of (frontmatter_dict, content_str)
        frontmatter_dict: parsed YAML as dict, or None if no frontmatter
        content_str: remainder of document after frontmatter
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if document starts with YAML frontmatter
    if not content.startswith('---'):
        return None, content
    
    # Find the closing --- delimiter
    lines = content.split('\n')
    closing_index = None
    
    for i in range(1, len(lines)):
        if lines[i].strip() == '---':
            closing_index = i
            break
    
    if closing_index is None:
        # No closing delimiter, treat entire doc as content
        return None, content
    
    # Extract YAML lines and parse manually
    yaml_lines = lines[1:closing_index]
    frontmatter = _parse_yaml_lines(yaml_lines)
    
    # Content starts after the closing ---
    body = '\n'.join(lines[closing_index + 1:]).lstrip('\n')
    
    return frontmatter, body


def _parse_yaml_lines(lines: List[str]) -> Dict:
    """Parse YAML lines manually into a dict."""
    result = {}
    current_key = None
    
    for line in lines:
        if not line.strip() or line.startswith('#'):
            continue
        
        if ':' in line and not line.startswith('  '):
            key, _, value = line.partition(':')
            key = key.strip()
            value = value.strip()
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            elif value.startswith("'") and value.endswith("'"):
                value = value[1:-1]
            
            if key == 'tags' and not value:
                result[key] = []
            else:
                result[key] = value
            current_key = key
        elif line.startswith('  ') and current_key:
            if current_key == 'tags':
                if not isinstance(result.get('tags'), list):
                    result['tags'] = []
                tag = line.strip().lstrip('- ').strip()
                if tag:
                    result['tags'].append(tag)
    
    return result


def strip_html(content: str) -> str:
    """
    Utility function for agents (optional).
    
    Remove ALL HTML tags completely while preserving text content.
    Agents may implement their own HTML stripping if preferred.
    
    Removes:
    - All <...> tags completely
    - Preserves text content from <a> tags
    - HTML comments
    - Self-closing tags
    """
    content = re.sub(r'<!--.*?-->', '', content, flags=re.DOTALL)
    content = re.sub(r'<iframe[^>]*>.*?</iframe>', '', content, flags=re.DOTALL)
    content = re.sub(r'<script[^>]*>.*?</script>', '', content, flags=re.DOTALL)
    content = re.sub(r'<style[^>]*>.*?</style>', '', content, flags=re.DOTALL)
    content = re.sub(r'<img[^>]*/?>', '', content)
    content = re.sub(r'<[^>]+>', '', content)
    
    return content


def generate_concise_title(content: str, directory: Optional[str] = None) -> str:
    """
    Utility function for agents (optional).
    
    Generate concise 1-4 word title using keyword extraction.
    Agents may implement their own title generation strategy.
    
    Strategy:
    1. Extract first heading if present
    2. Find most frequent meaningful words
    3. Combine into 1-4 word title
    4. Remove website names, dates, filler
    """
    heading_match = re.search(r'^#+\s+(.+)$', content, re.MULTILINE)
    first_heading = heading_match.group(1) if heading_match else None
    
    content_snippet = content[:1000]
    
    stop_words = {
        'the', 'a', 'an', 'and', 'or', 'but', 'in', 'of', 'to', 'for',
        'is', 'are', 'was', 'were', 'be', 'been', 'being',
        'have', 'has', 'do', 'does', 'did', 'will', 'would',
        'this', 'that', 'these', 'those', 'it', 'its',
        'you', 'your', 'he', 'she', 'we', 'they', 'them',
        'can', 'could', 'should', 'may', 'might', 'must',
        'how', 'what', 'when', 'where', 'why', 'which', 'who',
        'here', 'there', 'then', 'now', 'as', 'if', 'just',
        'only', 'also', 'same', 'some', 'all', 'any', 'no', 'not',
        'about', 'with', 'by', 'from', 'up', 'out', 'at', 'on',
        'guide', 'tutorial', 'article', 'post', 'blog', 'complete',
        'ultimate', 'best', 'top', 'amazing', 'awesome', 'great',
        'reddit', 'medium', 'hackernews', 'youtube', 'twitter', 'facebook',
        'here', 'click', 'view', 'read', 'see', 'check', 'starting'
    }
    
    words = re.findall(r'\b[a-z]+\b', content_snippet.lower())
    word_freq = collections.Counter(
        w for w in words 
        if w not in stop_words and len(w) > 2
    )
    
    top_words = [word for word, count in word_freq.most_common(4)]
    
    if first_heading:
        heading_words = re.findall(r'\b[a-z]+\b', first_heading.lower())
        heading_keywords = [
            w for w in heading_words 
            if w not in stop_words and len(w) > 2
        ][:3]
        if heading_keywords:
            top_words = heading_keywords
    
    title_words = []
    for word in top_words[:4]:
        if word.isdigit():
            continue
        if re.match(r'^\d{4}$', word):
            continue
        if word not in title_words:
            title_words.append(word.capitalize())
    
    if not title_words:
        title_words = ['Document']
    
    title = ' '.join(title_words[:4])
    
    return title


def clean_content(content: str) -> str:
    """
    Utility function for agents (optional).
    
    Remove Reddit/website navigation cruft while preserving FAQs.
    Agents may implement their own content cleaning if preferred.
    
    Removes:
    - First 20-30 lines (usually navigation)
    - Common Reddit patterns
    - Website chrome
    
    Preserves:
    - FAQ sections
    - Author clarifications
    - Comments that answer questions
    """
    lines = content.split('\n')
    
    content_start = 0
    for i, line in enumerate(lines):
        if line.strip().startswith('#') or (
            len(line.strip()) > 20 and not _is_nav_text(line)
        ):
            content_start = i
            break
    
    result_lines = lines[content_start:]
    
    cleaned_lines = []
    for line in result_lines:
        if _is_reddit_cruft(line):
            continue
        if _is_footer_cruft(line):
            continue
        cleaned_lines.append(line)
    
    content = '\n'.join(cleaned_lines)
    
    if '# Frequently Asked Questions' not in content and '# FAQ' not in content:
        lines = content.split('\n')
        last_heading = -1
        for i in range(len(lines) - 1, -1, -1):
            if lines[i].strip().startswith('#'):
                last_heading = i
                break
        
        if last_heading > 0:
            content = '\n'.join(lines[:last_heading + 50])
    
    return content.strip()


def _is_nav_text(line: str) -> bool:
    """Check if line is navigation text."""
    nav_patterns = [
        r'\[.*?contenu.*?\]', r'\[.*?Skip.*?\]',
        r'\[.*?Créer.*?\]', r'\[.*?Create.*?\]',
        r'Ouvrir.*?navigation', r'Open.*?navigation',
        r'^r/', r'^/r/', r'^u/', r'^Posted by',
        r'Règles de Reddit', r'Reddit Rules'
    ]
    return any(re.search(pat, line, re.IGNORECASE) for pat in nav_patterns)


def _is_reddit_cruft(line: str) -> bool:
    """Check if line is Reddit-specific cruft to remove."""
    stripped = line.strip()
    cruft_patterns = [
        r'\[–\].*?points.*?ago',
        r'\[Accéder au contenu',
        r'\[Skip to',
        r'Posted by u/',
        r'Règles de Reddit',
        r'Reddit Rules',
        r'©.*?Reddit',
        r'Powered by',
        r'\[Create Post\]',
        r'\[.*?Créer',
        r'r/.*?Guide',
        r'^\d+ k vues',
        r'^\d+ • \d+ •',
        r'^Ouvrir',
        r'^Faire de',
        r'^Voir ',
        r'^Permission requise',
        r'il y a \d+ (ans|mois|jours|heures|secondes)',
    ]
    return any(re.search(pat, stripped, re.IGNORECASE) for pat in cruft_patterns)


def _is_footer_cruft(line: str) -> bool:
    """Check if line is footer cruft."""
    cruft_patterns = [
        r'^$',
        r'Privacy Policy',
        r'Terms of Service',
        r'Cookie Policy',
        r'Back to top',
        r'Share on',
        r'Subscribe to',
        r'Advertisement',
        r'Sponsored Content',
        r'© \d+',
    ]
    return any(re.search(pat, line, re.IGNORECASE) for pat in cruft_patterns)


def embed_images(content: str) -> str:
    """
    Utility function for agents (optional).
    
    Convert raw image URLs to markdown format with context keywords.
    Agents may implement their own image embedding strategy.
    
    Converts:
    - https://i.imgur.com/abc123.png → ![keyword](https://i.imgur.com/abc123.png)
    
    Only converts STANDALONE URLs (entire line is just the URL).
    Preserves inline links like [text](url) and text with embedded URLs.
    """
    lines = content.split('\n')
    result = []
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        if re.match(r'^https?://[^\s\[\]<>]+$', stripped):
            context_lines = []
            for j in range(max(0, i - 2), min(len(lines), i + 2)):
                if j != i:
                    context_lines.append(lines[j])
            
            context_text = ' '.join(context_lines).lower()
            keyword = _extract_image_keyword(context_text)
            result.append(f'![{keyword}]({stripped})')
        else:
            result.append(line)
    
    return '\n'.join(result)


def _extract_image_keyword(context: str) -> str:
    """Extract 1-2 word keyword from surrounding context."""
    stop_words = {
        'the', 'a', 'an', 'and', 'or', 'but', 'in', 'of', 'to', 'for',
        'is', 'are', 'was', 'were', 'be', 'this', 'that', 'it',
        'check', 'see', 'view', 'image', 'click', 'here', 'url'
    }
    
    words = re.findall(r'\b[a-z]+\b', context)
    keywords = [
        w for w in words 
        if w not in stop_words and len(w) > 2 and not w.isdigit()
    ]
    
    if keywords:
        return '-'.join(keywords[:2])
    
    return 'image'


def _extract_domain_from_source(source: str) -> str:
    """Extract domain name from source string or URL."""
    if '://' in source:
        domain = source.split('://')[1].split('/')[0].replace('www.', '')
        if '.' in domain:
            domain = domain.split('.')[0]
        return domain.lower()
    return source.lower()


def standardize_tags(frontmatter: Optional[Dict], directory: Optional[str], content: str) -> List[str]:
    """
    Utility function for agents (optional).
    
    Generate exactly 2 meaningful tags.
    Agents may implement their own tagging strategy.
    
    Format:
    1. Source tag: reddit, medium, blog, web, etc.
    2. Topic tag: {directory}-{keyword}
    """
    tags = []
    
    source = 'web'
    
    if frontmatter and 'source' in frontmatter:
        source = _extract_domain_from_source(frontmatter['source'])
    else:
        if 'reddit.com' in content.lower() or '/r/' in content:
            source = 'reddit'
        elif 'medium.com' in content.lower():
            source = 'medium'
        elif 'youtube.com' in content.lower() or 'youtu.be' in content.lower():
            source = 'youtube'
        elif 'github.com' in content.lower():
            source = 'github'
        elif 'hackernews' in content.lower() or 'hn.algolia.com' in content.lower():
            source = 'hackernews'
    
    tags.append(source)
    
    topic_keyword = None
    
    if directory:
        dir_name = Path(directory).name.lower()
        dir_name = dir_name.replace('-', ' ')
        
        content_lower = content[:1000].lower()
        
        stop_words = {
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'of', 'to', 'for',
            'is', 'are', 'guide', 'tutorial', 'article', 'post', 'complete',
            'starting', 'stretch', 'document'
        }
        
        words = re.findall(r'\b[a-z]+\b', content_lower)
        keywords = [w for w in words if w not in stop_words and len(w) > 3]
        
        if keywords:
            word_count = collections.Counter(keywords)
            top_keyword = word_count.most_common(1)[0][0]
            topic_keyword = f"{dir_name.split()[0]}-{top_keyword}"
    
    if not topic_keyword:
        topic_keyword = 'content-article'
    
    tags.append(topic_keyword)
    
    return tags[:2]


def build_frontmatter(title: str, source: str, tags: List[str], 
                      published: Optional[str] = None) -> str:
    """
    Utility function for agents (optional).
    
    Build clean YAML frontmatter.
    Agents may implement their own frontmatter generation if preferred.
    
    Fields:
    - title: Generated concise title
    - source: Website source
    - published: Original publish date (optional)
    - created: Today's date (YYYY-MM-DD)
    - tags: List of exactly 2 tags
    """
    today = datetime.now().strftime('%Y-%m-%d')
    
    yaml_lines = ['---']
    yaml_lines.append(f'title: {title}')
    yaml_lines.append(f'source: {source}')
    
    if published:
        yaml_lines.append(f'published: {published}')
    
    yaml_lines.append(f'created: {today}')
    yaml_lines.append('tags:')
    
    for tag in tags:
        yaml_lines.append(f'  - {tag}')
    
    yaml_lines.append('---')
    
    return '\n'.join(yaml_lines)


def validate_markdown(file_path: str) -> bool:
    """
    Utility function for agents (optional).
    
    Validate markdown with markdownlint.
    Agents may implement their own validation strategy or skip validation.
    
    Runs: markdownlint "{filepath}" --fix --disable MD013 MD041 MD060 MD045
    
    Returns: True if validation passes (exit code 0), False otherwise
    """
    try:
        cmd = [
            'markdownlint',
            file_path,
            '--fix',
            '--disable', 'MD013', 'MD041', 'MD060', 'MD045', 'MD042'
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Markdownlint validation failed:", file=sys.stderr)
            print(result.stdout, file=sys.stderr)
            print(result.stderr, file=sys.stderr)
            return False
        
        return True
    except FileNotFoundError:
        print("Warning: markdownlint not found. Skipping validation.", file=sys.stderr)
        return True

