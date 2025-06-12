#!/usr/bin/env python3
import subprocess
import json
import time
import re
import sys
import os

# Default markers, can be overridden by command-line arguments
DEFAULT_START_MARKER = "APEX_DEBUG_START"
DEFAULT_END_MARKER = "APEX_DEBUG_END"


def run_command_quietly(cmd_args_list):
    """
    Runs a command and captures its output.
    Returns stdout if successful, None otherwise.
    Prints errors and minimal progress to stderr.
    """
    try:
        result = subprocess.run(
            cmd_args_list, check=False, capture_output=True, text=True
        )
        if result.returncode != 0:
            cmd_desc_fail = " ".join(cmd_args_list)
            message = f"Command failed: {cmd_desc_fail}\n"
            sys.stderr.write(message)
            message = f"Return Code: {result.returncode}\n"
            sys.stderr.write(message)
            if result.stdout:
                message = f"Stdout: {result.stdout.strip()}\n"
                sys.stderr.write(message)
            if result.stderr:
                message = f"Stderr: {result.stderr.strip()}\n"
                sys.stderr.write(message)
            return None
        return result.stdout
    except Exception as e:
        cmd_desc_exc = " ".join(cmd_args_list)
        message = f"Exception executing command {cmd_desc_exc}: {str(e)}\n"
        sys.stderr.write(message)
        return None


def execute_anonymous_apex(apex_file_path):
    """
    Executes an anonymous Apex script using 'sf apex run --file'.
    Returns True if the command execution was initiated, False otherwise.
    """
    message = f"Initiating Apex script execution: {apex_file_path}...\n"
    sys.stderr.write(message)
    cmd = ["sf", "apex", "run", "--file", apex_file_path]
    output = run_command_quietly(cmd)
    if output is None:
        message = f"Failed to initiate Apex script execution: {apex_file_path}. Check stderr for details from 'sf' command.\n"
        sys.stderr.write(message)
        return False
    message = f"Apex script {apex_file_path} execution command sent.\n"
    sys.stderr.write(message)
    return True


def get_latest_log_id():
    """
    Fetches the ID of the most recent Apex debug log.
    Returns the log ID string if successful, None otherwise.
    """
    sys.stderr.write("Fetching latest debug log ID...\n")
    cmd = ["sf", "apex", "log", "list", "--json"]
    output = run_command_quietly(cmd)
    if output:
        try:
            logs_data = json.loads(output)
            if (
                logs_data.get("status") == 0
                and logs_data.get("result")
                and len(logs_data["result"]) > 0
            ):
                latest_log_id = logs_data["result"][0]["Id"]
                message = f"Found latest log ID: {latest_log_id}\n"
                sys.stderr.write(message)
                return latest_log_id
            else:
                message = f"Failed to find latest log ID. 'sf apex log list' status: {logs_data.get('status')}, result: {logs_data.get('result')}\n"
                sys.stderr.write(message)
                if logs_data.get("message"):
                    message = f"Message: {logs_data.get('message')}\n"
                    sys.stderr.write(message)
                return None
        except (json.JSONDecodeError, KeyError, IndexError) as e:
            message = f"Error parsing log list JSON: {e}\nRaw output was: {output}\n"
            sys.stderr.write(message)
            return None
    return None


def get_log_content(log_id):
    """
    Fetches the content of a specific Apex debug log by ID using JSON output.
    Returns the log content string if successful, None otherwise.
    """
    message = f"Fetching content for log ID: {log_id}...\n"
    sys.stderr.write(message)
    cmd = ["sf", "apex", "get", "log", "--log-id", log_id, "--json"]
    output = run_command_quietly(cmd)

    if output:
        try:
            log_data = json.loads(output)
            log_text = None
            if log_data.get("status") == 0:
                result_data = log_data.get("result")
                if isinstance(result_data, dict):
                    log_text = result_data.get("log")
                elif (
                    isinstance(result_data, list)
                    and len(result_data) > 0
                    and isinstance(result_data[0], dict)
                ):
                    log_text = result_data[0].get("log")
                elif isinstance(result_data, str):
                    log_text = result_data

                if log_text is not None:
                    message = f"Successfully fetched log content for ID: {log_id}.\n"
                    sys.stderr.write(message)
                    return log_text
                else:
                    message = f"Log content not found in JSON response for log ID: {log_id}. Result was: {result_data}\n"
                    sys.stderr.write(message)
                    return None
            else:
                message = f"Failed to fetch log content (status {log_data.get('status')}) for log ID: {log_id}. Message: {log_data.get('message')}\n"
                sys.stderr.write(message)
                return None
        except (json.JSONDecodeError, KeyError, IndexError, AttributeError) as e:
            message = f"Error parsing log content JSON for log ID {log_id}: {e}\nRaw output was: {output}\n"
            sys.stderr.write(message)
            return None
    return None


def extract_flagged_content(log_content, start_marker, end_marker):
    """
    Extracts content from the log between start_marker and end_marker.
    Returns a list of extracted sections (strings), with leading/trailing whitespace stripped from each.
    """
    if not log_content:
        return []
    escaped_start = re.escape(start_marker)
    escaped_end = re.escape(end_marker)
    pattern = f"{escaped_start}(.*?){escaped_end}"
    matches = re.findall(pattern, log_content, re.DOTALL)
    return [match.strip() for match in matches]


def main():
    if not (2 <= len(sys.argv) <= 5):
        sys.stderr.write(
            "Usage: python execute_apex_and_parse_log.py <apex_script_path> [output_file_path] [start_marker] [end_marker]\n"
        )
        sys.stderr.write(
            "Example: python scripts/python/execute_apex_and_parse_log.py scripts/apex/myScript.apex\n"
        )
        sys.stderr.write(
            "Example with custom markers: python scripts/python/execute_apex_and_parse_log.py scripts/apex/myScript.apex logs/output.txt MY_START MY_END\n"
        )
        sys.exit(1)

    apex_file_path = sys.argv[1]

    output_file_path = (
        sys.argv[2]
        if len(sys.argv) > 2
        else f"{os.path.splitext(apex_file_path)[0]}_parsed_log.txt"
    )
    start_marker = sys.argv[3] if len(sys.argv) > 3 else DEFAULT_START_MARKER
    end_marker = sys.argv[4] if len(sys.argv) > 4 else DEFAULT_END_MARKER

    message = f"Processing Apex script: {apex_file_path}\n"
    sys.stderr.write(message)
    message = f"Outputting parsed log to: {output_file_path}\n"
    sys.stderr.write(message)
    message = f"Using start marker: '{start_marker}' and end marker: '{end_marker}'\n"
    sys.stderr.write(message)

    if not os.path.exists(apex_file_path):
        message = f"Error: Apex script file not found at {apex_file_path}\n"
        sys.stderr.write(message)
        sys.exit(1)

    output_dir = os.path.dirname(output_file_path)
    if output_dir and not os.path.exists(output_dir):
        try:
            os.makedirs(output_dir)
            message = f"Created output directory: {output_dir}\n"
            sys.stderr.write(message)
        except OSError as e:
            message = f"Error creating output directory {output_dir}: {e}\n"
            sys.stderr.write(message)
            sys.exit(1)

    if not execute_anonymous_apex(apex_file_path):
        sys.stderr.write("Aborting due to failure in Apex execution step.\n")
        sys.exit(1)

    log_generation_wait_time = 2
    message = f"Waiting {log_generation_wait_time} seconds for log generation (if needed)...\n"
    sys.stderr.write(message)
    time.sleep(log_generation_wait_time)

    log_id = get_latest_log_id()
    if not log_id:
        sys.stderr.write(
            "Failed to retrieve the latest log ID. No log found or error occurred.\n"
        )
        sys.stderr.write(
            "Ensure debug logs are enabled and being generated for anonymous Apex.\n"
        )
        try:
            with open(output_file_path, "w") as f:
                f.write("Failed to retrieve any debug log. Cannot parse content.\n")
            print(f"Log retrieval failed. Status written to {output_file_path}")
        except IOError as e:
            message = (
                f"Error writing failure status to output file {output_file_path}: {e}\n"
            )
            sys.stderr.write(message)
        sys.exit(1)

    log_content = get_log_content(log_id)
    if not log_content:
        message = f"Failed to retrieve log content for log ID {log_id}.\n"
        sys.stderr.write(message)
        try:
            with open(output_file_path, "w") as f:
                f.write(
                    f"Failed to retrieve content for log ID {log_id}. Cannot parse content.\n"
                )
            print(
                f"Log content retrieval failed for {log_id}. Status written to {output_file_path}"
            )
        except IOError as e:
            message = (
                f"Error writing failure status to output file {output_file_path}: {e}\n"
            )
            sys.stderr.write(message)
        sys.exit(1)

    sys.stderr.write("Extracting content between markers...\n")
    extracted_sections = extract_flagged_content(log_content, start_marker, end_marker)

    final_message_for_stdout = ""
    try:
        with open(output_file_path, "w") as f:
            if extracted_sections:
                f.write(f"Extracted content from log ID: {log_id}\n")
                f.write(
                    f"Start Marker: '{start_marker}', End Marker: '{end_marker}'\n\n"
                )
                for i, section in enumerate(extracted_sections):
                    f.write(f"--- Extracted Section {i+1} ---\n")
                    f.write(section)
                    f.write(f"\n--- End of Section {i+1} ---\n\n")
                final_message_for_stdout = f"Successfully extracted {len(extracted_sections)} section(s) from log {log_id} to {output_file_path}"
            else:
                f.write(
                    f"No content found between markers '{start_marker}' and '{end_marker}' in log ID {log_id}.\n"
                )
                f.write(
                    "Full log content may have been written if extraction failed but content was present, or this file may be empty if log was empty.\n"
                )
                final_message_for_stdout = f"No content found between specified markers in log {log_id}. Output file at {output_file_path} contains details."

        print(final_message_for_stdout)

    except IOError as e:
        message = f"Error writing to output file {output_file_path}: {e}\n"
        sys.stderr.write(message)
        print(
            f"Critical error: Failed to write extracted content to {output_file_path}. Check stderr."
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
