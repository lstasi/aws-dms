"""Main application file"""
from flask import Flask

app = Flask(__name__)


@app.route('/')
def home_page():
    return "Hello World!"


@app.route('/<random_string>')
def return_back_string(random_string):
    """Reverse and return the provided URI"""
    return "".join(reversed(random_string))


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
