import boto3
import os

def lambda_handler(event, context):
    s3_client = boto3.client('s3')

    s3_bucket = os.environ['S3_BUCKET']

    # Define the file paths relative to the Lambda function's directory
    cert_path = './cert.pem'
    key_path = './key.pem'
    chain_path = './chain.pem'

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

