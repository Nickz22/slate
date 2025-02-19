import os
import sys
import argparse
import subprocess
import requests
from urllib.parse import urlparse
from dotenv import load_dotenv

load_dotenv()


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


def generate_deployment_details(files):
    mapping = {
        "/classes/": "ApexClass",
        "/permissionsets/": "PermissionSet",
        "/lwc/": "LightningComponentBundle",
        "/aura/": "AuraDefinitionBundle",
        "/objects/": "CustomObject",
        "/customMetadata/": "CustomMetadata",
    }
    details = {}
    for f in files:
        if "/gpt-generated/" in f or "/typings/" in f or "/lwc/__tests__/" in f:
            continue
        if "/objects/" in f and "/fields/" in f:
            parts = f.split("/")
            try:
                idx = parts.index("objects")
                obj = parts[idx + 1]
                details[f"CustomObject:{obj}"] = True
            except Exception:
                continue
        elif "CustomLabels.labels-meta.xml" in f:
            details["CustomLabel"] = True
        else:
            for seg, typ in mapping.items():
                if seg in f:
                    name = f.split("/")[-1].split(".")[0]
                    left = f.rsplit("/", 1)[0]
                    if typ == "CustomObject" and not f.endswith(".object-meta.xml"):
                        continue
                    if typ == "LightningComponentBundle" and name not in left.split(
                        "/"
                    ):
                        continue
                    details[f"{typ}:{name}"] = True
                    break
    return list(details.keys())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pr", type=str)
    parser.add_argument("--org", type=str, required=True)
    args = parser.parse_args()
    pr_url = args.pr if args.pr else input("Enter the GitHub Pull Request URL: ")
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        sys.exit("No GITHUB_TOKEN found.")
    owner, repo, pr_number = get_pr_details(pr_url)
    changed_files = get_changed_files(owner, repo, pr_number, token)
    if not changed_files:
        sys.exit("Failed to retrieve changed files. Check the PR URL and token.")
    deploy_metadata = generate_deployment_details(changed_files)
    tests_dir = "force-app/main/default/classes/tests"
    test_classes = get_test_classes(tests_dir, ["mocks"])
    cmd = [
        "sf",
        "project",
        "deploy",
        "start",
        "-l",
        "RunSpecifiedTests",
        "--target-org",
        args.org,
    ]
    for m in deploy_metadata:
        cmd.extend(["-m", m])
    for t in test_classes:
        cmd.extend(["--tests", t])
    print(" ".join(cmd))
    subprocess.check_call(cmd)


if __name__ == "__main__":
    main()
