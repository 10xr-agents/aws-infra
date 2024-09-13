import boto3
import os

def lambda_handler(event, context):
    acm_client = boto3.client('acm')
    s3_client = boto3.client('s3')

    certificate_arn = os.environ['CERTIFICATE_ARN']
    s3_bucket = os.environ['S3_BUCKET']
    root_cert_path = './root_ca_10xr.pem'  # Relative path to your root CA cert file

    # Export the certificate
    response = acm_client.export_certificate(
        CertificateArn=certificate_arn,
        Passphrase=b'live_kit_tls_pass_phrase'  # Passphrase should be bytes
    )

    # Save the certificate, private key, and chain to S3
    s3_client.put_object(Bucket=s3_bucket, Key='cert.pem', Body=response['Certificate'])
    s3_client.put_object(Bucket=s3_bucket, Key='key.pem', Body=response['PrivateKey'])
    s3_client.put_object(Bucket=s3_bucket, Key='chain.pem', Body=response['CertificateChain'])

    # Upload the root certificate
    try:
        with open(root_cert_path, 'rb') as root_cert_file:
            s3_client.put_object(Bucket=s3_bucket, Key='root_ca_cert.pem', Body=root_cert_file.read())
    except FileNotFoundError:
        return {
            'statusCode': 500,
            'body': 'Root CA certificate file not found'
        }

    return {
        'statusCode': 200,
        'body': 'Certificate, key, chain, and root CA exported successfully'
    }
