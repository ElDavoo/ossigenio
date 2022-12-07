import os

from flask import Flask, render_template
import psycopg2
app = Flask(__name__)


# Check if DB_PASSWORD is set
if 'DB_PASSWORD' not in os.environ:
    print("DB_PASSWORD not set")
    exit(1)

def get_db_connection():
    conn = psycopg2.connect(
        host="localhost",
        database="iot",
        user="iot",
        password=os.environ['DB_PASSWORD'])
    return conn

@app.route('/')
def hello_world():  # put application's code here
    return 'Ciao a tutti!!!'

@app.route('/registrazione')
def showSignUp():
    return render_template('signup.html')


@app.route('/measurements/')
def index():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT * FROM measurements;')
    books = cur.fetchall()
    cur.close()
    conn.close()
    return books

if __name__ == '__main__':
    port = 5000
    interface = '0.0.0.0'
    app.jinja_env.auto_reload = True
    app.config['TEMPLATES_AUTO_RELOAD'] = True
    app.run(host='0.0.0.0', port=port, debug=True)
