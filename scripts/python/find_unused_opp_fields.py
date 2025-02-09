import requests
import json
import os
from typing import List, Dict
from dotenv import load_dotenv

load_dotenv()


def get_all_opp_fields(
    instance_url: str, access_token: str, api_version: str
) -> List[Dict]:
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }

    # First get all custom field names from describe
    describe_url = (
        f"{instance_url}/services/data/v{api_version}/sobjects/Opportunity/describe"
    )
    describe_result = requests.get(describe_url, headers=headers)
    if describe_result.status_code != 200:
        raise Exception(f"Failed to get Opportunity fields: {describe_result.text}")

    custom_fields = [
        {"name": field["name"], "label": field["label"]}
        for field in describe_result.json()["fields"]
        if field["name"].endswith("__c") and field["custom"]
    ]

    # Then get their IDs from tooling API
    field_ids = {}
    query = (
        "SELECT Id, DeveloperName FROM CustomField WHERE TableEnumOrId = 'Opportunity'"
    )
    tooling_url = (
        f"{instance_url}/services/data/v{api_version}/tooling/query/?q={query}"
    )

    tooling_result = requests.get(tooling_url, headers=headers)
    if tooling_result.status_code == 200:
        for record in tooling_result.json().get("records", []):
            field_ids[f"{record['DeveloperName']}__c"] = record["Id"]

    # Merge the data
    for field in custom_fields:
        field["id"] = field_ids.get(field["name"])

    return custom_fields


def get_field_references(
    instance_url: str, access_token: str, api_version: str
) -> Dict[str, List[str]]:
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }

    metadata_types = [
        "CustomField",
        "ValidationRule",
        "WorkflowRule",
        "Flow",
        "ApexClass",
        "ApexTrigger",
        "Report",
        "Dashboard",
    ]

    field_refs = {}

    for metadata_type in metadata_types:
        url = f"{instance_url}/services/data/v{api_version}/tooling/query/?q=SELECT Id, FullName FROM {metadata_type}"
        result = requests.get(url, headers=headers)

        if result.status_code == 200:
            records = result.json().get("records", [])
            for record in records:
                if "FullName" in record:
                    field_refs[record["FullName"]] = metadata_type

    return field_refs


def get_org_id(instance_url: str, access_token: str, api_version: str) -> str:
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }
    url = f"{instance_url}/services/data/v{api_version}/query/?q=SELECT Id FROM Organization LIMIT 1"

    result = requests.get(url, headers=headers)
    if result.status_code != 200:
        raise Exception("Failed to get Organization ID")

    return result.json()["records"][0]["Id"]


def main():
    instance_url = os.environ.get("SF_INSTANCE_URL")
    access_token = os.environ.get("SF_ACCESS_TOKEN")
    api_version = os.environ.get("SF_API_VERSION", "59.0")

    if not instance_url or not access_token:
        print("Error: Set SF_INSTANCE_URL and SF_ACCESS_TOKEN environment variables")
        return

    try:
        print("Getting all custom Opportunity fields...")
        fields = get_all_opp_fields(instance_url, access_token, api_version)

        org_id = get_org_id(instance_url, access_token, api_version)
        base_url = instance_url.replace(".my.salesforce.com", "")

        print("\nGetting metadata references...")
        field_refs = get_field_references(instance_url, access_token, api_version)

        print("\nAnalyzing field usage...")
        unused_fields = []

        for field in fields:
            field_name = field["name"]
            found = False

            for ref_name, ref_type in field_refs.items():
                if field_name.lower() in ref_name.lower():
                    found = True
                    break

            if not found:
                unused_fields.append(field)

        print("\nUnused Opportunity Fields:")
        print("========================")
        for field in sorted(unused_fields, key=lambda x: x["name"]):
            setup_url = (
                f"{instance_url}/{field.get('id', '')}?setupid=OpportunityFields"
            )
            print(f"{field['name']} ({field['label']}) - {setup_url}")
        print(f"\nTotal unused fields: {len(unused_fields)}")

    except Exception as e:
        print(f"Error: {str(e)}")


if __name__ == "__main__":
    main()
