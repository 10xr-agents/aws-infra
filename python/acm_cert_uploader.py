import boto3
import os

def lambda_handler(event, context):
    s3_client = boto3.client('s3')

    s3_bucket = os.environ['S3_BUCKET']
    certificate_body = os.environ['CERTIFICATE_BODY']
    private_key = os.environ['PRIVATE_KEY']
    certificate_chain = os.environ['CERTIFICATE_CHAIN']

    # Upload to S3
    s3_client.put_object(Bucket=s3_bucket, Key='cert.pem', Body=certificate_body)
    s3_client.put_object(Bucket=s3_bucket, Key='key.pem', Body=private_key)
    s3_client.put_object(Bucket=s3_bucket, Key='chain.pem', Body=certificate_chain)

    return {
        'statusCode': 200,
        'body': 'Certificate, key, and chain uploaded successfully'
    }
