import os
import sys
import argparse
import subprocess

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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pr", required=True)
    parser.add_argument("--org", required=True)
    args = parser.parse_args()

    token = os.environ.get("GITHUB_PERSONAL_TOKEN")
    if not token:
        sys.exit("No GITHUB_PERSONAL_TOKEN found.")

    tests_dir = "force-app/main/default/classes/tests"
    exclude_dirs = ["mocks"]
    test_classes = get_test_classes(tests_dir, exclude_dirs)

    command = [
        "sf",
        "project",
        "deploy",
        "start",
        "-d",
        "force-app",
        "-l",
        "RunSpecifiedTests",
        "--target-org",
        args.org,
    ]
    for cls in test_classes:
        command.extend(["--tests", cls])
    print(' '.join(command))
    subprocess.check_call(command)


if __name__ == "__main__":
    main()
