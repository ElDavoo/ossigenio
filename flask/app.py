import os

from flask import Flask, render_template, json, request
#from werkzeug import generate_password_hash, check_password_hash
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
#def hello_world():  # put application's code here
#    return 'Ciao a tutti!!!'
def showMain():
    return render_template('index.html')

@app.route('/registrazione')
def registrazione():
    return render_template('signup.html')

@app.route('/signUp',methods=['POST'])
def signUp():
    # create user code will be here !!
    _name = request.form['inputName']
    _email = request.form['inputEmail']
    _password = request.form['inputPassword']
    #_hashed_password = generate_password_hash(request.form['inputPassword'])

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('CREATE TABLE IF NOT EXISTS users (id serial PRIMARY KEY,'
                                 'name string NOT NULL,'
                                 'email string NOT NULL,'
                                 'password string NOT NULL,'
                                 )

    cur.execute('INSERT INTO users (name, email, password) VALUES ('+_name+', '+_email+', '+_password+');')

    data = cur.fetchall()
    if len(data) is 0:
        conn.commit()
        return json.dumps({'message':'User created successfully !'})
    else:
        return json.dumps({'error':str(data[0])})
    cur.close()
    conn.close()
    print("insert done")
    # validate the received values
    #if _name and _email and _password:
    #    return json.dumps({'html':'<span>All fields good !!</span>'})
    #else:
    #    return json.dumps({'html':'<span>Enter the required fields</span>'})

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
