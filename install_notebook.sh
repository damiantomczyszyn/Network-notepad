#!/bin/bash

PROJECT_DIR="notebook"

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo)."
  exit
fi

echo "Updating system..."
apt update -y && apt upgrade -y

echo "Installing Python, pip, and virtualenv..."
apt install -y python3 python3-pip python3-venv

echo "Creating project directory: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

echo "Creating Python virtual environment..."
python3 -m venv venv

echo "Activating virtual environment..."
source venv/bin/activate

echo "Installing Flask..."
pip install Flask

echo "Creating Flask application..."
cat <<EOF > app.py
from flask import Flask, render_template, request, redirect
import sqlite3
import os

app = Flask(__name__)

DATABASE = os.path.join(os.path.dirname(__file__), 'notes.db')

def init_db():
    with sqlite3.connect(DATABASE) as conn:
        c = conn.cursor()
        c.execute('''CREATE TABLE IF NOT EXISTS notes (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        content TEXT NOT NULL)''')
        conn.commit()

@app.route('/')
def index():
    with sqlite3.connect(DATABASE) as conn:
        c = conn.cursor()
        c.execute("SELECT * FROM notes")
        notes = c.fetchall()
    return render_template('index.html', notes=notes)

@app.route('/add', methods=['POST'])
def add_note():
    content = request.form['content']
    with sqlite3.connect(DATABASE) as conn:
        c = conn.cursor()
        c.execute("INSERT INTO notes (content) VALUES (?)", (content,))
        conn.commit()
    return redirect('/')

@app.route('/delete/<int:note_id>')
def delete_note(note_id):
    with sqlite3.connect(DATABASE) as conn:
        c = conn.cursor()
        c.execute("DELETE FROM notes WHERE id=?", (note_id,))
        conn.commit()
    return redirect('/')

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000)
EOF

echo "Creating templates directory..."
mkdir templates

echo "Creating HTML template for the app..."
cat <<EOF > templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Notebook</title>
    <style>
        body {
            font-family: Arial, sans-serif;
        }
        .note {
            margin-bottom: 20px;
        }
        .delete-btn {
            background-color: red;
            color: white;
            border: none;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <h1>Notebook</h1>
    <form action="/add" method="post">
        <textarea name="content" rows="4" cols="50" placeholder="Enter your note here..."></textarea><br>
        <button type="submit">Add Note</button>
    </form>
    <h2>Your notes:</h2>
    <ul>
        {% for note in notes %}
        <li class="note">
            {{ note[1] }} 
            <a href="/delete/{{ note[0] }}"><button class="delete-btn">Delete</button></a>
        </li>
        {% endfor %}
    </ul>
</body>
</html>
EOF

echo "Initializing database..."
python3 -c "from app import init_db; init_db()"

echo "Starting Flask application..."
flask run --host=0.0.0.0 --port=5000
