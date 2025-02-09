import requests
import json
import os
from typing import List, Dict
from dotenv import load_dotenv

load_dotenv()


def check_flow_usage(
    instance_url: str, access_token: str, api_version: str, flow_name: str
) -> Dict:
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }

    usage = {
        "process_builder_refs": [],
        "flow_refs": [],
        "apex_refs": [],
        "field_refs": [],
        "metadata_refs": [],
    }

    # Check Process Builder & Flow references
    flow_query = f"SELECT Id, FullName, NamespacePrefix FROM Flow WHERE FullName LIKE '%{flow_name}%' OR DefinitionId LIKE '%{flow_name}%'"
    flow_url = (
        f"{instance_url}/services/data/v{api_version}/tooling/query/?q={flow_query}"
    )

    flow_result = requests.get(flow_url, headers=headers)
    if flow_result.status_code == 200:
        for record in flow_result.json().get("records", []):
            if record.get("FullName") != flow_name:  # Don't include the flow itself
                usage["flow_refs"].append(record.get("FullName"))

    # Check Apex references
    apex_query = f"SELECT Id, Name FROM ApexClass WHERE Body LIKE '%{flow_name}%'"
    apex_url = (
        f"{instance_url}/services/data/v{api_version}/tooling/query/?q={apex_query}"
    )

    apex_result = requests.get(apex_url, headers=headers)
    if apex_result.status_code == 200:
        usage["apex_refs"] = [
            record.get("Name") for record in apex_result.json().get("records", [])
        ]

    # Check Field Update references
    field_query = f"SELECT Id, EntityDefinition.QualifiedApiName, QualifiedApiName FROM CustomField WHERE Metadata LIKE '%{flow_name}%'"
    field_url = (
        f"{instance_url}/services/data/v{api_version}/tooling/query/?q={field_query}"
    )

    field_result = requests.get(field_url, headers=headers)
    if field_result.status_code == 200:
        usage["field_refs"] = [
            f"{record.get('EntityDefinition', {}).get('QualifiedApiName')}.{record.get('QualifiedApiName')}"
            for record in field_result.json().get("records", [])
        ]

    # Check other metadata references
    metadata_types = [
        "ValidationRule",
        "WorkflowRule",
        "Dashboard",
        "Report",
        "CustomObject",
        "Layout",
    ]

    for metadata_type in metadata_types:
        query = f"SELECT Id, FullName FROM {metadata_type} WHERE FullName LIKE '%{flow_name}%'"
        url = f"{instance_url}/services/data/v{api_version}/tooling/query/?q={query}"

        result = requests.get(url, headers=headers)
        if result.status_code == 200:
            refs = [
                record.get("FullName") for record in result.json().get("records", [])
            ]
            if refs:
                usage["metadata_refs"].extend(
                    [f"{metadata_type}: {ref}" for ref in refs]
                )

    return usage


def main():
    instance_url = os.environ.get("SF_INSTANCE_URL")
    access_token = os.environ.get("SF_ACCESS_TOKEN")
    api_version = os.environ.get("SF_API_VERSION", "59.0")
    flow_name = "Sent_Estimate_CA"  # The flow we're looking for

    if not instance_url or not access_token:
        print("Error: Set SF_INSTANCE_URL and SF_ACCESS_TOKEN environment variables")
        return

    try:
        print(f"\nChecking usage of flow: {flow_name}")
        print("========================")

        usage = check_flow_usage(instance_url, access_token, api_version, flow_name)

        if any(refs for refs in usage.values()):
            print("\nFound the following references:")

            if usage["flow_refs"]:
                print("\nReferenced in Flows/Process Builders:")
                for ref in usage["flow_refs"]:
                    print(f"- {ref}")

            if usage["apex_refs"]:
                print("\nReferenced in Apex Classes:")
                for ref in usage["apex_refs"]:
                    print(f"- {ref}")

            if usage["field_refs"]:
                print("\nReferenced in Fields:")
                for ref in usage["field_refs"]:
                    print(f"- {ref}")

            if usage["metadata_refs"]:
                print("\nReferenced in Other Metadata:")
                for ref in usage["metadata_refs"]:
                    print(f"- {ref}")
        else:
            print("\nNo references found! This flow appears to be unused.")
            print(
                "(Note: This doesn't check for dynamic references in code or formulas)"
            )

    except Exception as e:
        print(f"Error: {str(e)}")


if __name__ == "__main__":
    main()
