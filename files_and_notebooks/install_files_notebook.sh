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
echo "Moving app.py from the parent directory..."
mv ../app.py .

echo "Creating templates directory..."
mkdir templates

echo "Creating HTML template for the app..."
mv ../index.html ./templates/

echo "Initializing database..."
python3 -c "from app import init_db; init_db()"

echo "Starting Flask application..."
flask run --host=0.0.0.0 --port=5000
