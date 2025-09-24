import os
import mysql.connector
import logging


from flask import Flask, request, jsonify

logging.basicConfig(level=logging.INFO)
app = Flask(__name__)

def get_db_connection():
