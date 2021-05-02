"""Main application file"""
import os
import boto3
from flask import Flask
from botocore.exceptions import ClientError

app = Flask(__name__)
endpoint = os.environ.get('END_POINT')


@app.route('/')
def home_page():
    return "Hello World!"


@app.route('/init_db')
def init_db():
    if endpoint != "":
        dynamodb = boto3.resource("dynamodb", endpoint_url=endpoint)
    else:
        dynamodb = boto3.resource("dynamodb")
    try:
        table = dynamodb.create_table(
            TableName='Movies',
            KeySchema=[
                {
                    'AttributeName': 'year',
                    'KeyType': 'HASH'  # Partition key
                },
                {
                    'AttributeName': 'title',
                    'KeyType': 'RANGE'  # Sort key
                }
            ],
            AttributeDefinitions=[
                {
                    'AttributeName': 'year',
                    'AttributeType': 'N'
                },
                {
                    'AttributeName': 'title',
                    'AttributeType': 'S'
                },

            ],
            ProvisionedThroughput={
                'ReadCapacityUnits': 10,
                'WriteCapacityUnits': 10
            }
        )
    except:
        print("Table already Exists")
        pass
    response = table.put_item(
        Item={
            'year': 1999,
            'title': "Matrix",
            'info': {
                'plot': "The Matrix",
                'rating': 5
            }
        }
    )
    return response


@app.route('/put_movie/<title>/<int:year>/<plot>/<int:rating>')
def put_movie(title, year, plot, rating):
    if endpoint != "":
        dynamodb = boto3.resource("dynamodb", endpoint_url=endpoint)
    else:
        dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table('Movies')
    response = table.put_item(
        Item={
            'year': year,
            'title': title,
            'info': {
                'plot': plot,
                'rating': rating
            }
        }
    )
    return response


@app.route('/get_movie/<title>/<int:year>')
def get_movie(title, year):
    if endpoint != "":
        dynamodb = boto3.resource("dynamodb", endpoint_url=endpoint)
    else:
        dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table('Movies')

    try:
        response = table.get_item(Key={'year': year, 'title': title})
    except ClientError as e:
        return e.response['Error']['Message']
    else:
        return response


@app.route('/reverse/<random_string>')
def return_back_string(random_string):
    """Reverse and return the provided URI"""
    return "".join(reversed(random_string))


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
