import json
import boto3
import urllib

#Extract the Bucket name and the Key Name

def lambda_handler(event, context): 
    #Get the bucket and file name
    s3Client = boto3.client('s3')
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    key = urllib.parse.unquote_plus(key, encoding='utf-8')
    
    message = 'A new file got uploaded' + key + ' in the bucket ' + bucket
    print(bucket)
    print(key)
    print(message)
    
    #Get our object 
    response = s3Client.get_object(Bucket=bucket, Key=key)
    
    #Process it
    contents = response["Body"].read().decode()
    contents = json.loads(contents)

    print("the content of file is \n", contents)