#!/usr/bin/env python3
"""
Upload files to the file-sharing service.

Usage:
    python upload.py /path/to/file.txt
    python upload.py /path/to/file.txt --file-name custom-name.txt
    python upload.py /path/to/file.txt -n custom-name.txt
"""

import argparse
import json
import os
import sys
import boto3
import requests


STACK_NAME = "file-sharing-dev"


def get_api_endpoint():
    """Discover API endpoint from CloudFormation stack outputs."""
    print("🔍 Discovering API endpoint from CloudFormation...")

    cfn = boto3.client('cloudformation')
    try:
        response = cfn.describe_stacks(StackName=STACK_NAME)
        outputs = response['Stacks'][0]['Outputs']

        # Find the API endpoint output (usually contains 'Api' in the key)
        for output in outputs:
            if 'Api' in output['OutputKey']:
                api_url = output['OutputValue']
                # Remove trailing /hello/ or similar paths
                base_url = api_url.rsplit('/', 2)[0] if api_url.endswith('/') else api_url.rsplit('/', 1)[0]
                print(f"✅ Found API: {base_url}")
                return base_url

        print(f"❌ No API endpoint found in stack outputs")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Failed to get API endpoint: {e}")
        sys.exit(1)


def upload_file(file_path, file_name=None):
    """Upload a file using the presigned URL workflow."""

    # Validate file exists
    if not os.path.isfile(file_path):
        print(f"❌ Error: File not found: {file_path}")
        sys.exit(1)

    # Use provided filename or extract from path
    if file_name is None:
        file_name = os.path.basename(file_path)

    print(f"\n📤 Uploading: {file_path}")
    print(f"📝 File name: {file_name}")

    # Get API endpoint dynamically
    api_base_url = get_api_endpoint()

    # Step 1: Get presigned URL from API
    print("\n1️⃣  Requesting presigned URL from API...")
    try:
        response = requests.post(
            f"{api_base_url}/files/upload-url",
            json={"fileName": file_name},
            headers={"Content-Type": "application/json"}
        )
        response.raise_for_status()
        presigned_data = response.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Failed to get presigned URL: {e}")
        if hasattr(e.response, 'text'):
            print(f"Response: {e.response.text}")
        sys.exit(1)

    print(f"✅ Got presigned URL")
    print(f"   S3 Key: {presigned_data.get('s3Key')}")

    # Step 2: Upload file to S3 using presigned POST
    print("\n2️⃣  Uploading to S3...")
    try:
        with open(file_path, 'rb') as f:
            files = {'file': (file_name, f)}
            response = requests.post(
                presigned_data['uploadUrl'],
                data=presigned_data['fields'],
                files=files
            )
            response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print(f"❌ Failed to upload to S3: {e}")
        if hasattr(e.response, 'text'):
            print(f"Response: {e.response.text}")
        sys.exit(1)

    print("✅ Upload successful!")
    print(f"\n📊 Summary:")
    print(f"   Bucket: {presigned_data['uploadUrl'].split('/')[2].split('.')[0]}")
    print(f"   S3 Key: {presigned_data['s3Key']}")
    print(f"   Size: {os.path.getsize(file_path):,} bytes")

    return presigned_data


def main():
    parser = argparse.ArgumentParser(
        description="Upload files to the file-sharing service",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python upload.py document.pdf
  python upload.py photo.jpg --file-name "my-photo.jpg"
  python upload.py data.csv -n backup-2025.csv
        """
    )

    parser.add_argument(
        'file_path',
        help='Path to the file to upload'
    )

    parser.add_argument(
        '--file-name', '-n',
        dest='file_name',
        help='Custom filename to use in S3 (defaults to original filename)'
    )

    args = parser.parse_args()

    upload_file(args.file_path, args.file_name)


if __name__ == '__main__':
    main()
