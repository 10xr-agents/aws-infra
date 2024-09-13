import os
import boto3
import logging
from cryptography.hazmat.primitives.serialization import load_pem_private_key
from cryptography.hazmat.primitives.serialization import Encoding, PrivateFormat, NoEncryption
from cryptography.hazmat.backends import default_backend
from botocore.exceptions import BotoCoreError, ClientError

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def validate_env_vars(*vars):
    """Validate that required environment variables are set."""
    missing_vars = [var for var in vars if os.getenv(var) is None]
    if missing_vars:
        raise EnvironmentError(f"Missing required environment variables: {', '.join(missing_vars)}")

def decrypt_private_key(encrypted_private_key, passphrase):
    """Decrypt the private key using the given passphrase."""
    try:
        private_key = load_pem_private_key(
            encrypted_private_key.encode('utf-8'),
            password=passphrase.encode('utf-8'),
            backend=default_backend()
        )
        decrypted_private_key = private_key.private_bytes(
            encoding=Encoding.PEM,
            format=PrivateFormat.PKCS8,
            encryption_algorithm=NoEncryption()
        )
        return decrypted_private_key
    except ValueError as e:
        logger.error("Failed to decrypt private key: %s", str(e))
        raise
    except Exception as e:
        logger.exception("An unexpected error occurred while decrypting the private key.")
        raise

def upload_to_s3(s3_client, bucket, key, data):
    """Upload data to S3 and handle errors."""
    try:
        s3_client.put_object(Bucket=bucket, Key=key, Body=data)
        logger.info(f"Successfully uploaded {key} to S3 bucket {bucket}.")
    except (BotoCoreError, ClientError) as e:
        logger.error("Failed to upload %s to S3: %s", key, str(e))
        raise

def lambda_handler(event, context):
    try:
        # Validate that required environment variables are set
        validate_env_vars('CERTIFICATE_ARN', 'S3_BUCKET')

        # Initialize clients
        acm_client = boto3.client('acm')
        s3_client = boto3.client('s3')

        # Get environment variables
        certificate_arn = os.getenv('CERTIFICATE_ARN')
        s3_bucket = os.getenv('S3_BUCKET')
        passphrase = os.getenv('PASSPHRASE', 'temp_passphrase')  # Default to 'temp_passphrase' if not provided

        # Export the certificate and handle potential errors
        logger.info("Exporting certificate from ACM...")
        response = acm_client.export_certificate(
            CertificateArn=certificate_arn,
            Passphrase=passphrase
        )
        logger.info("Certificate exported successfully.")

        # Decrypt the private key
        encrypted_private_key = response['PrivateKey']
        decrypted_private_key = decrypt_private_key(encrypted_private_key, passphrase)

        # Upload certificate, private key, and chain to S3
        upload_to_s3(s3_client, s3_bucket, 'cert.pem', response['Certificate'])
        upload_to_s3(s3_client, s3_bucket, 'key.pem', decrypted_private_key)
        upload_to_s3(s3_client, s3_bucket, 'chain.pem', response['CertificateChain'])

        return {
            'statusCode': 200,
            'body': 'Certificate exported and private key decrypted successfully'
        }

    except (BotoCoreError, ClientError) as e:
        logger.error("AWS API error: %s", str(e))
        return {
            'statusCode': 500,
            'body': f"Failed to export certificate or upload to S3: {str(e)}"
        }
    except EnvironmentError as e:
        logger.error("Environment error: %s", str(e))
        return {
            'statusCode': 400,
            'body': str(e)
        }
    except Exception as e:
        logger.exception("Unexpected error: %s", str(e))
        return {
            'statusCode': 500,
            'body': f"An unexpected error occurred: {str(e)}"
        }
