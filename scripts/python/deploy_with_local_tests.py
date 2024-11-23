import os
import argparse
import subprocess


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


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", required=True)
    args = parser.parse_args()

    tests_dir = "force-app/main/default/classes/tests"
    exclude_dirs = ["mocks"]
    test_classes = get_test_classes(tests_dir, exclude_dirs)

    deploy_command = [
        "sf",
        "project",
        "deploy",
        "start",
        "-d",
        "force-app",
        "-l",
        "RunSpecifiedTests",
        "--target-org",
        args.target,
    ]
    for test_class in test_classes:
        deploy_command.extend(["--tests", test_class])

    subprocess.check_call(deploy_command)
