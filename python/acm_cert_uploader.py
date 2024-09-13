import boto3
import os
import pathlib

def lambda_handler(event, context):
    s3_client = boto3.client('s3')

    s3_bucket = os.environ['S3_BUCKET']

    # Define the relative file paths
    cert_filename = 'cert.pem'
    key_filename = 'key.pem'
    chain_filename = 'chain.pem'

    # Resolve the path to the directory where this script is located
    script_dir = pathlib.Path(__file__).parent

    # Construct full paths to the certificate, key, and chain files
    cert_path = script_dir / cert_filename
    key_path = script_dir / key_filename
    chain_path = script_dir / chain_filename

    # Read the certificate body, private key, and certificate chain from the files
    with open(cert_path, 'rb') as cert_file:
        certificate_body = cert_file.read()

    with open(key_path, 'rb') as key_file:
        private_key = key_file.read()

    with open(chain_path, 'rb') as chain_file:
        certificate_chain = chain_file.read()

    # Upload to S3
    s3_client.put_object(Bucket=s3_bucket, Key='cert.pem', Body=certificate_body)
    s3_client.put_object(Bucket=s3_bucket, Key='key.pem', Body=private_key)
    s3_client.put_object(Bucket=s3_bucket, Key='chain.pem', Body=certificate_chain)

    return {
        'statusCode': 200,
        'body': 'Certificate, key, and chain uploaded successfully'
    }
