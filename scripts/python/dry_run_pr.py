import os
import sys
import argparse
import subprocess
import requests
from urllib.parse import urlparse
from dotenv import load_dotenv

load_dotenv()

"""
Usage Instructions:
-----------------
This script performs a dry-run deployment of changes from one or more GitHub Pull Requests to a Salesforce org.

Basic Usage:
    python dry_run_pr.py --org <target_org_alias> --prs <github_pr_url>

Multiple PRs:
    python dry_run_pr.py --org <target_org_alias> --prs <github_pr_url_1> <github_pr_url_2> <github_pr_url_3>

Interactive Mode:
    python dry_run_pr.py --org <target_org_alias>
    (Script will prompt for PR URL)

Examples:
    python dry_run_pr.py --org dev --prs https://github.com/username/repo/pull/123
    python dry_run_pr.py --org staging --prs https://github.com/username/repo/pull/123 https://github.com/username/repo/pull/124

Requirements:
    - GITHUB_TOKEN environment variable must be set with a valid GitHub token
    - Salesforce CLI (sf) must be installed and authenticated with the target org
"""


def get_test_classes(tests_dir, exclude_dirs=None):
    if exclude_dirs is None:
        exclude_dirs = []
    test_classes = []
    for root, dirs, files in os.walk(tests_dir):
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        for file in files:
            if file.endswith("Test.cls"):
                class_name = os.path.splitext(file)[0]
                test_classes.append(class_name)
    return test_classes


def get_pr_details(pr_url):
    parsed = urlparse(pr_url)
    parts = parsed.path.strip("/").split("/")
    return parts[0], parts[1], parts[3]


def get_changed_files(owner, repo, pr_number, token):
    files = []
    page = 1
    per_page = 100
    while True:
        url = f"https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}/files?page={page}&per_page={per_page}"
        headers = {"Authorization": f"token {token}"}
        r = requests.get(url, headers=headers)
        if r.status_code == 200:
            batch = r.json()
            if not batch:
                break
            files.extend([f["filename"] for f in batch])
            page += 1
        else:
            return None
    return files


def filter_deployable_files(files):
    deployable_files = set()
    excluded_patterns = ["/gpt-generated/", "/typings/", "/lwc/__tests__/"]

    for file in files:
        if any(pattern in file for pattern in excluded_patterns):
            continue

        if file.startswith("force-app/"):
            deployable_files.add(file)

    return list(deployable_files)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--prs", type=str, nargs="+", help="List of GitHub PR URLs")
    parser.add_argument("--org", type=str, required=True, help="Target org alias")
    args = parser.parse_args()

    if not args.prs:
        args.prs = [input("Enter the GitHub Pull Request URL: ")]

    token = os.getenv("GITHUB_TOKEN")
    if not token:
        sys.exit("No GITHUB_TOKEN found.")

    all_changed_files = []

    for pr_url in args.prs:
        owner, repo, pr_number = get_pr_details(pr_url)
        changed_files = get_changed_files(owner, repo, pr_number, token)

        if not changed_files:
            print(f"Failed to retrieve changed files for PR: {pr_url}. Skipping.")
            continue

        all_changed_files.extend(changed_files)

    if not all_changed_files:
        sys.exit(
            "Failed to retrieve changed files from any PR. Check the PR URLs and token."
        )

    deployable_files = filter_deployable_files(all_changed_files)

    if not deployable_files:
        sys.exit("No deployable files found in the changes.")

    tests_dir = "force-app/main/default/classes/tests"
    test_classes = get_test_classes(tests_dir, ["mocks"])

    cmd = [
        "sf",
        "project",
        "deploy",
        "start",
        "-l",
        "RunSpecifiedTests",
        "--dry-run",
        "--target-org",
        args.org,
    ]

    for file_path in deployable_files:
        cmd.extend(["-d", file_path])

    for t in test_classes:
        cmd.extend(["--tests", t])

    print(" ".join(cmd))
    subprocess.check_call(cmd)


if __name__ == "__main__":
    main()
