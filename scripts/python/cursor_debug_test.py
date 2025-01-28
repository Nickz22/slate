#!/usr/bin/env python3
import subprocess
import json
import time
import re
import sys


def run_command(cmd):
    try:
        print(f"Running command: {cmd}")
        result = subprocess.run(
            cmd, shell=True, check=False, capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"Command failed with return code: {result.returncode}")
            print(f"Error output: {result.stderr}")
            print(f"Command output: {result.stdout}")
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {cmd}")
        print(f"Error output: {e.stderr}")
        print(f"Command output: {e.stdout}")
        return None


def run_apex_test(class_name):
    print(f"Running test class: {class_name}")
    cmd = f"sf apex test run --tests {class_name} --result-format json -w 10"
    output = run_command(cmd)
    if output:
        try:
            result = json.loads(output)
            test_run_id = result.get("result", {}).get("summary", {}).get("testRunId")
            if test_run_id:
                print(f"Got test run ID: {test_run_id}")
                return test_run_id
            print("No test run ID found in response")
            print(f"Full response: {result}")
        except (json.JSONDecodeError, KeyError, IndexError) as e:
            print(f"Failed to parse test run output: {e}")
            print(f"Raw output: {output}")
    return None


def get_latest_log():
    print("Fetching latest debug log...")
    cmd = "sf apex log list --json"
    output = run_command(cmd)
    if output:
        try:
            logs = json.loads(output)
            if logs and "result" in logs and logs["result"]:
                latest_log = logs["result"][0]
                log_id = latest_log["Id"]

                print(f"Found log with ID: {log_id}")

                # Get the log content
                cmd = f"sf apex get log --log-id {log_id} --json"
                log_output = run_command(cmd)
                if log_output:
                    try:
                        log_content = json.loads(log_output)
                        print(f"Got log content type: {type(log_content)}")
                        if (
                            isinstance(log_content, dict)
                            and log_content.get("status") == 0
                            and isinstance(log_content.get("result"), list)
                        ):
                            return log_content["result"][0].get("log", "")
                        if isinstance(log_content, list) and len(log_content) > 0:
                            return log_content[0].get("log", "")
                        return log_content.get("result", {}).get("log", "")
                    except (
                        json.JSONDecodeError,
                        KeyError,
                        IndexError,
                        AttributeError,
                    ) as e:
                        print(f"Failed to parse log content: {e}")
        except (json.JSONDecodeError, KeyError, IndexError) as e:
            print(f"Failed to parse log list output: {e}")
            print(f"Raw log list output: {output}")
    return None


def extract_debug_section(
    log_content, start_marker="PARSE_DEBUG_START", end_marker="PARSE_DEBUG_END"
):
    print("extracting debug section")
    if not log_content:
        return None

    pattern = f"{start_marker}(.*?){end_marker}"
    matches = re.findall(pattern, log_content, re.DOTALL)
    return matches


def main():
    if len(sys.argv) != 2:
        print("Usage: python debug_test.py <ApexTestClassName>")
        sys.exit(1)

    class_name = sys.argv[1]

    # Run the test
    test_run_id = run_apex_test(class_name)
    if not test_run_id:
        print("Failed to get test run ID")
        sys.exit(1)

    print(f"Test run ID: {test_run_id}")

    # Give some time for the log to be generated
    time.sleep(5)

    # Get the latest log
    log_content = get_latest_log()
    if not log_content:
        print("No log content found")
        sys.exit(1)

    # Extract debug sections
    debug_sections = extract_debug_section(log_content)
    if debug_sections:
        print("\nDebug Output:")
        for section in debug_sections:
            print(section.strip())
    else:
        print("No debug sections found with the specified markers")


if __name__ == "__main__":
    main()
